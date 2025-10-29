# SCRATCH-QC Subworkflows

## Introduction
This repository contains three Nextflow subworkflows for alignment (GEX and TCR), quality control (sample and cell filtering) and clustering analysis in single-cell RNA sequencing (scRNA-seq) data. The subworkflows are designed to handle and analyze provided input files, ensuring reproducibility and scalability.

> **Disclaimer:** Subworkflows are chained modules providing a high-level functionality (e.g., Alignment, QC, Differential expression) within a pipeline context. These subworkflows should ideally be bundled with the pipeline implementation and shared among different pipelines as needed.

## Prerequisites
Before running any of the subworkflows, ensure you have the following installed:
- [Nextflow](https://www.nextflow.io/) (version 21.04.0 or higher)
- [Java](https://www.oracle.com/java/technologies/javase-downloads.html) (version 8 or higher)
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/) for containerized execution
- [Git](https://git-scm.com/)

## Installation
Clone the repository to your local machine:
```bash
git clone https://github.com/WangLab-ComputationalBiology/SCRATCH-QC.git
cd SCRATCH-QC
```

## Subworkflows

### 1. `scratch_align_entry.nf`
This subworkflow runs the alignment process for scRNA-seq data.

#### Usage
```bash
nextflow run scratch_align_entry.nf -profile [docker/singularity] --samplesheet <path/to/samplesheet> --modality <GEX|TCR|GEX+TCR> --genome <GRCh38|GRCm39>
```

#### Parameters
- `--samplesheet`: Path to the samplesheet file (default: `assets/test_sample_table.csv`).
- `--modality`: Modality type, either GEX, TCR, or GEX+TCR (default: `GEX`).
- `--genome`: Genome reference, either GRCh38 or GRCm39 (default: `GRCh38`).

### Example
```bash
nextflow run scratch_align_entry.nf -profile docker --samplesheet data/samplesheet.csv --modality GEX --genome GRCh38
```

### 2. `scratch_qc_entry.nf`
This subworkflow performs QC checks on the GEX matrices.

#### Usage
```bash
nextflow run scratch_qc_entry.nf -profile [docker/singularity] --input_gex_matrices_path <path/to/gex_matrices> --input_exp_table <path/to/exp_table>
```

#### Parameters
- `--input_gex_matrices_path`: Path to the GEX matrices (default: `data/SCRATCH_ALIGN:CELLRANGER_COUNT/**/outs/*`).
- `--input_exp_table`: Path to the experiment table (default: `data/pipeline_info/samplesheet.valid.csv`).
- `--expected_cells`: Expected number of cells (default: `5000`).
- `--total_droplets`: Total number of droplets (default: `15000`).
- `--fpr`: False positive rate (default: `0.01`).
- `--epochs`: Number of epochs (default: `150`).
- `--skip_cellbender`: Skip Cellbender step (default: `true`).
- `--thr_estimate_n_cells`: Threshold for estimated number of cells (default: `300`).
- `--thr_mean_reads_per_cells`: Threshold for mean reads per cell (default: `25000`).
- `--thr_median_genes_per_cell`: Threshold for median genes per cell (default: `900`).
- `--thr_median_umi_per_cell`: Threshold for median UMI per cell (default: `1000`).
- `--thr_n_feature_rna_min`: Minimum threshold for RNA features (default: `300`).
- `--thr_n_feature_rna_max`: Maximum threshold for RNA features (default: `7500`).
- `--thr_percent_mito`: Threshold for mitochondrial gene percentage (default: `25`).
- `--thr_n_observed_cells`: Threshold for observed cells (default: `300`).
- `--skip_scdblfinder`: Skip scDblFinder step (default: `false`).
- `-profile`: Execution profile. Use `docker` or `singularity`  depending on your containerization preference. Alternatively, you can create an HPC-aware profile for your institution.

### Example
```bash
nextflow run scratch_qc_entry.nf -profile docker --input_gex_matrices_path data/gex_matrices/ --input_exp_table data/exp_table.csv
```

### 3. `scratch_cluster_entry.nf`
This subworkflow performs clustering on the merged Seurat object.

#### Usage
```bash
nextflow run scratch_cluster_entry.nf -profile [docker/singularity] --input_merged_object <path/to/seurat_object.RDS>
```

#### Parameters
- `--input_merged_object`: Path to the merged Seurat object file (default: `data/SCRATCH_QC:SEURAT_MERGE/*_merged_object.RDS`).
- `--thr_n_features`: Threshold for the number of features (default: `2000`).
- `--thr_n_dimensions`: Threshold for the number of dimensions (default: `100`).
- `--input_integration_dimension`: Integration dimension (default: `auto`).
- `--input_group_plot`: Group plot input (default: `patient_id;timepoint`).
- `--thr_resolution`: Clustering resolution threshold (default: `0.5`).
- `--thr_proportion`: Clustering proportion threshold (default: `0.25`).

### Example
```bash
nextflow run scratch_cluster_entry.nf -profile docker --input_merged_object data/seurat_object.RDS
```

## Configuration
The subworkflow can be configured using the `nextflow.config` file. Modify this file to set default parameters, profiles, and other settings. An institution profile should be created whenever running the pipeline in an HPC environment, please refer to [Step-by-step guide to writing an institutional profile](https://nf-co.re/docs/tutorials/use_nf-core_pipelines/config_institutional_profile)

## Output
Upon successful completion, the results will be available in the specified output directory. You can open the reports in your browser to review the QC metrics and other outputs.

## Documentation
For more detailed documentation and advanced usage, refer to the [Nextflow documentation](https://www.nextflow.io/docs/latest/index.html) and the comments within the subworkflow scripts.

## Contributing
Contributions are welcome! Please submit a pull request or open an issue to discuss any changes.

## License
This project is available under the GNU General Public License v3.0. See the LICENSE file for more details.

## Contact
For questions or issues, please contact:
- sazaidi@mdanderson.org
- lwang22@mdanderson.org
