# SCRATCH-QC

## Introduction

SCRATCH-QC is a Nextflow DSL2 pipeline for single-cell RNA-seq alignment, quality control, and clustering. It supports three alignment modes covering the full range of library preparation strategies:

| Mode | `--multi` | `--demux` | When to use |
|------|-----------|-----------|-------------|
| **Standard** | `false` | `false` | Pre-demultiplexed FASTQs — one row per sample |
| **Demux** | `false` | `true` | Pooled FASTQs with auto barcode detection from I1 index |
| **Multi** | `true` | `false` | Hashtag-multiplexed libraries — runs `cellranger multi` with native CITE-seq demultiplexing (JIBES) |

> **Disclaimer:** Subworkflows are chained modules providing high-level functionality (Alignment, QC, Clustering) within a pipeline context. They are designed to be shared and reused across projects.

---

## Prerequisites

- [Nextflow](https://www.nextflow.io/) ≥ 21.04.0
- Java ≥ 8
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/) for containerised execution
- [Cell Ranger](https://support.10xgenomics.com/single-cell-gene-expression/software/overview/welcome) ≥ 7.0 (inside container)
- [Git](https://git-scm.com/)

## Installation

```bash
git clone https://github.com/WangLab-ComputationalBiology/SCRATCH-QC.git
cd SCRATCH-QC
```

---

## Alignment — `scratch_align_entry.nf`

Runs alignment (and demultiplexing where applicable) and emits per-sample feature–barcode matrices for downstream QC.

### Mode 1 — Standard (pre-demultiplexed FASTQs)

One row per sample. The pipeline groups lanes by sample name and runs `cellranger count` (GEX) or `cellranger vdj` (TCR).

**Samplesheet columns:** `sample, fastq_1, fastq_2, modality`

```
sample,fastq_1,fastq_2,modality
PATIENT01,/data/fastq/P01_R1.fastq.gz,/data/fastq/P01_R2.fastq.gz,GEX
PATIENT02,/data/fastq/P02_R1.fastq.gz,/data/fastq/P02_R2.fastq.gz,GEX
PATIENT03,/data/fastq/P03_R1.fastq.gz,/data/fastq/P03_R2.fastq.gz,TCR
```

**Command:**
```bash
nextflow run scratch_align_entry.nf \
  -profile singularity \
  --samplesheet assets/test_sample_table.csv \
  --modality GEX \
  --genome GRCh38
```

---

### Mode 2 — Demux (auto barcode detection from I1 index)

Accepts raw pooled FASTQs exactly as delivered by the sequencing core. The pipeline scans the I1 index reads, detects sample barcodes above a minimum frequency, auto-names samples, and demultiplexes R1/R2 into per-sample FASTQs before alignment. No prior knowledge of index sequences or sample names is required.

**Samplesheet columns:** `run_id, r1, r2, i1, i2, modality`

| Column | Required | Description |
|--------|----------|-------------|
| `run_id` | Yes | Label for this sequencing run — embedded in auto-generated sample names |
| `r1` | Yes | Pooled R1 FASTQ (all samples mixed) |
| `r2` | Yes | Pooled R2 FASTQ (all samples mixed) |
| `i1` | Yes | I1 index FASTQ — used for barcode detection and assignment |
| `i2` | No | I2 index FASTQ for dual-indexed runs; leave blank for single-index |
| `modality` | Yes | `GEX` or `TCR` |

One row per sequencing run. For GEX and TCR run separately, add one row each.

```
run_id,r1,r2,i1,i2,modality
GEX_Run240101,/data/Undetermined_R1.fastq.gz,/data/Undetermined_R2.fastq.gz,/data/Undetermined_I1.fastq.gz,/data/Undetermined_I2.fastq.gz,GEX
TCR_Run240101,/data/TCR_R1.fastq.gz,/data/TCR_R2.fastq.gz,/data/TCR_I1.fastq.gz,,TCR
```

Auto-generated sample names follow the pattern `<run_id>_S01_<barcode>`. Output FASTQs are named in cellranger format (`<sample>_S1_L001_R1_001.fastq.gz`).

**Command:**
```bash
nextflow run scratch_align_entry.nf \
  -profile singularity \
  --samplesheet assets/test_demux_sample_table.csv \
  --modality GEX \
  --genome GRCh38 \
  --demux true
```

**Tuning parameters:**

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--demux_n_detect` | `50000` | Reads sampled from I1 for barcode detection |
| `--demux_min_freq` | `0.01` | Min fraction of sampled reads to call a barcode as a real sample |
| `--demux_mismatches` | `1` | Mismatches tolerated when assigning reads to a detected barcode |

---

### Mode 3 — Multi (hashtag-multiplexed CITE-seq, native demultiplexing)

For libraries prepared with cell hashing (e.g., TotalSeq ATP1B3 hashtags). Each row in the samplesheet points to a `cellranger multi` CSV config file that declares the GEX library, the Multiplexing Capture (hashtag) library, and the per-sample hashtag assignments. Cell Ranger runs its native JIBES algorithm to demultiplex samples and emits per-sample filtered matrices under `<run_id>/outs/per_sample_outs/`.

**Samplesheet columns:** `sample_id, multi_config`

| Column | Description |
|--------|-------------|
| `sample_id` | Unique label for this pooled run (used as the `--id` argument to `cellranger multi`) |
| `multi_config` | Absolute path to the `cellranger multi` CSV config file |

```
sample_id,multi_config
GBM_DFCI1_CSF_20260520,/path/to/assets/cellranger_multi_config_DFCI1.csv
GBM_DFCI2_CSF_20260520,/path/to/assets/cellranger_multi_config_DFCI2.csv
```

An example samplesheet is at `assets/test_multi_sample_table.csv`.

**`cellranger multi` config file format:**

Each config CSV has four sections:

```ini
[gene-expression]
reference,/path/to/refdata-gex-GRCh38-2024-A
check-library-compatibility,false
create-bam,true

[feature]
reference,/path/to/feature_reference_multi_DFCI1.csv

[libraries]
fastq_id,fastqs,feature_types
GBM-DFCI1-S1to5-CSF-CELLS-1_IGO_15328_C_1,/path/to/Demux_Data,Gene Expression
GBM-DFCI1-S1to5-CSF-CELLS-1_FB_IGO_15328_D_1,/path/to/Demux_Data/CITE,Multiplexing Capture

[samples]
sample_id,cmo_ids
GBM1_DFCI1_S1_CSF,C0251
GBM1_DFCI1_S2_CSF,C0252
GBM1_DFCI1_S3_CSF,C0253
GBM1_DFCI1_S4_CSF,C0254
GBM1_DFCI1_S5_CSF,C0255
```

> **Important:** Hashtag features must be declared as `Multiplexing Capture` in the feature reference (not `Antibody Capture`). This triggers the JIBES native demultiplexer.

**Feature reference format:**

```
id,name,read,pattern,sequence,feature_type
C0251,TotalSeq-C0251,R2,5PNNNNNNNNNN(BC)NNNNNNNNN,GTCAACTCTTTAGCG,Multiplexing Capture
C0252,TotalSeq-C0252,R2,5PNNNNNNNNNN(BC)NNNNNNNNN,TGATGGCCTATTGGG,Multiplexing Capture
...
CD3,CD3,R2,5PNNNNNNNNNN(BC)NNNNNNNNN,<sequence>,Antibody Capture
```

**Command:**
```bash
nextflow run scratch_align_entry.nf \
  -profile singularity \
  --samplesheet assets/test_multi_sample_table.csv \
  --genome GRCh38 \
  --multi true
```

> `--modality` is not required (or used) in multi mode — library types are declared inside the config CSV.

**Internal flow (multi mode):**
```
test_multi_sample_table.csv
        │
        ▼  (one row per cohort)
CELLRANGER_MULTI  ─────────────────────────────────────────┐
  cellranger multi --id=<sample_id> --csv=<multi_config>   │
        │                                                   │
        ▼                                                   │
<sample_id>/outs/per_sample_outs/                          │
  ├── GBM1_DFCI1_S1_CSF/count/sample_filtered_feature_bc_matrix/
  ├── GBM1_DFCI1_S2_CSF/count/sample_filtered_feature_bc_matrix/
  └── ...                                                  │
        │  (flatMap → one channel element per sample)       │
        ▼                                                   │
  Downstream QC (same as Standard/Demux modes) ◄───────────┘
```

---

### Alignment parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--samplesheet` | `assets/test_demux_sample_table.csv` | Path to samplesheet CSV |
| `--genome` | `GRCh38` | `GRCh38` or `GRCm39` |
| `--modality` | `GEX` | `GEX`, `TCR`, or `GEX+TCR` (not used in multi mode) |
| `--multi` | `false` | `true` = hashtag-multiplexed mode (cellranger multi) |
| `--demux` | `false` | `true` = auto-detect samples from I1 index |

---

## QC — `scratch_qc_entry.nf`

Performs per-sample quality control using Seurat, optional ambient RNA removal (CellBender), and doublet detection (scDblFinder). Generates HTML QC reports.

### Usage

```bash
nextflow run scratch_qc_entry.nf \
  -profile singularity \
  --input_gex_matrices_path "data/SCRATCH_ALIGN:CELLRANGER_COUNT/*/outs/*" \
  --input_exp_table data/pipeline_info/samplesheet.valid.csv
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input_gex_matrices_path` | `data/SCRATCH_ALIGN:CELLRANGER_COUNT/*/outs/*` | Glob path to cellranger output directories |
| `--input_exp_table` | `data/pipeline_info/samplesheet.valid.csv` | Validated samplesheet from alignment step |
| `--skip_cellbender` | `true` | Skip ambient RNA removal |
| `--expected_cells` | `5000` | Expected cells (CellBender) |
| `--total_droplets` | `15000` | Total droplets to consider (CellBender) |
| `--fpr` | `0.01` | False positive rate (CellBender) |
| `--epochs` | `150` | Training epochs (CellBender) |
| `--thr_estimate_n_cells` | `300` | Min estimated cells to pass QC |
| `--thr_mean_reads_per_cells` | `25000` | Min mean reads per cell |
| `--thr_median_genes_per_cell` | `900` | Min median genes per cell |
| `--thr_median_umi_per_cell` | `1000` | Min median UMI per cell |
| `--thr_n_feature_rna_min` | `300` | Min RNA features per cell |
| `--thr_n_feature_rna_max` | `7500` | Max RNA features per cell |
| `--thr_percent_mito` | `25` | Max mitochondrial gene % |
| `--thr_n_observed_cells` | `300` | Min observed cells after filtering |
| `--skip_scdblfinder` | `false` | Skip doublet detection |

---

## Clustering — `scratch_cluster_entry.nf`

Performs normalization, dimensionality reduction (PCA/UMAP), and Seurat clustering on the merged object output by the QC subworkflow.

### Usage

```bash
nextflow run scratch_cluster_entry.nf \
  -profile singularity \
  --input_merged_object "data/SCRATCH_QC:SEURAT_MERGE/*_merged_object.RDS"
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input_merged_object` | `data/SCRATCH_QC:SEURAT_MERGE/*_merged_object.RDS` | Path to merged Seurat RDS |
| `--thr_n_features` | `2000` | Variable features for normalization |
| `--thr_n_dimensions` | `100` | PCA dimensions to compute |
| `--input_integration_dimension` | `auto` | Integration dimension (`auto` or integer) |
| `--input_group_plot` | `patient_id;timepoint` | Metadata columns for UMAP colouring (semicolon-separated) |
| `--thr_resolution` | `0.5` | Leiden/Louvain clustering resolution |
| `--thr_proportion` | `0.25` | Minimum cluster size proportion |

---

## Full end-to-end example (multi mode)

```bash
# 1. Alignment — run cellranger multi for all cohorts, then QC-ready matrices emitted automatically
nextflow run scratch_align_entry.nf \
  -profile singularity \
  --samplesheet assets/test_multi_sample_table.csv \
  --genome GRCh38 \
  --multi true \
  --outdir results/align

# 2. Quality control
nextflow run scratch_qc_entry.nf \
  -profile singularity \
  --input_gex_matrices_path "results/align/data/SCRATCH_ALIGN:CELLRANGER_MULTI/*/outs/*" \
  --input_exp_table results/align/pipeline_info/samplesheet.valid.csv \
  --outdir results/qc

# 3. Clustering
nextflow run scratch_cluster_entry.nf \
  -profile singularity \
  --input_merged_object "results/qc/data/SCRATCH_QC:SEURAT_MERGE/*_merged_object.RDS" \
  --outdir results/cluster
```

---

## Output structure

```
results/
├── pipeline_info/
│   └── samplesheet.valid.csv
├── data/
│   ├── SCRATCH_ALIGN:CELLRANGER_MULTI/   # multi mode
│   │   └── <sample_id>/outs/
│   │       ├── per_sample_outs/<per_sample>/count/sample_filtered_feature_bc_matrix/
│   │       └── multi/
│   ├── SCRATCH_ALIGN:CELLRANGER_COUNT/   # standard / demux mode
│   ├── SCRATCH_QC:CELLBENDER/
│   ├── SCRATCH_QC:SEURAT_QUALITY/
│   ├── SCRATCH_QC:SEURAT_MERGE/
│   ├── SCRATCH_QC:SCDBLFINDER/
│   ├── SCRATCH_CLUSTER:SEURAT_NORMALIZE/
│   └── SCRATCH_CLUSTER:SEURAT_CLUSTER/
└── report/
    ├── quality_report.html
    ├── merge_report.html
    ├── doublet_report.html
    ├── normalization_report.html
    └── clustering_report.html
```

---

## HPC configuration

For HPC clusters (LSF, SLURM, etc.), create an institution profile in `conf/institution.config` and add it to the `profiles` block in `nextflow.config`. Refer to the [nf-core institutional profile guide](https://nf-co.re/docs/tutorials/use_nf-core_pipelines/config_institutional_profile).

A `seadragon` profile is included for MD Anderson's LSF cluster:
```bash
nextflow run scratch_align_entry.nf -profile singularity,seadragon ...
```

---

## Configuration

All defaults are in `nextflow.config`. Override any parameter on the command line with `--param value` or by providing a custom config with `-c my.config`.

---

## Contributing

Pull requests and issues are welcome.

## License

GNU General Public License v3.0 — see LICENSE for details.

## Contact

- sazaidi@mdanderson.org
- lwang22@mdanderson.org
