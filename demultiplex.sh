#!/usr/bin/env bash
# Single-cell demultiplexing pipeline
# Uses cellSNP-lite + Vireo
# Processes multiple samples sequentially

set -euo pipefail

#############################################
# Configuration
#############################################

# Base directories
base_data_dir="/mnt/data1/shared/dynast_results_from_PMACS"
demux_data_dir="/mnt/data1/hongjie/project/IGVF/DataSubmission/cram/wgs/demultiplex_VCF/VillageA"
output_base="${base_data_dir}/demultiplex_results/DemultiplexBySNP_WGS_VillageA-rep1"

# Samples
sample_ids=(
    "iPSC_VillageA-rep1_day0"
    "iPSC_VillageA-rep1_day2"
    "iPSC_VillageA-rep1_day4"
    "iPSC_VillageA-rep1_day6"
    "iPSC_VillageA-rep1_day8"
    "iPSC_VillageA-rep1_day16"
)

# Shared input files
region_vcf="${demux_data_dir}/VillageA_final_filtered_demu.vcf.gz"
donor_genotypes="${demux_data_dir}/VillageA_final_filtered_demu.vcf.gz"

# Parameters
threads=22
donor_count=40
chrom_list="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,X,Y"

#############################################
# Validate shared inputs
#############################################

for file in "${region_vcf}" "${donor_genotypes}"; do
    if [[ ! -f "${file}" ]]; then
        echo "ERROR: Missing required file: ${file}" >&2
        exit 1
    fi
done

#############################################
# Main loop
#############################################

for sample_id in "${sample_ids[@]}"; do

    echo "========================================"
    echo "Processing: ${sample_id}"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"

    sample_dir="${base_data_dir}/${sample_id}"
    bam_file="${sample_dir}/Aligned.sortedByCoord.out.bam"
    bai_file="${bam_file}.bai"
    barcode_file="${sample_dir}/Solo.out/GeneFull/filtered/barcodes.tsv"

    # Validate sample-specific files
    for file in "${bam_file}" "${bai_file}" "${barcode_file}"; do
        if [[ ! -f "${file}" ]]; then
            echo "ERROR: Missing file for ${sample_id}: ${file}" >&2
            exit 1
        fi
    done

    output_dir="${output_base}/${sample_id}"
    cellsnp_output="${output_dir}/cell_data"
    vireo_output="${output_dir}/vireo"

    mkdir -p "${output_dir}"

    #############################################
    # Run cellSNP-lite
    #############################################

    cellsnp-lite \
        -s "${bam_file}" \
        -b "${barcode_file}" \
        -R "${region_vcf}" \
        -O "${cellsnp_output}" \
        --minCOUNT 20 \
        --minMAF 0.05 \
        --chrom "${chrom_list}" \
        --gzip \
        -p "${threads}"

    #############################################
    # Run Vireo
    #############################################

    vireo \
        -c "${cellsnp_output}" \
        -d "${donor_genotypes}" \
        -N "${donor_count}" \
        -o "${vireo_output}" \
        --genoTag=GT \
        --randSeed=42

    echo "Completed: ${sample_id}"
    echo

done

