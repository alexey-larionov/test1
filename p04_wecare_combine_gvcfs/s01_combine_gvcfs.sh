#!/bin/bash

# s01_combine_gvcfs.sh
# Combine gvcfs
# Alexey Larionov, 23Sep2015

# Read parameters
job_file="${1}"
scripts_folder="${2}"

# Update pipeline log
echo "Started s01_combine_gvcfs: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Set parameters
source "${scripts_folder}/a02_read_config.sh"
echo "Read settings"
echo ""

# --- Copy source gvcfs to cluster --- #

# Progress report
echo "Started copying source data"
echo ""

# For each library
for library in ${libraries}
do

  # Progress report
  echo "Getting list of samples"
  echo ""

  # Copy samples file
  rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${library}/gvcfs/samples.txt" "${gvcf_folder}/" 

  # Progress report
  echo "Copying gvcfs to cluster"
  echo ""

  # Get list of samples
  samples=$(awk 'NR>1 {print $1}' "${gvcf_folder}/samples.txt")

  # For each sample
  for sample in ${samples}
  do

    # Copy gvcf file
    gvcf_file=$(awk -v sm="${sample}" '$1==sm {print $2}' "${gvcf_folder}/samples.txt")
    rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${library}/gvcfs/${gvcf_file}" "${gvcf_folder}/"

  # Progress report
  echo "${sample}"

done

# Progress report
echo ""
echo "Completed copying source data: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Combine gvcfs --- #

# Progress report
echo "Started combining gvcfs"
echo ""

# Go to gvcfs folder
init_dir="$(pwd)"
cd "${gvcf_folder}"

# File names
input_gvcfs=$(awk 'NR>1 {print $2}' "${gvcf_folder}/samples.txt")
combined_gvcf="${set_id}.g.vcf"
combining_gvcf_log="${set_id}_cmb_gvcf.log"
combined_gvcf_md5="${set_id}_cmb_gvcf.md5"

# Process files  
"${java7}" -Xmx60g -jar "${gatk}" \
  -T CombineGVCFs \
	-R "${ref_genome}" \
  -L "${nextera_targets_intervals}" -ip 100 \
	-V "${input_gvcfs}" \
  -o "${combined_gvcf}" \
  -nt 12 2> "${combining_gvcf_log}"

# Note: 
# http://gatkforums.broadinstitute.org/discussion/3973/combinegvcfs-performance
# mentions use of -nt

# Make md5 file
md5sum "${combined_gvcf}" > "${combined_gvcf_md5}"

# Return to the initial folder
cd "${init_dir}"

# Progress report
echo ""
echo "Completed combining gvcfs: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Copy output back to NAS --- #

# Progress report
echo "Started copying results to NAS"
echo ""

# Copy files to NAS
ssh "${data_server}" "mkdir -p ${project_location}/${project}/combined_gvcfs"
scp -qp "${gvcf_folder}/${combined_gvcf}" "${data_server}:${project_location}/${project}/combined_gvcfs/"
scp -qp "${gvcf_folder}/${combined_gvcf_md5}" "${data_server}:${project_location}/${project}/combined_gvcfs/"
scp -qp "${gvcf_folder}/${combining_gvcf_log}" "${data_server}:${project_location}/${project}/combined_gvcfs/"
scp -qp "${gvcf_folder}/${set_id}.log" "${data_server}:${project_location}/${project}/combined_gvcfs/"

# Progress report
echo ""
echo "Completed copying results to NAS: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Remove results from cluster 
if [ "${remove_project_folder}" == "yes" ] || [ "${remove_project_folder}" == "Yes" ] 
then 
  #rm -fr "${project_folder}"
else
  #rm -fr "${gvcf_folder}"
fi 

# Update log on NAS
ssh "${data_server}" "echo \"Removed data from cluster\" >> ${project_location}/${project}/combined_gvcfs/${set_id}.log"
