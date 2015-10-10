#!/bin/bash

# s01_genotype_gvcfs.sh
# Genotype gvcfs
# Alexey Larionov, 25Sep2015

# Read parameters
job_file="${1}"
scripts_folder="${2}"

# Update pipeline log
echo "Started s01_genotype_gvcfs: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Set parameters
source "${scripts_folder}/a02_read_config.sh"
echo "Read settings"
echo ""

# Go to working folder
init_dir="$(pwd)"
cd "${raw_vcf_folder}"

# --- Copy source gvcfs to cluster --- #

# Progress report
echo "Started copying source data"
echo ""

# Initialise file for list of source gvcfs
source_gvcfs="${result_id}.list"
> "${source_gvcfs}"

# For each library
for set in ${sets}
do

  # Copy data
  rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/combined_gvcfs/${set}.g.vcf" "${raw_vcf_folder}/"
  rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/combined_gvcfs/${set}.g.vcf.idx" "${raw_vcf_folder}/"

  # Add gvcf file name to the list of source gvcfs
  echo "${set}.g.vcf" >> "${source_gvcfs}"

  # Progress report
  echo "${set}"

done # next set

# Progress report
echo ""
echo "Completed copying source data: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Combine gvcfs --- #

# Progress report
echo "Started genotyping gvcfs"
echo ""

# File names
raw_vcf="${result_id}_raw.vcf"
raw_vcf_log="${result_id}_raw_vcf.log"
raw_vcf_md5="${result_id}_raw_vcf.md5"

# Calculate variant calls
"${java7}" -Xmx60g -jar "${gatk}" \
  -T GenotypeGVCFs \
  -R "${ref_genome}" \
  -L "${nextera_targets_intervals}" -ip 100 \
  -V "${source_gvcfs}" \
  -o "${raw_vcf}" \
  -nt 14 &>>  "${raw_vcf_log}"

# Note about other possible options:
# Default max num of alternate alleles is 6, it can be changed, e.g.
# -maxAltAlleles 20
# However, it may be computationally demanding

# Make md5 file
md5sum "${raw_vcf}" "${raw_vcf}.idx" > "${raw_vcf_md5}"

# Remove the source files 
gvcfs=$(< "${source_gvcfs}")
for gvcf in ${gvcfs}
do
  rm -f "${gvcf}" "${gvcf}.idx"
done

# Return to the initial folder
cd "${init_dir}"

# Progress report
echo ""
echo "Completed genotyping gvcfs: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Raw vcf stats --- #

# Progress report
echo "Calculating raw vcf stats and making plots"
echo ""

# File names
vcf_stats="${result_id}_raw.vchk"

# Calculate vcf stats
"${bcftools}" stats -d 0,25000,500 -F "${ref_genome}" "${raw_vcf}" > "${vcf_stats}" 

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
rsync -thrqe "ssh -x" "${raw_vcf_folder}" "${data_server}:${project_location}/${project}/" 

# Progress report
echo ""
echo "Completed copying results to NAS: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Remove results from cluster 
if [ "${remove_project_folder}" == "yes" ] || [ "${remove_project_folder}" == "Yes" ] 
then 
  echo "Remove project folder from hpc scratch"
  #rm -fr "${project_folder}"
else
  echo "Remove raw vcf folder from hpc scratch"
  #rm -fr "${raw_vcf_folder}"
fi 

# Update log on NAS
ssh "${data_server}" "echo \"Removed data from cluster\" >> ${project_location}/${project}/raw_vcf/${result_id}_raw_vcf.log"
