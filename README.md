# single cell demultiplexing pipeline

This Bash script automates demultiplexing of WGS data for multiple samples using **cellSNP-lite** and **vireo**.  
It validates inputs, processes each sample, and organizes outputs systematically.

---

## Script Overview

```bash
#!/bin/bash
set -euo pipefail

#############################################
# Configuration
#############################################

# Base directories
base_data_dir="/mnt/data1/shared/dynast_results_from_PMACS"
demux_data_dir="/mnt/data1/hongjie/project/IGVF/DataSubmission/cram/wgs/demultiplex_VCF/VillageA"
output_base="${base_data_dir}/demultiplex_results/DemultiplexBySNP_WGS_VillageA-rep1"

# List of samples
sample_ids=(
    "iPSC_VillageA-rep1_day0"
    "iPSC_VillageA-rep1_day2"
    "iPSC_VillageA-rep1_day4"
    "iPSC_VillageA-rep1_day6"
    "iPSC_VillageA-rep1_day8"
    "iPSC_VillageA-rep1_day16"
)

# Common input files
region_vcf="${demux_data_dir}/VillageA_final_filtered_demu.vcf.gz"
donor_genotypes="${demux_data_dir}/VillageA_final_filtered_demu.vcf.gz"

# Processing parameters
threads=22
donor_count=40

#############################################
# Validate common inputs
#############################################
for required_file in "${region_vcf}" "${donor_genotypes}"; do
    if [[ ! -f "${required_file}" ]]; then
        echo "ERROR: Missing required file: ${required_file}" >&2
        exit 1
    fi
done

#############################################
# Main loop
#############################################
for sample_id in "${sample_ids[@]}"; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Processing sample: ${sample_id}"
    echo "========================================"

    sample_dir="${base_data_dir}/${sample_id}"
    bam_file="${sample_dir}/Aligned.sortedByCoord.out.bam"
    bai_file="${sample_dir}/Aligned.sortedByCoord.out.bam.bai"
    barcode_file="${sample_dir}/Solo.out/GeneFull/filtered/barcodes.tsv"

    # Validate sample files
    for required_file in "${bam_file}" "${bai_file}" "${barcode_file}"; do
        if [[ ! -f "${required_file}" ]]; then
            echo "ERROR: Missing file for ${sample_id}: ${required_file}" >&2
            exit 1
        fi
    done

    # Create output directories
    output_dir="${output_base}/${sample_id}"
    mkdir -p "${output_dir}"

    #############################################
    # Step 1: Detect chromosomes automatically
    #############################################
    chrom_list="1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,X,Y"
    echo "Detected chromosomes: ${chrom_list}"

    #############################################
    # Step 2: Run cellSNP-lite
    #############################################
    cellsnp_output="${output_dir}/cell_data"
    echo "Running cellSNP-lite..."
    cellsnp-lite \
        -s "${bam_file}" \
        -b "${barcode_file}" \
        -R "${region_vcf}" \
        -O "${cellsnp_output}" \
        --minCOUNT 20 \
        --chrom "${chrom_list}" \
        --gzip \
        --minMAF 0.05 \
        -p ${threads}

    #############################################
    # Step 3: Run vireo
    #############################################
    vireo_output="${output_dir}/vireo"
    echo "Running vireo..."
    vireo \
        -c "${cellsnp_output}" \
        -d "${donor_genotypes}" \
        -N ${donor_count} \
        -o "${vireo_output}" \
        --genoTag=GT \
        --randSeed=42

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Completed processing for ${sample_id}"
    echo "Outputs stored in: ${output_dir}"
    echo "========================================"
    echo
done

echo "All samples processed successfully!"

