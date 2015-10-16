  #!/bin/bash

# s01_filter_with_vqsr.sh
# vqsr
# Alexey Larionov, 16Oct2015

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

# ------------------------------------------------------------ #
#                      Train vqsr snp model                    #
# ------------------------------------------------------------ #

# Note: 
# At the time of analysis there was a controvercy about what version of dbSNP should be used for this step 
# the most recent (dbSNP138) or the earlier versions (e.g. dbsnp_138.b37.excluding_sites_after_129.vcf)
# http://gatkforums.broadinstitute.org/discussion/comment/20493/#Comment_20493

# Less controversial, but yet non entirely clear was the question about target TsTv
# Theoretical TsTv value is 2
# Default recommended for the whole genome is 2.15
# Recommended for the whole exome is 3.2
# The sources for 3.2 and even 2.15 are not clear.
# Therefore, this script tests all 4 combinations: 129_215, 129_32, 138_215 and 138_32
# The other parameters were set as recommended here:
# https://www.broadinstitute.org/gatk/guide/article?id=1259

# Tranches plots were significantly different between the 4 options.  
# However, the actual VQSLod-s for given sensitivity were the same 
# (which is how it should be, because the truth training set was the same
# and the study dataset was the same...)

# Therefore, for downstream analysis I used 138_32, 
# as recommended for exomes at the time of analysis

# Calcuilations take ~ 20min per model (~1.5hr for all 4 models)

# Files and folders
vcf="${vqsr_vcf_folder}/${source_vcf%.vcf}_source_files/${source_vcf}"
dataset_name="${source_vcf%_raw.vcf}"

# --------------- 129_215 --------------- # 

# Progress report
echo "Started training vqsr snp model with dbSNP 129 & default TsTv (2.15)"
echo ""

recal_snp_129_215="${dataset_name}_129_215.vqsr.snp.recal"
tranches_snp_129_215="${dataset_name}_129_215.vqsr.snp.tranches"
plots_snp_129_215="${dataset_name}_129_215.vqsr.snp.plots.R"
log_snp_129_215="${dataset_name}_129_215_train_vqsr_snp.log"

# Train vqsr snp model
#"${java7}" -Xmx60g -jar "${gatk}" \
#  -T VariantRecalibrator \
#  -R "${ref_genome}" \
#  -L "${nextera_targets_intervals}" -ip 100 \
#  -input "${vcf}" \
#  -resource:hapmap,known=false,training=true,truth=true,prior=15.0 "${hapmap}" \
#  -resource:omni,known=false,training=true,truth=true,prior=12.0 "${omni}" \
#  -resource:1000G,known=false,training=true,truth=false,prior=10.0 "${phase1_1k_hc}" \
#  -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 "${dbsnp_138_sites129}" \
#  -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an InbreedingCoeff \
#  -recalFile "${recal_snp_129_215}" \
#  -tranchesFile "${tranches_snp_129_215}" \
#  -rscriptFile "${plots_snp_129_215}" \
#  -mode SNP \
#  -nt 14 &>  "${log_snp_129_215}"

# Progress report
echo "Completed training vqsr snp model with dbSNP 129 & default TsTv (2.15): $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --------------- 129_32 --------------- #

# Progress report
echo "Started training vqsr snp model with dbSNP 129 & TsTv 3.2"
echo ""

recal_snp_129_32="${dataset_name}_129_32.vqsr.snp.recal"
tranches_snp_129_32="${dataset_name}_129_32.vqsr.snp.tranches"
plots_snp_129_32="${dataset_name}_129_32.vqsr.snp.plots.R"
log_snp_129_32="${dataset_name}_129_32_train_vqsr_snp.log"

# Train vqsr snp model
#"${java7}" -Xmx60g -jar "${gatk}" \
#  -T VariantRecalibrator \
#  -R "${ref_genome}" \
#  -L "${nextera_targets_intervals}" -ip 100 \
#  -input "${vcf}" \
#  -resource:hapmap,known=false,training=true,truth=true,prior=15.0 "${hapmap}" \
#  -resource:omni,known=false,training=true,truth=true,prior=12.0 "${omni}" \
#  -resource:1000G,known=false,training=true,truth=false,prior=10.0 "${phase1_1k_hc}" \
#  -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 "${dbsnp_138_sites129}" \
#  -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an InbreedingCoeff \
#  -recalFile "${recal_snp_129_32}" \
#  -tranchesFile "${tranches_snp_129_32}" \
#  -rscriptFile "${plots_snp_129_32}" \
#  --target_titv 3.2 \
#  -mode SNP \
#  -nt 14 &>  "${log_snp_129_32}"

# Progress report
echo "Completed training vqsr snp model with dbSNP 129 & TsTv 3.2: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --------------- 138_215 --------------- #

# Progress report
echo "Started training vqsr snp model with the latest dbSNP (138) & default TsTv (2.15)"
echo ""

# Files and folders
recal_snp_138_215="${dataset_name}_138_215.vqsr.snp.recal"
tranches_snp_138_215="${dataset_name}_138_215.vqsr.snp.tranches"
plots_snp_138_215="${dataset_name}_138_215.vqsr.snp.plots.R"
log_snp_138_215="${dataset_name}_138_215_train_vqsr_snp.log"

# Train vqsr snp model
#"${java7}" -Xmx60g -jar "${gatk}" \
#  -T VariantRecalibrator \
#  -R "${ref_genome}" \
#  -L "${nextera_targets_intervals}" -ip 100 \
#  -input "${vcf}" \
#  -resource:hapmap,known=false,training=true,truth=true,prior=15.0 "${hapmap}" \
#  -resource:omni,known=false,training=true,truth=true,prior=12.0 "${omni}" \
#  -resource:1000G,known=false,training=true,truth=false,prior=10.0 "${phase1_1k_hc}" \
#  -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 "${dbsnp_138}" \
#  -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an InbreedingCoeff \
#  -recalFile "${recal_snp_138_215}" \
#  -tranchesFile "${tranches_snp_138_215}" \
#  -rscriptFile "${plots_snp_138_215}" \
#  -mode SNP \
#  -nt 14 &>  "${log_snp_138_215}"

# Progress report
echo "Completed training vqsr snp model with the latest dbSNP (138) & default TsTv (2.15): $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --------------- 138_32 --------------- #

# Progress report
echo "Started training vqsr snp model with the latest dbSNP (138) & TsTv 3.2"
echo ""

# Files and folders
recal_snp_138_32="${dataset_name}_138_32.vqsr.snp.recal"
tranches_snp_138_32="${dataset_name}_138_32.vqsr.snp.tranches"
plots_snp_138_32="${dataset_name}_138_32.vqsr.snp.plots.R"
log_snp_138_32="${dataset_name}_138_32_train_vqsr_snp.log"

# Train vqsr snp model
#"${java7}" -Xmx60g -jar "${gatk}" \
#  -T VariantRecalibrator \
#  -R "${ref_genome}" \
#  -L "${nextera_targets_intervals}" -ip 100 \
#  -input "${vcf}" \
#  -resource:hapmap,known=false,training=true,truth=true,prior=15.0 "${hapmap}" \
#  -resource:omni,known=false,training=true,truth=true,prior=12.0 "${omni}" \
#  -resource:1000G,known=false,training=true,truth=false,prior=10.0 "${phase1_1k_hc}" \
#  -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 "${dbsnp_138}" \
#  -an QD -an MQ -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an InbreedingCoeff \
#  -recalFile "${recal_snp_138_32}" \
#  -tranchesFile "${tranches_snp_138_32}" \
#  -rscriptFile "${plots_snp_138_32}" \
#  --target_titv 3.2 \
#  -mode SNP \
#  -nt 14 &>  "${log_snp_138_32}"

# Progress report
echo "Completed training vqsr snp model with dbSNP 138 & TsTv 3.2: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# ------------------------------------------------------------ #
#                      Apply vqsr snp model                    #
# ------------------------------------------------------------ #

# Note: 
# 99% looked reasonable and was in agreementy with typical Broad's recommendations
# Takes ~30min

# Progress report
echo "Started applying vqsr snp model with the latest dbSNP (138), TsTv 3.2 & Ts 99%"
echo ""

# Files and folders
vqsr_snp_vcf="${dataset_name}.vqsr.snp.vcf"
log_file="${dataset_name}_apply_vqsr_snp.log"

# Apply vqsr snp model
#"${java7}" -Xmx60g -jar "${gatk}" \
#  -T ApplyRecalibration \
#  -R "${ref_genome}" \
#  -L "${nextera_targets_intervals}" -ip 100 \
#  -input "${vcf}" \
#  -recalFile "${recal_snp_138_32}" \
#  -tranchesFile "${tranches_snp_138_32}" \
#  -o "${vqsr_snp_vcf}" \
#  -mode SNP \
#  --ts_filter_level 99.0 \
#  -nt 14 &>  "${log_file}"  

# --excludeFiltered \ removes variants failed filters

# Progress report
echo "Completed applying vqsr snp model with dbSNP 138, TsTv 3.2 & Ts 99%: $(date +%d%b%Y_%H:%M:%S)"
echo ""

###################################################################################
exit
###################################################################################

# sensitivity 99% looked reasonambe

# Make md5 file
md5sum "${filtered_vcf}" "${filtered_vcf}.idx" > "${filtered_vcf_md5}"

# Remove source files from cluster
rm -fr "${raw_vcf%.vcf}_source_files"

# --- Calculate vcf stats after filtering --- #

# Progress report
echo "Calculating filtered vcf stats and making plots"
echo ""

# File names
vcf_stats="${filtered_vcf%.vcf}.vchk"

# Calculate vcf stats
"${bcftools}" stats -d 0,25000,500 -F "${ref_genome}" "${filtered_vcf}" > "${vcf_stats}" 

# Plot the stats
"${plot_vcfstats}" "${vcf_stats}" -p "${vcf_plots_folder}/"
echo ""

# Completion message to log
echo "Completed: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# --- Copy output back to NAS --- #

# Progress report
echo "Started copying results to NAS"
echo ""

# Copy files to NAS
rsync -thrqe "ssh -x" "${filtered_vcf_folder}" "${data_server}:${project_location}/${project}/" 

# Change ownership on nas (to allow user manipulating files later w/o administrative privileges)
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}/${project}/qual_filtered_vcf"
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}/${project}" # just in case...
ssh -x "${data_server}" "chown -R ${mgqnap_user}:${mgqnap_group} ${project_location}" # just in case...

# Progress report
timestamp="$(date +%d%b%Y_%H:%M:%S)"
ssh -x "${data_server}" "echo \"Completed copying results to NAS: ${timestamp}\" >> ${project_location}/${project}/qual_filtered_vcf/${raw_vcf%_raw.vcf}_qual${qual_threshold}.log"
ssh -x "${data_server}" "echo \"\" >> ${project_location}/${project}/qual_filtered_vcf/${raw_vcf%_raw.vcf}_qual${qual_threshold}.log"

# Return to the initial folder
cd "${init_dir}"

# Remove results from cluster
if [ "${remove_project_folder}" == "yes" ] || [ "${remove_project_folder}" == "Yes" ] 
then 
  rm -fr "${project_folder}"
  ssh -x "${data_server}" "echo \"Working folder is removed from cluster\" >> ${project_location}/${project}/qual_filtered_vcf/${raw_vcf%_raw.vcf}_qual${qual_threshold}.log"
else
  ssh -x "${data_server}" "echo \"Working folder is not removed from cluster\" >> ${project_location}/${project}/qual_filtered_vcf/${raw_vcf%_raw.vcf}_qual${qual_threshold}.log"
fi 

