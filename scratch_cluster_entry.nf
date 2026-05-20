#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SCRATCH_CLUSTERING } from './subworkflow/local/scratch_cluster.nf'

workflow {

    if (!params.input_merged_object) exit 1, 'Please, provide a --input_merged_object <PATH> !'

    log.info """\

        Parameters:

        Input: ${params.input_merged_object}

    """

    ch_seurat_object = Channel.fromPath(params.input_merged_object, checkIfExists: true)

    SCRATCH_CLUSTERING(
        ch_seurat_object
    )

}
