#!/bin/bash

# s02_read_config.sh
# Parse config file for genotyping gvcfs
# Alexey Larionov, 24Sep2015

# Function for reading parameters
function get_parameter()
{
	local parameter="${1}"
  local line
	line=$(awk -v p="${parameter}" 'BEGIN { FS=":" } $1 == p {print $2}' "${job_file}") 
	echo ${line} # return value
}

# ======= Analysis settings ======= #

project=$(get_parameter "project") # e.g. project1
sets=$(get_parameter "sets") # e.g. set1
result_id=$(get_parameter "result_id") # e.g. resuilt1

data_server=$(get_parameter "Data server") # e.g. admin@mgqnap.medschl.cam.ac.uk
project_location=$(get_parameter "Project location") # e.g. /share/alexey

remove_project_folder=$(get_parameter "Remove project folder from HPC scratch after run") # e.g. yes

# ========== HPC settings ========== #

working_folder=$(get_parameter "working_folder") # e.g. /scratch/medgen/users/alexey

account_to_use=$(get_parameter "Account to use on HPC") # e.g. TISCHKOWITZ-SL2
time_to_request=$(get_parameter "Max time to request (hrs.min.sec)") # e.g. 02.00.00
time_to_request=${time_to_request//./:} # substitute dots to colons 

# ======== mgqnap settings ======== #

mgqnap_user=$(get_parameter "mgqnap_user") # e.g. alexey
mgqnap_group=$(get_parameter "mgqnap_group") # e.g. mtgroup

# ======= Standard settings ======= #

scripts_folder=$(get_parameter "scripts_folder") # e.g. /scratch/medgen/scripts/p04_wecare_combine_gvcfs

# ----------- Tools ---------- #

tools_folder=$(get_parameter "tools_folder") # e.g. /scratch/medgen/tools

java7=$(get_parameter "java7") # e.g. java/jre1.7.0_76/bin/java
java7="${tools_folder}/${java7}"

gatk=$(get_parameter "gatk") # e.g. gatk/gatk-3.4-46/GenomeAnalysisTK.jar
gatk="${tools_folder}/${gatk}"

bcftools=$(get_parameter "bcftools") # e.g. bcftools/bcftools-1.2/bin/bcftools
bcftools="${tools_folder}/${bcftools}"

plot_vcfstats=$(get_parameter "plot_vcfstats") # e.g. bcftools/bcftools-1.2/bin/plot-vcfstats
plot_vcfstats="${tools_folder}/${plot_vcfstats}"

# Prepend path to local version of python within the toolbox:
# it contains updated version of matplotlib library for plot-vcfstats script
python_bin=$(get_parameter "python_bin") # e.g. python/python_2.7.10/bin/
python_bin="${tools_folder}/${python_bin}"
PATH="${python_bin}":$PATH

# ----------- Resources ---------- #

resources_folder=$(get_parameter "resources_folder") # e.g. /scratch/medgen/resources

decompressed_bundle_folder=$(get_parameter "decompressed_bundle_folder") # e.g. gatk_bundle/b37/decompressed
decompressed_bundle_folder="${resources_folder}/${decompressed_bundle_folder}"

ref_genome=$(get_parameter "ref_genome") # e.g. human_g1k_v37.fasta
ref_genome="${decompressed_bundle_folder}/${ref_genome}"

nextera_folder=$(get_parameter "nextera_folder") # e.g. illumina_nextera
nextera_folder="${resources_folder}/${nextera_folder}"

nextera_targets_intervals=$(get_parameter "nextera_targets_intervals") # e.g. nexterarapidcapture_exome_targetedregions_v1.2.b37.intervals
nextera_targets_intervals="${nextera_folder}/${nextera_targets_intervals}"

# ----------- Working sub-folders ---------- #

project_folder="${working_folder}/${project}" # e.g. project1

raw_vcf_folder=$(get_parameter "raw_vcf_folder") # e.g. raw_vcf
raw_vcf_folder="${project_folder}/${raw_vcf_folder}"

vcf_plots_folder=$(get_parameter "vcf_plots_folder") # e.g. plots
vcf_plots_folder="${raw_vcf_folder}/${vcf_plots_folder}"
