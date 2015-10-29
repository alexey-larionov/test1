#!/bin/bash

# s01_filter_by_qual.sh
# Filtering raw vcf by qual
# Alexey Larionov, 14Oct2015

# Read parameters
job_file="${1}"
scripts_folder="${2}"

# Update pipeline log
echo "Started s01_filter_by_qual: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Set parameters
source "${scripts_folder}/a02_read_config.sh"
echo "Read settings"
echo ""

# Check the source file name
if [ "${source_vcf: -8}" == "_raw.vcf" ]
then
  dataset="${source_vcf%_raw.vcf}"
else
  dataset="${source_vcf%.vcf}"
fi

# Check the qual_threshold
if [ "${qual_threshold: -2}" == ".0" ]
then
  suffix="qual${qual_threshold%.0}"
else
  suffix="qual${qual_threshold}"
fi

# Go to working folder
init_dir="$(pwd)"
cd "${filtered_vcf_folder}"

# --- Copy source gvcfs to cluster --- #

# Progress report
echo "Started copying source data"
echo ""

rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${source_vcf_folder}/${source_vcf}" "${filtered_vcf_folder}/${dataset}_${suffix}_source_files/"
rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${source_vcf_folder}/${source_vcf}.idx" "${filtered_vcf_folder}/${dataset}_${suffix}_source_files/"

# Progress report
echo "Completed copying source data: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Filter by qual --- #

# Progress report
echo "Started filtering"
echo ""

# File names
input_vcf="${filtered_vcf_folder}/${dataset}_${suffix}_source_files/${source_vcf}"
filtered_vcf="${dataset}_${suffix}.vcf"
SelectVariants_log="${dataset}_${suffix}_SelectVariants.log"
filtered_vcf_md5="${dataset}_${suffix}.md5"

# Select variants
"${java7}" -Xmx60g -jar "${gatk}" \
  -T SelectVariants \
  -R "${ref_genome}" \
  -L "${nextera_targets_intervals}" -ip 100 \
  -V "${input_vcf}" \
  -o "${filtered_vcf}" \
  -select "QUAL > ${qual_threshold}" \
  -nt 14 &>  "${SelectVariants_log}"

# Make md5 file
md5sum "${filtered_vcf}" "${filtered_vcf}.idx" > "${filtered_vcf_md5}"

# Remove source files from cluster
rm -fr "${dataset}_${suffix}_source_files"

# Progress report
echo "Completed filtering: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Raw vcf stats --- #

# Progress report
echo "Calculating filtered vcf stats and making plots"
echo ""

# File names
vcf_stats="${dataset}_${suffix}.vchk"

# Calculate vcf stats
"${bcftools}" stats -d 0,25000,500 -F "${ref_genome}" "${filtered_vcf}" > "${vcf_stats}" 

# Plot the stats
"${plot_vcfstats}" "${vcf_stats}" -p "${vcf_plots_folder}/"
echo ""

# Completion message to log
echo "Completed: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Copy output back to NAS --- #

# Progress report
echo "Started copying results to NAS"
echo ""

# Copy files to NAS
rsync -thrqe "ssh -x" "${filtered_vcf_folder}" "${data_server}:${project_location}/${project}/" 

# Change ownership on nas (to allow user manipulating files later w/o administrative privileges)
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}/${project}/qual_filtered_vcf"
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}/${project}" # just in case...
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}" # just in case...

# Progress report
timestamp="$(date +%d%b%Y_%H:%M:%S)"
ssh -x "${data_server}" "echo \"Completed copying results to NAS: ${timestamp}\" >> ${project_location}/${project}/qual_filtered_vcf/${dataset}_${suffix}.log"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/qual_filtered_vcf/${dataset}_${suffix}.log"

# Remove results from cluster
rm -f "${filtered_vcf}"
rm -f "${filtered_vcf}.idx"
rm -f "${SelectVariants_log}"
rm -f "${filtered_vcf_md5}"

rm -f "${vcf_stats}"
rm -fr "${vcf_plots_folder}"

rm -f "${dataset}_${suffix}.log"
rm -f "${dataset}_${suffix}.res"

ssh -x "${data_server}" "echo \"Removed results from cluster\" >> ${project_location}/${project}/qual_filtered_vcf/${dataset}_${suffix}.log"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/qual_filtered_vcf/${dataset}_${suffix}.log"

# Return to the initial folder
cd "${init_dir}"

# Remove project folder from cluster
if [ "${remove_project_folder}" == "yes" ] || [ "${remove_project_folder}" == "Yes" ] 
then 
  rm -fr "${project_folder}"
  ssh -x "${data_server}" "echo \"Removed project folder from cluster\" >> ${project_location}/${project}/qual_filtered_vcf/${dataset}_${suffix}.log"
else
  ssh -x "${data_server}" "echo \"Project folder is not removed from cluster\" >> ${project_location}/${project}/qual_filtered_vcf/${dataset}_${suffix}.log"
fi 
