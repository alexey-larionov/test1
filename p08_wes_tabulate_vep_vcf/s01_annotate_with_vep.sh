#!/bin/bash

# s01_annotate_with_vep.sh
# Annotating filtered vcfs with vep
# Alexey Larionov, 15Oct2015

# Read parameters
job_file="${1}"
scripts_folder="${2}"

# Update pipeline log
echo "Started s01_annotate_with_vep: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Set parameters
source "${scripts_folder}/a02_read_config.sh"
echo "Read settings"
echo ""

# Go to working folder
init_dir="$(pwd)"
cd "${annotated_vcf_folder}"

# --- Copy source gvcfs to cluster --- #

# Progress report
echo "Started copying source data"
echo ""

rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/qual_filtered_vcf/${source_vcf}" "${annotated_vcf_folder}/${source_vcf%.vcf}_source_files/"
rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/qual_filtered_vcf/${source_vcf}.idx" "${annotated_vcf_folder}/${source_vcf%.vcf}_source_files/"

# Progress report
echo "Completed copying source data: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Run vep script --- #

# Progress report
echo "Started vep script"
echo ""

# File names
vcf_in="${source_vcf%.vcf}_source_files/${source_vcf}"
vcf_out="${source_vcf%.vcf}_vep.vcf"

stats_file="${source_vcf%.vcf}_vep.html"
vep_script_log="${source_vcf%.vcf}_vep_script.log"
annotated_vcf_md5="${source_vcf%.vcf}_vep.md5"

# Run script

#v1
#perl "${vep_script}" \
#  -i "${vcf_in}" -o "${vcf_out}" --stats_file "${stats}" --vcf \
#  --cache --offline --dir_cache "${vep_cache}" \
#  --symbol --pick --sift b --polyphen b \
#  --check_existing --check_alleles \
#  --gmaf --maf_1kg --maf_esp \
#  --force_overwrite --fork 12 --no_progress \
#  --fields "${vep_fields}" &>> "${vep_script_log}"

#v2
#perl "${vep_script}" \
#  -i "${vcf_in}" -o "${vcf_out}" --stats_file "${stats}" \
#  --cache --offline --dir_cache "${vep_cache}" \
#  --symbol --pick --sift b --polyphen b \
#  --check_existing --check_alleles \
#  --gmaf --maf_1kg --maf_esp \
#  --force_overwrite --fork 12 --no_progress \
#  --fields "${vep_fields}" &>> "${vep_script_log}"

#v3
perl "${vep_script}" \
  -i "${vcf_in}" -o "${vcf_out}" --stats_file "${stats}" \
  --cache --offline --dir_cache "${vep_cache}" \
  --symbol --pick --sift b --polyphen b \
  --check_existing --check_alleles \
  --gmaf --maf_1kg --maf_esp \
  --force_overwrite --fork 12 --no_progress &>> "${vep_script_log}"

# Make vcf index
# to be done later

# Make md5 file
# later: add index to md5
md5sum "${vcf_out}" > "${annotated_vcf_md5}"

# Remove source files from cluster
rm -fr "${source_vcf%.vcf}_source_files"

# Progress report
echo "Completed vep script: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Copy output back to NAS --- #

# Progress report
echo "Started copying results to NAS"
echo ""

# Copy files to NAS
rsync -thrqe "ssh -x" "${annotated_vcf_folder}" "${data_server}:${project_location}/${project}/" 

# Change ownership on nas (to allow user manipulating files later w/o administrative privileges)
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}/${project}/vep_annotated_vcf"
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}/${project}" # just in case...
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}" # just in case...

# Progress report
timestamp="$(date +%d%b%Y_%H:%M:%S)"
ssh -x "${data_server}" "echo \"Completed copying results to NAS: ${timestamp}\" >> ${project_location}/${project}/vep_annotated_vcf/${source_vcf%.vcf}_vep.log"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/vep_annotated_vcf/${source_vcf%.vcf}_vep.log"

# Remove results from cluster
rm -f "${vcf_out}" 
rm -f "${stats_file}"
rm -f "${vep_script_log}"
rm -f "${annotated_vcf_md5}"

rm -f "${source_vcf%.vcf}_vep.res"

ssh -x "${data_server}" "echo \"Removed results from cluster\" >> ${project_location}/${project}/vep_annotated_vcf/${source_vcf%.vcf}_vep.log"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/vep_annotated_vcf/${source_vcf%.vcf}_vep.log"

# Return to the initial folder
cd "${init_dir}"

# Remove project folder from cluster
if [ "${remove_project_folder}" == "yes" ] || [ "${remove_project_folder}" == "Yes" ] 
then 
  rm -fr "${project_folder}"
  ssh -x "${data_server}" "echo \"Removed project foldr from cluster\" >> ${project_location}/${project}/vep_annotated_vcf/${source_vcf%.vcf}_vep.log"
else
  ssh -x "${data_server}" "echo \"Project folder is not removed from cluster\" >> ${project_location}/${project}/vep_annotated_vcf/${source_vcf%.vcf}_vep.log"
fi 
