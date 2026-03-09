# Single-Cell Demultiplexing Pipeline

This repository contains `demultiplex.sh`, a Bash script for demultiplexing pooled single-cell RNA-seq samples using:

- **cellSNP-lite** – SNP pileup from BAM files  
- **Vireo** – donor assignment using genotype VCF  

The script processes multiple samples sequentially and validates all required inputs before running.

---

## Workflow

For each sample:

1. Run **cellSNP-lite** to extract SNP counts from the BAM file  
2. Run **Vireo** to assign cells to donors  
3. Save outputs into structured directories  

The script exits immediately if any required file is missing (`set -euo pipefail`).

---

## Input Requirements

### Per-Sample Files

Each sample directory must contain:

```
<base_data_dir>/<sample_id>/
├── Aligned.sortedByCoord.out.bam
├── Aligned.sortedByCoord.out.bam.bai
└── Solo.out/GeneFull/filtered/barcodes.tsv
```

### Shared Files

- `VillageA_final_filtered_demu.vcf.gz`
  - Used as SNP region file (`-R`)
  - Used as donor genotype reference (`-d`)
  - Must be bgzipped and indexed (`.tbi`)

---

## Samples Processed

```
iPSC_VillageA-rep1_day0
iPSC_VillageA-rep1_day2
iPSC_VillageA-rep1_day4
iPSC_VillageA-rep1_day6
iPSC_VillageA-rep1_day8
iPSC_VillageA-rep1_day16
```

---

## Parameters

| Parameter     | Value              |
|--------------|--------------------|
| Threads      | 22                 |
| Donor count  | 40                 |
| Chromosomes  | 1–22, X, Y         |
| minCOUNT     | 20                 |
| minMAF       | 0.05               |
| Random seed  | 42                 |

---

## Output Structure

For each sample:

```
DemultiplexBySNP_WGS_VillageA-rep1/
└── <sample_id>/
    ├── cell_data/   # cellSNP-lite output
    └── vireo/       # donor assignment results
```

---

## Run the Pipeline

```bash
bash demultiplex.sh
```

---

## Software Versions

Tested with:

| Software        | Version |
|----------------|----------|
| cellSNP-lite   | 1.2.3    |
| Vireo          | 0.6.2    |


## Notes

- The same VCF file is used for SNP extraction and donor genotypes.
- Designed for pooled scRNA-seq with matched WGS genotype reference.
- Samples are processed sequentially.
