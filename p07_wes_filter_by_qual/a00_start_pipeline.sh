#!/bin/bash

# a00_start_pipeline.sh
# Start filtering vcf by qual
# Alexey Larionov, 19Oct2015

## Read parameter
job_file="${1}"
scripts_folder="${2}"

# Read job's settings
source "${scripts_folder}/a02_read_config.sh"

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

# Start lane pipeline log
mkdir -p "${filtered_vcf_folder}"
mkdir -p "${filtered_vcf_folder}/${dataset}_${suffix}_source_files"
log="${filtered_vcf_folder}/${dataset}_${suffix}.log"

echo "WES library: filtering vcf by qual" > "${log}"
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
  "${scripts_folder}/s01_filter_by_qual.sb.sh" \
  "${job_file}" \
  "${dataset}" \
  "${suffix}" \
  "${qual_threshold}" \
  "${scripts_folder}" \
  "${filtered_vcf_folder}" \
  "${log}"

# Update pipeline log
echo "" >> "${log}"
echo "Submitted s01_filter_by_qual: $(date +%d%b%Y_%H:%M:%S)" >> "${log}"
echo "" >> "${log}"