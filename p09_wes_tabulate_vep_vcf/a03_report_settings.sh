#!/bin/bash

# s03_report_config.sh
# Reporting settings for tabulating vep vcf
# Alexey Larionov, 20Oct2015

pipeline_info=$(grep "^#" "${job_file}")
pipeline_info=${pipeline_info//"#"/}

echo "------------------- Pipeline summary -----------------"
echo ""
echo "${pipeline_info}"
echo ""
echo "------------------ Analysis settings -----------------"
echo ""
echo "project: ${project}"
echo "dataset: ${dataset}"
echo "source_vcf: ${source_vcf}"
echo "source_vcf_folder: ${source_vcf_folder}"
echo ""
echo "data_server: ${data_server}"
echo "project_location: ${project_location}"
echo ""
echo "remove_project_folder: ${remove_project_folder}"
echo ""
echo "------------------- HPC settings ---------------------"
echo ""
echo "working_folder: ${working_folder}"
echo ""
echo "account_to_use: ${account_to_use}"
echo "time_to_request: ${time_to_request}"
echo ""
echo "------------------ mgqnap settings -------------------"
echo ""
echo "mgqnap_user: ${mgqnap_user}"
echo "mgqnap_group: ${mgqnap_group}"
echo ""
echo "----------------- Standard settings ------------------"
echo ""
echo "scripts_folder: ${scripts_folder}"
echo ""
echo "Working sub-folders on HPC"
echo "--------------------------"
echo ""
echo "project_folder: ${project_folder}"
echo "tabulated_vep_vcf_folder: ${tabulated_vep_vcf_folder}"
echo "" 
