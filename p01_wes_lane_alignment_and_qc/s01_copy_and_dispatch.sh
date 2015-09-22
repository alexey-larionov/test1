#!/bin/bash

# s01_copy_and_dispatch.sh
# Wes lane alignment pipeline
# Copy source files and dispatch samples to nodes
# Alexey Larionov, 21Sep2015

# Read parameters
job_file="${1}"
scripts_folder="${2}"
pipeline_log="${3}"

# Update pipeline log
echo "Started s01_copy_and_dispatch: $(date +%d%b%Y_%H:%M:%S)" >> "${pipeline_log}"

# ================= Copy source files to cluster ================= #

# Progress report to the job log
echo "Started copying source fastq files to cluster"
echo ""

# Set parameters
source "${scripts_folder}/a02_read_config.sh"
echo "Read settings"
echo ""

# Copy files
mkdir -p "${source_fastq_folder}"
"${rsync}" -thrve "ssh -x" "${source_server}:${source_folder}/" "${source_fastq_folder}/" 

# Completion message to the job log
echo ""
echo "Completed copying source fastq files to cluster: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# ================= Rename source files if requested ================= #

if [ "${use_contents_csv}" == "yes" ] || [ "${use_contents_csv}" == "Yes" ]
then

    # Progress report to the job log
    echo "Started parsing contents.csv and renaming fastq files"
    echo ""
    
    # Rearrange folders
    mkdir -p "${renamed_fastq_folder}"
    mv -f "${source_fastq_folder}/" "${lane_folder}/f01_fastq/"
    source_fastq_folder="${lane_folder}/f01_fastq/f01_source_fastq"
    
    # Progress report
    echo "Rearranged fastq folder names"
    echo ""
    
    # Read name of the contents.csv file
    cd "${source_fastq_folder}"
    contents_file_name="$(ls *.contents.csv)"
    
    # Check that the file has been found
    if [ -z "${contents_file_name}" ]
    then
      echo "Can not find the content.csv file"
      echo "Pipeline terminated"
      exit 1
    fi
    
    # Check the 1st line of the file
    read line1 < "${contents_file_name}"
    if [ "${line1}" != '"Pool","Barcode","Sequence","Sample name"' ]
    then
      echo "Unexpected format of the content.csv file"
      echo "Pipeline terminated"
      exit 1
    fi
    
    # Parse the name of contents.csv file
    contents=${contents_file_name//"."/" "}
    read slx_id flowcell_id flowcell_lane_id etc <<< ${contents}
    
    # Get full file name for contents.csv
    contents_file="${source_fastq_folder}/${contents_file_name}"
    cd "${scripts_folder}"
    
    # ----- Copy fastq files for read 1 ----- #
    
    # Progress report
    echo "Copy fastq files"
    echo ""
    
    # Prepare list of paired file names for read 1, e.g. 
    # SLX-9871.N703_N505.C71EDANXX.s_8.r_1.fq.gz Sample_name.r_1.fq.gz
    # The conversion accounts for specific format and content of content.csv file
    # as generated by CRUK CI genomic core at the time of this script preparation
    script_1='gsub(/"/,"") sub(/-/,"_",$2) $1~'"${slx_id}"' {print $1"."$2"."fc"."fcl".r_1.fq.gz "$4".r_1.fq.gz "$1"."$2"."fc"."fcl".md5sums.txt"}'
    reads_1=$(awk -v FS=',' -v slx="${slx_id}" -v fc="${flowcell_id}" -v fcl="${flowcell_lane_id}" "${script_1}" "${contents_file}")

    # Copy files to the target folder under the new names
    while read src_file_name tgt_file_name md5_file_name
    do
    
      # Get full names for te source and target files
      src_file="${source_fastq_folder}/${src_file_name}"
      tgt_file="${renamed_fastq_folder}/${tgt_file_name}"
      md5_file="${source_fastq_folder}/${md5_file_name}"
        
      # Check that the source file exists
      if [ ! -e "${src_file}" ]
      then
        echo "Can not find source file:"
        echo "${src_file}"
        echo "Pipeline terminated"
        exit 1
      fi
      
      # Copy the file
      cp "${src_file}" "${tgt_file}"
      
      # Update md5 file content
      sed -i s/"${src_file_name}"/"${tgt_file_name}"/ "${md5_file}" 
      
      # Progress report
      echo "${src_file} -> ${tgt_file}"
      
    done <<< "${reads_1}" # next file
    echo ""
    
    # ----- Copy fastq files for read 2 ----- #
    
    # Prepare list of paired file names for read 1, e.g. 
    # SLX-9871.N703_N505.C71EDANXX.s_8.r_2.fq.gz Sample_name.r_2.fq.gz
    # The conversion accounts for specific format and content of content.csv file
    # as generated by CRUK CI genomic core at the time of this script preparation
    script_2='gsub(/"/,"") sub(/-/,"_",$2) $1~'"${slx_id}"' {print $1"."$2"."fc"."fcl".r_2.fq.gz "$4".r_2.fq.gz "$1"."$2"."fc"."fcl".md5sums.txt"}'
    reads_2=$(awk -v FS=',' -v slx="${slx_id}" -v fc="${flowcell_id}" -v fcl="${flowcell_lane_id}" "${script_2}" "${contents_file}")
    
    # Copy files to the target folder under the new names
    while read src_file_name tgt_file_name md5_file_name
    do
    
      # Get full names for te source and target files
      src_file="${source_fastq_folder}/${src_file_name}"
      tgt_file="${renamed_fastq_folder}/${tgt_file_name}"
      md5_file="${source_fastq_folder}/${md5_file_name}"
        
      # Check that the source file exists
      if [ ! -e "${src_file}" ]
      then
        echo "Can not find source file:"
        echo "${src_file}"
        echo "Pipeline terminated"
        exit 1
      fi
      
      # Copy the file
      cp "${src_file}" "${tgt_file}"
      
      # Update md5 file content
      sed -i s/"${src_file_name}"/"${tgt_file_name}"/ "${md5_file}" 
      
      # Progress report
      echo "${src_file} -> ${tgt_file}"
      
    done <<< "${reads_2}" # next file
    echo ""
    
    # ----- Copy md5 files and chack md5 sums ----- #
    
    # Progress report
    echo "Check md5 sums"
    echo ""
    
    # Prepare list of paired file names for read 1, e.g. 
    # SLX-9871.N703_N505.C71EDANXX.s_8.md5sums.txt Sample_name.md5sums.txt
    # The conversion accounts for specific format and content of content.csv file
    # as generated by CRUK CI genomic core at the time of this script preparation  
    script_3='gsub(/"/,"") sub(/-/,"_",$2) $1 !~ "Pool" {print $1"."$2"."fc"."fcl".md5sums.txt "$4".md5"}'
    md5_files=$(awk -v FS=',' -v slx="${slx_id}" -v fc="${flowcell_id}" -v fcl="${flowcell_lane_id}" "${script_3}" "${contents_file}")
    
    # Copy files to the target folder under the new names and check md5 sums
    while read src_file_name tgt_file_name
    do
    
      # Get full names for te source and target files
      src_file="${source_fastq_folder}/${src_file_name}"
      tgt_file="${renamed_fastq_folder}/${tgt_file_name}"
      
      # Check that the source file exists
      if [ ! -e "${src_file}" ]
      then
        echo ""
        echo "Can not find source file:"
        echo "${src_file}"
        echo "Pipeline terminated"
        exit 1
      fi
      
      # Copy the file
      cp "${src_file}" "${tgt_file}"
      
      # Check md5 sums
      cd "${renamed_fastq_folder}"
      md5sum -c "${tgt_file}"
      md5chk="${?}"
      if [ "${md5chk}" != "0" ]
      then
        echo ""
        echo "Failed md5 checksum:"
        echo "${tgt_file}"
        echo "Pipeline terminated"
        exit 1
      fi
      cd "${lane_folder}"
      
    done <<< "${md5_files}" # next file
    echo ""
    
    # Generate the new samples file for renamed fastqs
    samples_file="${renamed_fastq_folder}/samples.txt"
    header=$(echo -e "sample\tfastq1\tfastq2\tmd5") 
    echo -e "${header}" >  "${samples_file}"
    
    script_4='gsub(/"/,"") $1 !~ "Pool" {print $4"\t"$4".r_1.fq.gz\t"$4".r_2.fq.gz\t"$4".md5"}'
    renamed_samles=$(awk -v FS=',' "${script_4}" "${contents_file}")
    echo -e "${renamed_samles}" >> "${samples_file}"
    
    echo "Made samples.txt file"
    echo ""
    
    # Redirect source fastq folder
    source_fastq_folder="${renamed_fastq_folder}"
    
    # Progress report to the job log
    echo "Completed parsing contents.csv and renaming fastq files: $(date +%d%b%Y_%H:%M:%S)"
    echo ""
    
fi # Completed renaming source files if requested

# ================= Dispatch samples to nodes for processing ================= #

# Make folders on cluster
mkdir -p "${fastqc_raw_folder}"
mkdir -p "${trimmed_fastq_folder}"
mkdir -p "${fastqc_trimmed_folder}"
mkdir -p "${bam_folder}"
mkdir -p "${flagstat_folder}"
mkdir -p "${picard_mkdup_folder}"
mkdir -p "${picard_inserts_folder}"
mkdir -p "${picard_alignment_folder}"
mkdir -p "${picard_hybridisation_folder}"
mkdir -p "${qualimap_results_folder}"
mkdir -p "${samstat_results_folder}"
# etc

# Progress update 
echo "Made working folders on cluster"
echo ""

# Get list of samples
samples_file="${source_fastq_folder}/samples.txt"
samples=$(awk '$1 != "sample" {print $1}' "${samples_file}")

# Count samples and check that all source files exist for each sample
samples_count=0
while read sample_id fastq1 fastq2 md5
do
  if [ "${sample_id}" != "sample" ]
  then
  
    # Increment samples count
    samples_count="$(( ${samples_count} + 1 ))"
  
    # fastq1
    if [ ! -e "${source_fastq_folder}/${fastq1}" ]
    then
      echo "Missed fastq1 for sample ${sample_id}"
      echo "Pipeline treminated"
      exit 1
    fi
  
    # fastq2
    if [ ! -e "${source_fastq_folder}/${fastq2}" ]
    then
      echo "Missed fastq2 for sample ${sample_id}"
      echo "Pipeline treminated"
      exit 1
    fi
  
    # md5
    if [ ! -e "${source_fastq_folder}/${md5}" ]
    then
      echo "Missed md5 for sample ${sample_id}"
      echo "Pipeline treminated"
      exit 1
    fi
    
  fi
done < "${samples_file}"

# Progress report
echo "Found data for ${samples_count} samples"
echo "Submitting samples:"
echo ""

# Set time and account for pipeline submissions
slurm_time="--time=${time_alignment_qc}"
slurm_account="--account=${account_alignment_qc}"

# For each sample
for sample in ${samples}
do

  # Start pipeline on a separate node
  sbatch "${slurm_time}" "${slurm_account}" \
       "${scripts_folder}/s02_align_and_qc.sb.sh" \
       "${sample}" \
       "${job_file}" \
       "${logs_folder}" \
       "${scripts_folder}" \
       "${pipeline_log}" &
  
  # Progress report
  echo "${sample}"
  
done # Next sample
echo ""

# Progress update 
echo "Submitted all samples: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Update pipeline log
echo "Detected ${samples_count} samples" >> "${pipeline_log}"
echo "Completed s01_copy_and_dispatch: $(date +%d%b%Y_%H:%M:%S)" >> "${pipeline_log}"
echo "" >> "${pipeline_log}"