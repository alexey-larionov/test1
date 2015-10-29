#!/bin/bash

# s01_tabulate_vep_vcf.sh
# Tabulating vep vcf
# Alexey Larionov, 26Oct2015

# Read parameters
job_file="${1}"
scripts_folder="${2}"

# Update pipeline log
echo "Started s01_tabulate_vep_vcf: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Set parameters
source "${scripts_folder}/a02_read_config.sh"
echo "Read settings"
echo ""

# Go to working folder
init_dir="$(pwd)"
cd "${tabulated_vep_vcf_folder}"

# --- Copy source gvcfs to cluster --- #

# Progress report
echo "Started copying source data"

mkdir -p "${tabulated_vep_vcf_folder}/source_vcf"
rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${source_vcf_folder}/${source_vcf}" "${tabulated_vep_vcf_folder}/source_vcf/"

# Progress report
echo "Completed copying source data: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Run perl script --- #

# File names
input_vcf="${tabulated_vep_vcf_folder}/source_vcf/${source_vcf}"
txt_md5="${dataset}.md5"
perl_log="${dataset}_vep2txt_perl.log"

# Progress report
echo "Started perl script"
 
# Run script with vcf output
"${scripts_folder}/s02_vcf2tab.pl" \
   "${dataset}" \
   "${input_vcf}" \
   "${tabulated_vep_vcf_folder}" &> "${perl_log}"

# Progress report
echo "Completed perl script: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Remove source file from cluster
rm -fr "${tabulated_vep_vcf_folder}/source_vcf"

# Make md5 file for tabulated files
files_list=$(ls)
md5sum ${files_list} > "${txt_md5}"

# --- Copy results to NAS --- #

# Progress report
echo "Started copying results to NAS"

# Copy files to NAS
rsync -thrqe "ssh -x" "${tabulated_vep_vcf_folder}" "${data_server}:${project_location}/${project}/" 

# Change ownership on nas (to allow user manipulating files later w/o administrative privileges)
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}/${project}/tabulated_vep_vcf"
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}/${project}" # just in case...
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}" # just in case...

# Progress report
timestamp="$(date +%d%b%Y_%H:%M:%S)"
ssh -x "${data_server}" "echo \"Completed copying results to NAS: ${timestamp}\" >> ${project_location}/${project}/tabulated_vep_vcf/${dataset}_vep2txt.log"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/tabulated_vep_vcf/${dataset}_vep2txt.log"

# Remove results from cluster
rm -f ${files_list}
rm -f "${txt_md5}"
rm -f "${dataset}_vep2txt.log"
rm -f "${dataset}_vep2txt.res"

ssh -x "${data_server}" "echo \"Removed results from cluster\" >> ${project_location}/${project}/tabulated_vep_vcf/${dataset}_vep2txt.log"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/tabulated_vep_vcf/${dataset}_vep2txt.log"

# Return to the initial folder
cd "${init_dir}"

# Remove project folder from cluster
if [ "${remove_project_folder}" == "yes" ] || [ "${remove_project_folder}" == "Yes" ] 
then 
  rm -fr "${project_folder}"
  ssh -x "${data_server}" "echo \"Removed project foldr from cluster\" >> ${project_location}/${project}/tabulated_vep_vcf/${dataset}_vep2txt.log"
else
  ssh -x "${data_server}" "echo \"Project folder is not removed from cluster\" >> ${project_location}/${project}/tabulated_vep_vcf/${dataset}_vep2txt.log"
fi 
