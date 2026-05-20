#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SCRATCH_QC } from './subworkflow/local/scratch_qc.nf'

workflow {

    if (!params.input_gex_matrices_path) exit 1, 'Please, provide a --input_gex_matrices_path <PATH> !'
    if (!params.input_exp_table)         exit 1, 'Please, provide a --input_exp_table <PATH> !'

    log.info """\

        Parameters:

        Input:    ${params.input_gex_matrices_path}
        Metadata: ${params.input_exp_table}

    """

    ch_gex_matrices = Channel.fromPath(params.input_gex_matrices_path, checkIfExists: true)
    ch_exp_table    = Channel.fromPath(params.input_exp_table, checkIfExists: true)

    SCRATCH_QC(
        ch_gex_matrices,
        ch_exp_table
    )

}
