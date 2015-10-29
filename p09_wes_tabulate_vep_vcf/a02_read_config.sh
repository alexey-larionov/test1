#!/bin/bash

# s02_read_config.sh
# Parse config file for tabulating vep vcf
# Alexey Larionov, 20Oct2015

# Function for reading parameters
function get_parameter()
{
	local parameter="${1}"
  local line
	line=$(awk -v p="${parameter}" 'BEGIN { FS=":" } $1 == p {print $2}' "${job_file}") 
	echo ${line} # return value
}

# ======= Analysis settings ======= #

project=$(get_parameter "project") # e.g. wecare

dataset=$(get_parameter "dataset name") # e.g. CCLG_v1_Oct_results_qual100
source_vcf_folder=$(get_parameter "source vcf folder") # e.g. vep_annotated_vcf
source_vcf=$(get_parameter "source vcf") # e.g. CCLG_v1_Oct_results_qual100.0_vep.vcf

data_server=$(get_parameter "Data server") # e.g. admin@mgqnap.medschl.cam.ac.uk
project_location=$(get_parameter "Project location") # e.g. /share/mae

remove_project_folder=$(get_parameter "Remove project folder from HPC scratch after run") # e.g. yes

# ========== HPC settings ========== #

working_folder=$(get_parameter "working_folder") # e.g. /scratch/medgen/users/alexey
account_to_use=$(get_parameter "Account to use on HPC") # e.g. TISCHKOWITZ-SL2
time_to_request=$(get_parameter "Max time to request (hrs.min.sec)") # e.g. 00.30.00
time_to_request=${time_to_request//./:} # substitute dots to colons 

# ======== mgqnap settings ======== #

mgqnap_user=$(get_parameter "mgqnap_user") # e.g. alexey
mgqnap_group=$(get_parameter "mgqnap_group") # e.g. mtgroup

# ======= Standard settings ======= #

scripts_folder=$(get_parameter "scripts_folder") # e.g. /scratch/medgen/scripts/p09_wes_tabulate_vep_vcf

# ----------- Working sub-folders ---------- #

project_folder="${working_folder}/${project}" # e.g. CCLG

tabulated_vep_vcf_folder=$(get_parameter "tabulated_vep_vcf_folder") # e.g. tabulated_vep_vcf
tabulated_vep_vcf_folder="${project_folder}/${tabulated_vep_vcf_folder}"
