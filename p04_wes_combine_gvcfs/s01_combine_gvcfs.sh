#!/bin/bash

# s01_combine_gvcfs.sh
# Combine gvcfs
# Alexey Larionov, 07Oct2015

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
  echo "${library}"
  echo "Getting list of samples"


  # Copy samples file
  rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/${library}/gvcfs/samples.txt" "${combined_gvcfs_folder}/" 

  # Progress report
  echo "Copying gvcfs to cluster"

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
  
  echo ""
  
done # next library

# Remove samples file remaining from the last library
rm -f "${combined_gvcfs_folder}/samples.txt" 

# Progress report
echo "Completed copying source data: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Combine gvcfs --- #

# Progress report
echo "Started combining gvcfs"
echo ""

# File names
combined_gvcf="${set_id}.g.vcf"
combining_gvcf_log="${set_id}_combine_gvcfs.log"
combined_gvcf_md5="${combined_gvcf}.md5"

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

# -V argument takes a file with list of gvcfs as the argument 

# No papallelism supported in Oct 2015
# http://gatkforums.broadinstitute.org/discussion/3973/combinegvcfs-performance mentions use of -nt
# However, runs with -nt or -nct generated errors (...CombineGVCFs currently does not support parallel execution...)  

# Progress report
echo "Completed combining gvcfs: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Make md5 file
echo "Started calculating md5 sum"
echo ""

md5sum "${combined_gvcf}" "${combined_gvcf}.idx" > "${combined_gvcf_md5}"

# Progress report
echo ""
echo "Completed calculating md5 sum: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# ----- Remove the source gvcf files from hpc ----- #

if [ "${remove_source_files_from_hpc}" == "yes" ] || [ "${remove_source_files_from_hpc}" == "Yes" ]
then  
  gvcfs_to_remove="$(<${source_gvcfs})"
  for gvcf_file in ${gvcfs_to_remove}
  do
    rm -f "${gvcf_file}" "${gvcf_file}.idx"
  done

  echo "Removed source gvcf files from cluster"
  echo ""
else
  echo "Source gvcf files are not removed from hpc"
  echo ""
fi

# ----- Copy results to NAS ----- #

if [ "${copy_results_to_nas}" == "yes" ] || [ "${copy_results_to_nas}" == "Yes" ]
then  

  # Progress report
  echo "Started copying results to NAS: $(date +%d%b%Y_%H:%M:%S)"
  echo ""

  # Copy results
  rsync -thrqe "ssh -x" "${combined_gvcfs_folder}" "${data_server}:${project_location}/${project}/" 

  # Update owner/group
  # to be done

  # Progress report
  echo "Completed copying results to NAS: $(date +%d%b%Y_%H:%M:%S)"
  echo ""

else
  echo "Results are not copied to NAS"
  echo ""
fi

# ----- Remove results from cluster ----- #

if [ "${remove_results_from_hpc}" == "yes" ] || [ "${remove_results_from_hpc}" == "Yes" ] 
then 

  rm -f "${combined_gvcf}"
  rm -f "${combined_gvcf_md5}"
  rm -f "${combining_gvcf_log}"
  rm -f "${source_gvcfs}"
  rm -f "${set_id}_combine_gvcfs.res"
  rm -f "${set_id}.log"

  # Update log on NAS, if needed
  if [ "${copy_results_to_nas}" == "yes" ] || [ "${copy_results_to_nas}" == "Yes" ]
  then  
    rsync -thrqe "ssh -x" "${set_id}.log" "${data_server}:${project_location}/${project}/combined_gvcfs/"
  fi

else 
  echo "Results are not removed from hpc"
  echo ""
fi 

# Return to the initial folder
cd "${init_dir}"

# --- Remove working folder from hpc --- #
if [ "${remove_project_folder_from_hpc}" == "yes" ] || [ "${remove_project_folder_from_hpc}" == "Yes" ]
then
  rm -fr "${project_folder}"
  
  # Update log on NAS, if needed
  if [ "${copy_results_to_nas}" == "yes" ] || [ "${copy_results_to_nas}" == "Yes" ]
  then  
    ssh "${data_server}" "echo \"Removed working folder from cluster\" >> ${project_location}/${project}/combined_gvcfs/${set_id}.log"
  fi
  
fi
