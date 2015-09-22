#!/bin/bash

# s02_read_config.sh
# Parse congig file for wes lane alignment pipeline
# Alexey Larionov, 16Aug2015

pipeline_info=$(grep "^#" "${job_file}")
pipeline_info=${pipeline_info//"# "/}

echo "------------------- Pipeline summary -----------------"
echo ""
echo "${pipeline_info}"
echo ""
echo "------------------ Analysis settings -----------------"
echo ""
echo "project: ${project}"
echo "library: ${library}"
echo "lane: ${lane}"
echo ""
echo "source_server: ${source_server}"
echo "source_folder: ${source_folder}"
echo ""
echo "results_server: ${results_server}"
echo "results_folder: ${results_folder}"
echo ""
echo "use_contents_csv: ${use_contents_csv}"
echo ""
echo "remove_project_folder: ${remove_project_folder}"
echo ""
echo "------------------- HPC settings ---------------------"
echo ""
echo "working_folder: ${working_folder}"
echo "project_folder: ${project_folder}"
echo "lane_folder: ${lane_folder}"
echo ""
echo "account_copy_in: ${account_copy_in}"
echo "time_copy_in: ${time_copy_in}"
echo ""
echo "account_alignment_qc: ${account_alignment_qc}"
echo "time_alignment_qc: ${time_alignment_qc}"
echo ""
echo "account_move_out: ${account_move_out}"
echo "time_move_out: ${time_move_out}"
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
echo ""
echo "java6: ${java6}"
echo "java7: ${java7}"
echo "java8: ${java8}"
echo ""   
echo "fastqc: ${fastqc}"
echo ""
echo "cutadapt: ${cutadapt}"
echo "cutadapt_min_len: ${cutadapt_min_len}"
echo "cutadapt_adapter_1: ${cutadapt_adapter_1}"
echo "cutadapt_adapter_2: ${cutadapt_adapter_2}"
echo ""
echo "bwa: ${bwa}"
echo "bwa_index: ${bwa_index}"
echo ""   
echo "samtools: ${samtools}"
echo "samtools_folder: ${samtools_folder}"
echo ""
echo "picard: ${picard}"
echo ""
echo "r_folder: ${r_folder}"
echo ""
echo "qualimap: ${qualimap}"
echo ""
echo "gnuplot: ${gnuplot}"
echo "LiberationSansRegularTTF: ${LiberationSansRegularTTF}"
echo ""
echo "samstat: ${samstat}"
echo ""
echo "rsync: ${rsync}"
echo ""
echo "Resources" 
echo "---------"
echo ""
echo "resources_folder: ${resources_folder}"
echo ""
echo "ref_genome: ${ref_genome}"
echo ""
echo "hs_metrics_probes_name: ${hs_metrics_probes_name}"
echo "nextera_probes_intervals: ${nextera_probes_intervals}"
echo "nextera_targets_intervals: ${nextera_targets_intervals}"
echo "nextera_targets_bed_3: ${nextera_targets_bed_3}"
echo "nextera_targets_bed_6: ${nextera_targets_bed_6}"
echo ""
echo "Working folders"
echo "---------------"
echo ""
echo "logs_folder: ${logs_folder}"
echo "source_fastq_folder: ${source_fastq_folder}"
echo "renamed_fastq_folder: ${renamed_fastq_folder}"
echo "fastqc_raw_folder: ${fastqc_raw_folder}"
echo "trimmed_fastq_folder: ${trimmed_fastq_folder}"
echo "fastqc_trimmed_folder: ${fastqc_trimmed_folder}"
echo "bam_folder: ${bam_folder}"
echo "flagstat_folder: ${flagstat_folder}"
echo "picard_mkdup_folder: ${picard_mkdup_folder}"
echo "picard_inserts_folder: ${picard_inserts_folder}"
echo "picard_alignment_folder: ${picard_alignment_folder}"
echo "picard_hybridisation_folder: ${picard_hybridisation_folder}"
echo "picard_summary_folder: ${picard_summary_folder}"
echo "qualimap_results_folder: ${qualimap_results_folder}"
echo "samstat_results_folder: ${samstat_results_folder}"
echo "" 
echo "Additional parameters"
echo "---------------------"
echo ""
echo "platform: ${platform}"
echo "" 
