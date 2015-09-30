#!/bin/bash

# Update pipeline log
echo "Started: $(date +%d%b%Y_%H:%M:%S)"

job_file="/home/al720/tasks/TEMPLATE_02_wes_library_merge_qc_v2.job"
start_folder="$(pwd)"

echo "====================== Settings ======================"
echo ""

source "/scratch/medgen/scripts/p02_wes_library_merge_and_qc/a02_read_config.sh"
source "/scratch/medgen/scripts/p02_wes_library_merge_and_qc/a03_report_settings.sh"

echo "====================================================="
echo ""

# Copy files
#rsync -thrve ssh "admin@mgqnap.medschl.cam.ac.uk:/share/alexey/wecare/plate1_library1/merged/f01_bams/P1_A01_dedup.bam" "${start_folder}/"
#rsync -thrve ssh "admin@mgqnap.medschl.cam.ac.uk:/share/alexey/wecare/plate1_library1/merged/f01_bams/P1_A01_dedup.bai" "${start_folder}/"
dedup_bam="${start_folder}/P1_A01_dedup.bam"

# ----- Diagnose targets ----- #

# Progress report
echo ""
echo "DiagnoseTargets"
echo "Started: $(date +%d%b%Y_%H:%M:%S)"

# File names
diagnose_targets="${start_folder}/P1_A01_diagnose_targets.vcf"
missing_targets="${start_folder}/P1_A01_missing_targets.intervals"
diagnose_targets_log="${start_folder}/P1_A01_diagnose_targets.log"

# Process sample
"${java7}" -Xmx60g -jar "${gatk}" \
  -T DiagnoseTargets \
	-R "${ref_genome}" \
  -L "${nextera_targets_intervals}" \
	-I "${dedup_bam}" \
  -o "${diagnose_targets}" \
  -missing "${missing_targets}" \
  2> "${diagnose_targets_log}"

# Note: 
# Relatively fast step; no -nt/nct options 

# Progress report
echo "Completed: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# ----- Analyse missing targets ----- #

# Progress report
echo "Analyse missing targets"
echo "Started: $(date +%d%b%Y_%H:%M:%S)"

# File names
output="${start_folder}/P1_A01_missing_targets.grp"
diagnose_targets_log="${start_folder}/P1_A01_missing_targets.log"

# Process sample
"${java7}" -Xmx60g -jar "${gatk}" \
  -T QualifyMissingIntervals \
	-R "${ref_genome}" \
  -L "${missing_targets}" \
	-I "${dedup_bam}" \
  -o "${output}" \
  -targets "${nextera_targets_intervals}" \
  -nct 12 2> "${diagnose_targets_log}"

# Does not accept -cds option

# Progress report
echo "Completed: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Notes:

# Broad exome interval file provided in the bundle is used as coding sequence of genome 

# Depth over specific genes can be calculated uising gatk DepthOfCoverage
# https://www.broadinstitute.org/gatk/gatkdocs/
# org_broadinstitute_gatk_tools_walkers_coverage_DepthOfCoverage.php

