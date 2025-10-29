#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SCRATCH_QC }    from './subworkflow/local/scratch_qc.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Check mandatory parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

if (params.input_gex_matrices_path) { input_gex_matrices = file(params.input_gex_matrices_path) } else { exit 1, 'Please, provide a --input <PATH/TO/seurat_object.RDS> !' }
if (params.input_exp_table) { input_exp_table = file(params.input_exp_table) } else { exit 1, 'Please, provide a --input <PATH/TO/seurat_object.RDS> !' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN ALL WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    log.info """\

        Parameters:

        Input: ${input_gex_matrices}
        Metadata: ${input_exp_table}

    """

    // Description
    ch_gex_matrices = Channel.fromPath(params.input_gex_matrices_path, checkIfExists: true)
    ch_exp_table    = Channel.fromPath(params.input_exp_table, checkIfExists: true)

    // Filtering sample and cells
    SCRATCH_QC(
        ch_gex_matrices,
        ch_exp_table
    )

}

workflow.onComplete {
    log.info(
        workflow.success ? "\nDone! Open the following report in your browser -> ${launchDir}/report/index.html\n" :
        "Oops... Something went wrong"
    )
}