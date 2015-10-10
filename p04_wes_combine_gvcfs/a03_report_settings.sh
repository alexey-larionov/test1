#!/bin/bash

# s03_report_config.sh
# Reporting settings for combining gvcfs
# Alexey Larionov, 23Sep2015

pipeline_info=$(grep "^#" "${job_file}")
pipeline_info=${pipeline_info//"#"/}

echo "------------------- Pipeline summary -----------------"
echo ""
echo "${pipeline_info}"
echo ""
echo "------------------ Analysis settings -----------------"
echo ""
echo "project: ${project}"
echo "libraries: ${libraries}"
echo "set_id: ${set_id}"
echo ""
echo "data_server: ${data_server}"
echo "project_location: ${project_location}"
echo ""
echo "----------- Data keeping/moving after run ------------"
echo ""
echo "remove_project_folder_from_hpc: ${remove_project_folder_from_hpc}"
echo "remove_source_files_from_hpc: ${remove_source_files_from_hpc}"
echo "remove_results_from_hpc: ${remove_results_from_hpc}"
echo "copy_results_to_nas: ${copy_results_to_nas}"
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
echo "Tools"
echo "-----"
echo ""
echo "tools_folder: ${tools_folder}"
echo "java7: ${java7}"
echo "gatk: ${gatk}"
echo ""
echo "Resources" 
echo "---------"
echo ""
echo "resources_folder: ${resources_folder}"
echo ""
echo "decompressed_bundle_folder: ${decompressed_bundle_folder}"
echo "ref_genome: ${ref_genome}"
echo ""
echo "nextera_folder: ${nextera_folder}"
echo "nextera_targets_intervals: ${nextera_targets_intervals}"
echo ""
echo "Working sub-folders on HPC"
echo "--------------------------"
echo ""
echo "project_folder: ${project_folder}"
echo "combined_gvcfs_folder: ${combined_gvcfs_folder}"
echo "" 