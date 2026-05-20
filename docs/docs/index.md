# SCRATCH Subworkflow

For full documentation visit [mkdocs.org](https://www.mkdocs.org).
This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report generated from the full-sized test dataset for the pipeline using a command similar to the one below:

```{bash}
nextflow run scratch --sample_table <SAMPLE> -profile test_full,<docker/singularity/institute>
```

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview
The pipeline is built using Nextflow and processes data using the following steps:

* Preprocessing
  * `Tool` - Description
  * `Tool` - Description
  * `Tool` - Description

* Quality control
  * `Tool` - Description
  * `Tool` - Description
  * `Tool` - Description
  
* Clustering
  * `Tool` - Description
  * `Tool` - Description
  * `Tool` - Description

* Annotation
  * `Tool` - Description
  * `Tool` - Description
  * `Tool` - Description

## Usage

First, prepare a samplesheet with your input data that looks as follows:

**samplesheet.csv:**

sample,fastq_1,fastq_2,strandedness
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz,auto
CONTROL_REP1,AEG588A1_S1_L003_R1_001.fastq.gz,AEG588A1_S1_L003_R2_001.fastq.gz,auto
CONTROL_REP1,AEG588A1_S1_L004_R1_001.fastq.gz,AEG588A1_S1_L004_R2_001.fastq.gz,auto

Each row represents a fastq file (single-end) or a pair of fastq files (paired end). Rows with the same sample identifier are considered technical replicates and merged automatically. The strandedness refers to the library preparation and will be automatically inferred if set to auto.

An example (samplesheet)[./assets/samplesheet.csv] has been provided with the pipeline.

## Pipeline output

## Contributions

## Citations