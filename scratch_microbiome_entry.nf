#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { MICROBIOME } from './subworkflows/local/microbiome.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Check mandatory parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

if (params.input_bam_path) { input_bam = file(params.input_bam_path) } else { exit 1, 'Please, provide a --input_bam <PATH/TO/BAM> !' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MICROBIOME WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    log.info """\

        Parameters:

        Input BAM: ${input_bam}

    """

    // Define input channel
    ch_bam_files = Channel.fromPath(params.input_bam_path, checkIfExists: true)

    // Run microbiome workflow
    MICROBIOME(
        ch_bam_files
    )
}

workflow.onComplete {
    log.info(
        workflow.success ? "\nDone! Microbiome analysis completed successfully. Check outputs in ${launchDir}/results/ \n" :
        "Oops... Something went wrong"
    )
}
