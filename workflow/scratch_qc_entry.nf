#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SCRATCH_QC }    from './subworkflow/local/scratch_qc.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Check mandatory parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

if (params.input_gex_matrices_path) { input_gex_matrices = file(params.input_gex_matrices_path) } else { exit 1, 'Please, provide a --input <PATH/TO/seurat_object.RDS> !' }
if (params.input_exp_table_path) { input_exp_table = file(params.input_exp_table_path) } else { exit 1, 'Please, provide a --input <PATH/TO/seurat_object.RDS> !' }


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN ALL WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SCRATCH_QC_ENTRY {

    // Description
    ch_gex_matrices = Channel.fromPath(input_gex_matrices, checkIfExists: true)
    ch_exp_table    = Channel.fromPath(input_exp_table, checkIfExists: true)

    // Description
    ch_template    = Channel.fromPath(params.template, checkIfExists: true)
    ch_page_config = Channel.fromPath(params.page_config, checkIfExists: true)
        .collect()

    // GEX+VDJ alignment
    SCRATCH_QC(
        ch_gex_matrices,
        ch_exp_table,
    )

}

// workflow SCRATCH_QC_WORKFLOW {}
// workflow SCRATCH_CLUSTERING_WORKFLOW {}

workflow.onComplete {
    log.info(
        workflow.success ? "\nDone! Open the following report in your browser -> ${launchDir}/report/index.html\n" :
        "Oops... Something went wrong"
    )
}
