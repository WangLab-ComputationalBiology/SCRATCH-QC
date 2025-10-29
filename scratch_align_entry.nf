#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SCRATCH_ALIGN } from './subworkflow/local/scratch_align.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Check mandatory parameters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

if (params.samplesheet) { samplesheet = file(params.samplesheet) } else { exit 1, 'Please, provide a --samplesheet <path/to/samplesheet> !' }
if (params.modality) { modality = params.modality } else { exit 1, 'Please, provide a --modality <GEX|TCR|GEX+TCR> !' }
if (params.genome) { genome = params.genome } else { exit 1, 'Please, provide a --genome <GRCh38|GRCm39> !' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN ALL WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    log.info """\

        Parameters:

        Input: ${samplesheet}
        Modality: ${modality}
        Genome: ${genome}

    """

    // Creating channel from samplesheet
    ch_samplesheet = Channel.fromPath(samplesheet, checkIfExists: true)

    // GEX+VDJ alignment
    SCRATCH_ALIGN(
        ch_samplesheet,
        params.modality,
        params.genome
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
