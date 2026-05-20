#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { MICROBIOME } from './subworkflows/local/microbiome.nf'

workflow {

    if (!params.input_bam_path) exit 1, 'Please, provide a --input_bam_path <PATH> !'

    log.info """\

        Parameters:

        Input BAM: ${params.input_bam_path}

    """

    ch_bam_files = Channel.fromPath(params.input_bam_path, checkIfExists: true)

    MICROBIOME(
        ch_bam_files
    )

}
