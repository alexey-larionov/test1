#!/bin/bash

# s01_combine_gvcfs.sh
# Combine gvcfs
# Alexey Larionov, 23Sep2015

# Read parameters
job_file="${1}"
scripts_folder="${2}"

#job_file="/home/al720/tasks/TEMPLATE_wes_combine_gvcfs_v1.job"
#scripts_folder="/scratch/medgen/scripts/p04_wecare_combine_gvcfs"

# Update pipeline log
echo "Started s01_combine_gvcfs: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Set parameters
source "${scripts_folder}/a02_read_config.sh"
echo "Read settings"
echo ""

# Go to working folder
init_dir="$(pwd)"
cd "${combined_gvcfs_folder}"

# --- Copy source gvcfs to cluster --- #

# Progress report
echo "Started copying source data"
echo ""

# Initialise file for list of source gvcfs
source_gvcfs="${set_id}.list"
> "${source_gvcfs}"

# For each library
for library in ${libraries}
do

  # Progress report
  echo "Getting list of samples"
  echo ""

  # Copy samples file
  rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${library}/gvcfs/samples.txt" "${combined_gvcfs_folder}/" 

  # Progress report
  echo "Copying gvcfs to cluster"
  echo ""

  # Get list of samples
  samples=$(awk 'NR>1 {print $1}' "${combined_gvcfs_folder}/samples.txt")

  # For each sample
  for sample in ${samples}
  do

    # Copy gvcf file and gvcf index
    gvcf_file=$(awk -v sm="${sample}" '$1==sm {print $2}' "${combined_gvcfs_folder}/samples.txt")
    rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${library}/gvcfs/${gvcf_file}" "${combined_gvcfs_folder}/"
    rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${library}/gvcfs/${gvcf_file}.idx" "${combined_gvcfs_folder}/"
    
    # Add gvcf file name to the list of source gvcfs
    echo "${gvcf_file}" >> "${source_gvcfs}"
    
    # Progress report
    echo "${sample}"
    
  done # next sample

done # next library

# Progress report
echo ""
echo "Completed copying source data: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Combine gvcfs --- #

# Progress report
echo "Started combining gvcfs"
echo ""

# File names
combined_gvcf="${set_id}.g.vcf"
combining_gvcf_log="${set_id}_combine_gvcfs.log"
combined_gvcf_md5="${set_id}.md5"

#gvcfs_to_combine='-V P1_A01.g.vcf -V P1_A02.g.vcf'

# Process files  
"${java7}" -Xmx60g -jar "${gatk}" \
  -T CombineGVCFs \
	-R "${ref_genome}" \
  -L "${nextera_targets_intervals}" -ip 100 \
	-V "${source_gvcfs}" \
  -o "${combined_gvcf}" \
  2> "${combining_gvcf_log}"

# Notes:

# Note that -V argument takes a file with list of gvcfs as the argument 
# Alternative could be like this: gvcfs_to_combine="${gvcfs_to_combine} -V ${gvcf_file}"

# http://gatkforums.broadinstitute.org/discussion/3973/combinegvcfs-performance mentions use of -nt
# However, the run with -nt generates error:
# Argument nt has a bad value: The analysis CombineGVCFs currently does not support parallel execution with nt.  
# Please run your analysis without the nt option.

# Make md5 file
md5sum "${combined_gvcf} ${combined_gvcf}.idx" > "${combined_gvcf_md5}"

# Remove the source files 
source_gvcfs="$(<${gvcfs_to_combine})"
for gvcf_file in ${source_gvcfs}
do
  rm -f "${gvcf_file}" "${gvcf_file}.idx"
done

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

# Copy results to NAS
rsync -thrqe "ssh -x" "${combined_gvcfs_folder}" "${data_server}:${project_location}/${project}/" 

# Progress report
echo ""
echo "Completed copying results to NAS: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Remove results from cluster 
if [ "${remove_project_folder}" == "yes" ] || [ "${remove_project_folder}" == "Yes" ] 
then 
  echo "Remove project folder from hpc scratch"
  #rm -fr "${project_folder}"
else
  echo "Remove combined gvcfs folder from hpc scratch"
  #rm -fr "${combined_gvcfs_folder}"
fi 

# Update log on NAS
ssh "${data_server}" "echo \"Removed data from cluster\" >> ${project_location}/${project}/combined_gvcfs/${set_id}.log"
