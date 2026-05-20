#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SCRATCH_ALIGN } from './subworkflow/local/scratch_align.nf'

workflow {

    if (!params.samplesheet) exit 1, 'Please, provide a --samplesheet <path/to/samplesheet> !'
    if (!params.genome)      exit 1, 'Please, provide a --genome <GRCh38|GRCm39> !'

    def demux = params.demux ?: false
    def multi = params.multi ?: false

    if (multi && demux) exit 1, '--multi and --demux cannot both be true. Choose one mode.'
    if (!multi && !params.modality) exit 1, 'Please, provide a --modality <GEX|TCR|GEX+TCR> !'

    log.info """\

        Parameters:

        Input:    ${params.samplesheet}
        Modality: ${multi ? 'N/A (cellranger multi handles libraries internally)' : params.modality}
        Genome:   ${params.genome}
        Mode:     ${multi ? 'MULTI (hashtag demultiplexing via cellranger multi)' : demux ? 'DEMUX (auto-detect from I1 index)' : 'STANDARD (pre-demultiplexed FASTQs)'}

    """

    ch_samplesheet = Channel.fromPath(params.samplesheet, checkIfExists: true)

    SCRATCH_ALIGN(
        ch_samplesheet,
        params.modality ?: 'GEX',
        params.genome,
        demux,
        multi
    )

}
