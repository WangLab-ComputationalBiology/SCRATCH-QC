#!/bin/bash


#BSUB -J scratch_alignNF             # Job name
###BSUB -q e40long                   # Queue name (change if needed)
#BSUB -n 20                        # Number of CPU cores
#BSUB -M 350G                      # Memory limit (64GB)
###BSUB -R "span[hosts=1]"           # Ensure all cores are on the same node
#BSUB -o nextflow_job.out          # Standard output file
#BSUB -e nextflow_job.err          # Standard error file
#BSUB -cwd /home/sazaidi/Softwares/SCRATCH-QC-main  # Set working directory

# Load necessary modules (modify based on your system)
module load nextflow
# module load singularity  # If using Singularity
module load cellranger/8.0.0   # If CellRanger is a module
module load python
module load R


cd /rsrch8/home/genomic_med/sazaidi/Softwares/SCRATCH-QC-main

  
# nextflow run scratch_align_entry.nf \
# --profile singularity \
# --samplesheet /home/sazaidi/YD_to_SZ/Imunon_raw_data/samples.csv \
# --modality GEX \
# --genome GRCh38 \
# -resume

nextflow run scratch_align_entry.nf 
--profile singularity 
--samplesheet /home/sazaidi/YD_to_SZ/Zhang_subset_Scratch/samples.csv 
--modality GEX+TCR 
--genome GRCh38
-o ${PWD}/zhang2/



# nextflow run scratch_qc_entry.nf \
# -profile singularity \
# --input_exp_table pipeline_info/samplesheet.valid.csv \
# --input_gex_matrices_path "data/SCRATCH_ALIGN:CELLRANGER_COUNT/*/outs/*" \
# -resume
