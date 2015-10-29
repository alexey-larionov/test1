#!/bin/bash

# s01_filter_with_vqsr.sh
# vqsr
# Alexey Larionov, 18Oct2015

# Read parameters
job_file="${1}"
scripts_folder="${2}"

# Update pipeline log
echo "Started s01_filter_with_vqsr: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Set parameters
source "${scripts_folder}/a02_read_config.sh"
echo "Read settings"
echo ""

# Go to working folder
init_dir="$(pwd)"
cd "${vqsr_vcf_folder}"

# --- Copy source gvcfs to cluster --- #

# Progress report
echo "Started copying source data"
echo ""

rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/raw_vcf/${source_vcf}" "${vqsr_vcf_folder}/${source_vcf%.vcf}_source_files/"
rsync -thrqe "ssh -x" "${data_server}:${project_location}/${project}/raw_vcf/${source_vcf}.idx" "${vqsr_vcf_folder}/${source_vcf%.vcf}_source_files/"

# Progress report
echo "Completed copying source data: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Train vqsr snp model --- #

# Files and folders
vcf="${vqsr_vcf_folder}/${source_vcf%.vcf}_source_files/${source_vcf}"
dataset_name="${source_vcf%_raw.vcf}"

# Progress report
echo "Started training vqsr snp model"
echo ""

# File names
recal_snp="${dataset_name}_snp.recal"
tranches_snp="${dataset_name}_snp.tranches"
plots_snp="${dataset_name}_snp_plots.R"
log_train_snp="${dataset_name}_snp_train.log"

# Train vqsr snp model
"${java7}" -Xmx60g -jar "${gatk}" \
  -T VariantRecalibrator \
  -R "${ref_genome}" \
  -L "${nextera_targets_intervals}" -ip 100 \
  -input "${vcf}" \
  -resource:hapmap,known=false,training=true,truth=true,prior=15.0 "${hapmap}" \
  -resource:omni,known=false,training=true,truth=true,prior=12.0 "${omni}" \
  -resource:1000G,known=false,training=true,truth=false,prior=10.0 "${phase1_1k_hc}" \
  -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 "${dbsnp_138}" \
  -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an InbreedingCoeff \
  -recalFile "${recal_snp}" \
  -tranchesFile "${tranches_snp}" \
  -rscriptFile "${plots_snp}" \
  --target_titv 3.2 \
  -mode SNP \
  -nt 14 &>  "${log_train_snp}"

# Progress report
echo "Completed training vqsr snp model: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Apply vqsr snp model --- #

# Progress report
echo "Started applying vqsr snp model"
echo ""

# File names
vqsr_snp_vcf="${dataset_name}_snp_vqsr.vcf"
log_apply_snp="${dataset_name}_snp_apply.log"

# Apply vqsr snp model
"${java7}" -Xmx60g -jar "${gatk}" \
  -T ApplyRecalibration \
  -R "${ref_genome}" \
  -L "${nextera_targets_intervals}" -ip 100 \
  -input "${vcf}" \
  -recalFile "${recal_snp}" \
  -tranchesFile "${tranches_snp}" \
  -o "${vqsr_snp_vcf}" \
  -mode SNP \
  --ts_filter_level 99.0 \
  --excludeFiltered \
  -nt 14 &>  "${log_apply_snp}"  

# Remove source files from cluster
rm -fr "${source_vcf%.vcf}_source_files"

# Progress report
echo "Completed applying vqsr snp model"
echo ""

# --- Train vqsr indel model --- #

# Progress report
echo "Started training vqsr indel model"
echo ""

# File names
recal_indel="${dataset_name}_indel.recal"
tranches_indel="${dataset_name}_indel.tranches"
plots_indel="${dataset_name}_indel_plots.R"
log_train_indel="${dataset_name}_indel_train.log"

# Train model
"${java7}" -Xmx60g -jar "${gatk}" \
  -T VariantRecalibrator \
  -R "${ref_genome}" \
  -L "${nextera_targets_intervals}" -ip 100 \
  -input "${vqsr_snp_vcf}" \
  -resource:mills,known=false,training=true,truth=true,prior=12.0 "${mills}" \
  -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 "${dbsnp_138}" \
  -an QD -an FS -an SOR -an ReadPosRankSum -an MQRankSum -an InbreedingCoeff \
  -recalFile "${recal_indel}" \
  -tranchesFile "${tranches_indel}" \
  -rscriptFile "${plots_indel}" \
  -tranche 100.0 -tranche 99.0 -tranche 97.0 -tranche 90.0 \
  --maxGaussians 4 \
  -mode INDEL \
  -nt 14 &>  "${log_train_indel}"

# Progress report
echo "Completed training vqsr indel model (215): $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Apply vqsr indel model --- #

# Progress report
echo "Started applying vqsr indel model (Ts 95%, VQSLod ~0)"
echo ""

# Files and folders
vqsr_vcf="${dataset_name}_vqsr.vcf"
log_apply_indel="${dataset_name}_indel_apply.log"

# Apply vqsr indel model
"${java7}" -Xmx60g -jar "${gatk}" \
  -T ApplyRecalibration \
  -R "${ref_genome}" \
  -L "${nextera_targets_intervals}" -ip 100 \
  -input "${vqsr_snp_vcf}" \
  -recalFile "${recal_indel}" \
  -tranchesFile "${tranches_indel}" \
  -o "${vqsr_vcf}" \
  -mode INDEL \
  --ts_filter_level 97.0 \
  --excludeFiltered \
  -nt 14 &>  "${log_apply_indel}"  

# Progress report
echo "Completed applying vqsr indel model: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- make md5 and remove intermediste files --- #

# Make md5 file
vqsr_vcf_md5="${vqsr_vcf%.vcf}.md5"
md5sum "${vqsr_vcf}" "${vqsr_vcf}.idx" > "${vqsr_vcf_md5}"

# Remove intermediate files from cluster
rm -f "${vqsr_snp_vcf}" "${vqsr_snp_vcf}.idx"

# --- Calculate vcf stats after filtering --- #

# Progress report
echo "Started calculating vcf stats and making plots"
echo ""

# File names
vcf_stats="${vqsr_vcf%.vcf}.vchk"

# Calculate vcf stats
"${bcftools}" stats -d 0,25000,500 -F "${ref_genome}" "${vqsr_vcf}" > "${vcf_stats}" 

# Plot the stats
"${plot_vcfstats}" "${vcf_stats}" -p "${vcf_plots_folder}/"
echo ""

# Completion message to log
echo "Completed calculating vcf stats and making plots: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Copy output back to NAS --- #

# Progress report
echo "Started copying results to NAS"
echo ""

# Copy files to NAS
rsync -thrqe "ssh -x" "${vqsr_vcf_folder}" "${data_server}:${project_location}/${project}/" 

# Change ownership on nas (to allow user manipulating files later w/o administrative privileges)
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}/${project}/vqsr_vcf"
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}/${project}" # just in case...
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}" # just in case...

# Progress report
timestamp="$(date +%d%b%Y_%H:%M:%S)"
ssh -x "${data_server}" "echo \"Completed copying results to NAS: ${timestamp}\" >> ${project_location}/${project}/vqsr_vcf/${dataset_name}_vqsr.log"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/vqsr_vcf/${dataset_name}_vqsr.log"

# --- Clean up --- ~

# Remove results from cluster

rm -f "${recal_snp}"
rm -f "${recal_snp}.idx"
rm -f "${tranches_snp}"
rm -f "${tranches_snp}.pdf"
rm -f "${plots_snp}"
rm -f "${plots_snp}.pdf"
rm -f "${log_train_snp}"
rm -f "${vqsr_snp_vcf}"
rm -f "${vqsr_snp_vcf}.idx"
rm -f "${log_apply_snp}"

rm -f "${recal_indel}"
rm -f "${recal_indel}.idx"
rm -f "${tranches_indel}"
rm -f "${plots_indel}"
rm -f "${plots_indel}.pdf"
rm -f "${log_train_indel}"
rm -f "${vqsr_vcf}"
rm -f "${vqsr_vcf}.idx"
rm -f "${log_apply_indel}"

rm -f "${vqsr_vcf_md5}"
rm -f "${vcf_stats}"
rm -fr "${vcf_plots_folder}"

rm -f "${dataset_name}_vqsr.log"
rm -f "${dataset_name}_vqsr.res"

ssh -x "${data_server}" "echo \"Removed results from cluster\" >> ${project_location}/${project}/vqsr_vcf/${dataset_name}_vqsr.log"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/vqsr_vcf/${dataset_name}_vqsr.log"

# Return to the initial folder
cd "${init_dir}"

# Remove project folder from cluster
if [ "${remove_project_folder}" == "yes" ] || [ "${remove_project_folder}" == "Yes" ] 
then 
  rm -fr "${project_folder}"
  ssh -x "${data_server}" "echo \"Removed project folder from cluster\" >> ${project_location}/${project}/vqsr_vcf/${dataset_name}_vqsr.log"
else
  ssh -x "${data_server}" "echo \"Project folder is not removed from cluster\" >> ${project_location}/${project}/vqsr_vcf/${dataset_name}_vqsr.log"
fi 
