#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SCRATCH_CLUSTERING }    from './subworkflow/local/scratch_cluster.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Check mandatory parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

if (params.input_merged_object) { input_merged_object = file(params.input_merged_object) } else { exit 1, 'Please, provide a --input <PATH/TO/seurat_object.RDS> !' }
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN ALL WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    log.info """\

        Parameters:

        Input: ${input_merged_object}

    """

    // Description
    ch_seurat_object = Channel.fromPath(input_merged_object, checkIfExists: true)

    // Filtering sample and cells
    SCRATCH_CLUSTERING(
        ch_seurat_object
    )

}

workflow.onComplete {
    log.info(
        workflow.success ? "\nDone! Open the following report in your browser -> ${launchDir}/report/index.html\n" :
        "Oops... Something went wrong"
    )
}
