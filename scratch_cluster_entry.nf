#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SCRATCH_CLUSTERING } from './subworkflow/local/scratch_cluster.nf'

workflow {

    if (!params.input_merged_object) exit 1, 'Please, provide a --input_merged_object <PATH> !'

    log.info """\

        Parameters:

        Input: ${params.input_merged_object}

    """

    // The merged object is BPCells-backed: its counts live in an on-disk store
    // (data/bpcells_counts) published next to the RDS. Pass both downstream so
    // the on-disk references resolve.
    ch_seurat_object = Channel.fromPath(params.input_merged_object, checkIfExists: true)
        .map { rds -> tuple(rds, file("${rds.parent}/bpcells_counts", checkIfExists: true)) }

    SCRATCH_CLUSTERING(
        ch_seurat_object
    )

}
