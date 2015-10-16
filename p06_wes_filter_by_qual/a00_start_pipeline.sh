#!/bin/bash

# a00_start_pipeline.sh
# Start filtering raw vcf by qual
# Alexey Larionov, 14Oct2015

## Read parameter
job_file="${1}"
scripts_folder="${2}"

# Read job's settings
source "${scripts_folder}/a02_read_config.sh"

# Start lane pipeline log
mkdir -p "${filtered_vcf_folder}"
mkdir -p "${filtered_vcf_folder}/${raw_vcf%.vcf}_source_files"
log="${filtered_vcf_folder}/${raw_vcf%_raw.vcf}_qual${qual_threshold}.log"

echo "WES library: filtering raw vcf by qual" > "${log}"
echo "${raw_vcf}" >> "${log}" 
echo "Started: $(date +%d%b%Y_%H:%M:%S)" >> "${log}"
echo "" >> "${log}" 

echo "====================== Settings ======================" >> "${log}"
echo "" >> "${log}"

source "${scripts_folder}/a03_report_settings.sh" >> "${log}"

echo "=================== Pipeline steps ===================" >> "${log}"
echo "" >> "${log}"

# Submit job
slurm_time="--time=${time_to_request}"
slurm_account="--account=${account_to_use}"

sbatch "${slurm_time}" "${slurm_account}" \
  "${scripts_folder}/s01_filter_by_qual.sb.sh" \
  "${job_file}" \
  "${raw_vcf}" \
  "${qual_threshold}" \
  "${scripts_folder}" \
  "${filtered_vcf_folder}" \
  "${log}"

# Update pipeline log
echo "" >> "${log}"
echo "Submitted s01_filter_by_qual: $(date +%d%b%Y_%H:%M:%S)" >> "${log}"
echo "" >> "${log}"