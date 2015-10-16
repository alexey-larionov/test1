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

# Go to working folder
init_dir="$(pwd)"
cd "${filtered_vcf_folder}"

# --- Copy source gvcfs to cluster --- #

# Progress report
echo "Started copying source data"
echo ""

rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/raw_vcf/${raw_vcf}" "${filtered_vcf_folder}/${raw_vcf%.vcf}_source_files/"
rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/raw_vcf/${raw_vcf}.idx" "${filtered_vcf_folder}/${raw_vcf%.vcf}_source_files/"

# Progress report
echo "Completed copying source data: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Filter by qual --- #

# Progress report
echo "Started filtering"
echo ""

# File names
source_vcf="${filtered_vcf_folder}/${raw_vcf%.vcf}_source_files/${raw_vcf}"
filtered_vcf="${raw_vcf%_raw.vcf}_qual${qual_threshold}.vcf"
SelectVariants_log="${raw_vcf%_raw.vcf}_SelectVariants_qual${qual_threshold}.log"
filtered_vcf_md5="${filtered_vcf%.vcf}.md5"

# Select variants
"${java7}" -Xmx60g -jar "${gatk}" \
  -T SelectVariants \
  -R "${ref_genome}" \
  -L "${nextera_targets_intervals}" -ip 100 \
  -V "${source_vcf}" \
  -o "${filtered_vcf}" \
  -select "QUAL > ${qual_threshold}" \
  -nt 14 &>  "${SelectVariants_log}"

# Make md5 file
md5sum "${filtered_vcf}" "${filtered_vcf}.idx" > "${filtered_vcf_md5}"

# Remove source files from cluster
rm -fr "${raw_vcf%.vcf}_source_files"

# Progress report
echo "Completed filtering: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Raw vcf stats --- #

# Progress report
echo "Calculating filtered vcf stats and making plots"
echo ""

# File names
vcf_stats="${filtered_vcf%.vcf}.vchk"

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
ssh -x "${data_server}" "echo \"Completed copying results to NAS: ${timestamp}\" >> ${project_location}/${project}/qual_filtered_vcf/${raw_vcf%_raw.vcf}_qual${qual_threshold}.log"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/qual_filtered_vcf/${raw_vcf%_raw.vcf}_qual${qual_threshold}.log"

# Return to the initial folder
cd "${init_dir}"

# Remove results from cluster
if [ "${remove_project_folder}" == "yes" ] || [ "${remove_project_folder}" == "Yes" ] 
then 
  rm -fr "${project_folder}"
  ssh -x "${data_server}" "echo \"Working folder is removed from cluster\" >> ${project_location}/${project}/qual_filtered_vcf/${raw_vcf%_raw.vcf}_qual${qual_threshold}.log"
else
  ssh -x "${data_server}" "echo \"Working folder is not removed from cluster\" >> ${project_location}/${project}/qual_filtered_vcf/${raw_vcf%_raw.vcf}_qual${qual_threshold}.log"
fi 

