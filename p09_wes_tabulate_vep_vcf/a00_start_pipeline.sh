#!/bin/bash

# a00_start_pipeline.sh
# Start tabulating vep vcf
# Alexey Larionov, 20Oct2015

## Read parameter
job_file="${1}"
scripts_folder="${2}"

# Read job's settings
source "${scripts_folder}/a02_read_config.sh"

# Start lane pipeline log
mkdir -p "${tabulated_vep_vcf_folder}"
log="${tabulated_vep_vcf_folder}/${dataset}_vep2txt.log"

echo "WES library: tabulating vep vcf" > "${log}"
echo "${source_vcf}" >> "${log}" 
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
  "${scripts_folder}/s01_tabulate_vep_vcf.sb.sh" \
  "${job_file}" \
  "${dataset}" \
  "${scripts_folder}" \
  "${tabulated_vep_vcf_folder}" \
  "${log}"

# Update pipeline log
echo "" >> "${log}"
echo "Submitted s01_tabulate_vep_vcf: $(date +%d%b%Y_%H:%M:%S)" >> "${log}"
echo "" >> "${log}"