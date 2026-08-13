//
// Description
//

include { SEURAT_QUALITY            } from '../../modules/local/seurat/quality/main.nf'
include { CELLBENDER                } from '../../modules/local/cellbender/main.nf'
include { HELPER_SUMMARIZE          } from '../../modules/local/helper/summarize/main.nf'
include { SEURAT_MERGE              } from '../../modules/local/seurat/merge/main.nf'
include { SCDBLFINDER               } from '../../modules/local/scdblfinder/main.nf'
include { EXPORT_H5AD as EXPORT_H5AD_MERGED  } from '../../modules/local/export_h5ad/main.nf'
include { EXPORT_H5AD as EXPORT_H5AD_SINGLET } from '../../modules/local/export_h5ad/main.nf'

workflow SCRATCH_QC {

    take:
        ch_cell_matrices // channel: [ val(sample), path(metrics_csv), path(h5) ]
        ch_exp_table     // channel: path to samplesheet with metadata columns

    main:
        
        // Channel definitions
        ch_versions  = Channel.empty()

        // Importing notebook
        ch_notebook_quality       = Channel.fromPath(params.notebook_quality, checkIfExists: true)
        ch_notebook_summarize     = Channel.fromPath(params.notebook_summarize, checkIfExists: true)
        ch_notebook_merge         = Channel.fromPath(params.notebook_merge, checkIfExists: true)
        ch_notebook_scdblfinder   = Channel.fromPath(params.notebook_scdblfinder, checkIfExists: true)

        // Quarto settings
        ch_template    = Channel.fromPath(params.template, checkIfExists: true)
            .collect()

        ch_page_config = Channel.fromPath(params.page_config, checkIfExists: true)
            .collect()

        ch_page_config = ch_template
            .map{ file -> file.find { it.toString().endsWith('.png') } }
            .combine(ch_page_config)
            .collect()

        // Matrices arrive pre-resolved from the samplesheet as
        // [ sample, metrics_csv, h5 ] — one row per sample, across all datasets.
        ch_cell_matrices
            .view()

        // Removing RNA ambient and artifacts
        if(!params.skip_cellbender) {

            ch_cell_matrices = CELLBENDER(
                ch_cell_matrices
            )

        }

        // Standard filtering
        SEURAT_QUALITY(
            ch_cell_matrices,
            ch_notebook_quality.collect(),
            ch_page_config
        )

        // Writing QC check
        ch_quality_report = SEURAT_QUALITY.out.metrics
            .collect()
        
        // Generating QC table
        HELPER_SUMMARIZE(
            ch_quality_report,
            ch_notebook_summarize,
            ch_page_config
        )

        // Keep QC-passing samples for merging: SUCCESS and FIXABLE. FIXABLE
        // samples are borderline but retained so they can be reviewed (and
        // dropped later if desired); they stay flagged in the QC report. Only
        // FAILURE samples are excluded from the merge.
        ch_qc_approved = SEURAT_QUALITY.out.status
            .filter{sample, object, status ->
                def log_name = status.toString()
                log_name.endsWith('SUCCESS.txt') || log_name.endsWith('FIXABLE.txt')
            }
            .map{sample, object, status -> object}
            .collect()

        ch_qc_approved
            .ifEmpty{error 'No samples matched QC expectations.'}
            .view{'Done'}

        // Merging all Seurat objects into a single-object
        SEURAT_MERGE(
            ch_qc_approved,
            ch_notebook_merge,
            ch_exp_table,
            ch_page_config
        )

        ch_merge_object = SEURAT_MERGE.out.seurat_rds

        // Portable, self-contained .h5ad of the merged object (streamed from the
        // BPCells store, so it never realizes the full matrix). Opens in both R
        // (BPCells/anndata) and Python (scanpy).
        if(params.export_h5ad) {

            EXPORT_H5AD_MERGED(
                SEURAT_MERGE.out.seurat_rds
                    .combine(SEURAT_MERGE.out.bpcells_store)
                    .map{ rds, store -> tuple('merged', rds, store) }
            )

        }

        // Filtering doublets
        if(!params.skip_scdblfinder) {

            SCDBLFINDER(
                ch_merge_object,
                SEURAT_MERGE.out.bpcells_store,
                ch_notebook_scdblfinder,
                ch_page_config
            )

            // Matching .h5ad for the doublet-removed (singlet) object.
            if(params.export_h5ad) {

                EXPORT_H5AD_SINGLET(
                    SCDBLFINDER.out.seurat_rds
                        .combine(SCDBLFINDER.out.bpcells_store)
                        .map{ rds, store -> tuple('singlet', rds, store) }
                )

            }

        }

        ch_final_object = ch_merge_object

    emit:
        ch_final_object
}
