#!/bin/bash

# a00_start_pipeline.sh
# Start genotyping gvcfs
# Alexey Larionov, 12Oct2015

## Read parameter
job_file="${1}"
scripts_folder="${2}"

# Read job's settings
source "${scripts_folder}/a02_read_config.sh"

# Start lane pipeline log
mkdir -p "${raw_vcf_folder}"
mkdir -p "${raw_vcf_folder}/${result_id}_source_files"
log="${raw_vcf_folder}/${result_id}_raw_vcf.log"

echo "WES library: genotype gvcfs" > "${log}"
echo "${result_id}" >> "${log}" 
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
  "${scripts_folder}/s01_genotype_gvcfs.sb.sh" \
  "${job_file}" \
  "${result_id}" \
  "${scripts_folder}" \
  "${raw_vcf_folder}" \
  "${log}"

# Update pipeline log
echo "" >> "${log}"
echo "Submitted s01_genotype_gvcfs: $(date +%d%b%Y_%H:%M:%S)" >> "${log}"
echo "" >> "${log}"