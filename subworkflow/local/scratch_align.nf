//
// Description
//

include { SAMPLESHEET_CHECK        } from '../../modules/local/helper/validate/main.nf'
include { CELLRANGER_COUNT         } from '../../modules/local/cellranger/count/main.nf'
include { CELLRANGER_VDJ           } from '../../modules/local/cellranger/vdj/main.nf'

// Importing Quarto notebooks

workflow SCRATCH_ALIGN {

    take:
        ch_sample_table // channel: [ val(sample), [ fastq ] ]
        modality        // string: GEX, TCR, or GEX+TCR
        genome          // string: genome code

    main:

        // Channel definitions
        ch_versions  = Channel.empty()

        // Quarto settings
        ch_template    = Channel.fromPath(params.template, checkIfExists: true)
            .collect()

        ch_page_config = Channel.fromPath(params.page_config, checkIfExists: true)
            .collect()

        ch_page_config = ch_template
            .map{ file -> file.find { it.toString().endsWith('.png') } }
            .combine(ch_page_config)
            .collect()

        // Sample check
        ch_sample_table = SAMPLESHEET_CHECK(ch_sample_table)
            .csv
            .splitCsv(header:true, sep:',')
            .map{ row -> tuple row.sample, row.fastq_1, row.fastq_2, row.modality }

        ch_sample_table
            .view()

        // Separeting GEX and VDJ
        ch_sample_branches = ch_sample_table
            .branch {
                gex: it[3] == 'GEX'
                tcr: it[3] == 'TCR'
            }
        
        // Printing out warnings
        ch_sample_branches.gex
            .ifEmpty { 
                println("No GEX samples were found. Skipping CELLRANGER_COUNTS process.")
            }

        ch_sample_branches.tcr
            .ifEmpty { 
                println("No TCR samples were found. Skipping CELLRANGER_VDJ process.")
            }

        if(modality =~ /\b(GEX)/) {

            // Staging Cellranger Counts indexes
            gex_indexes = params.genomes[genome].gex

            // Grouping fastq based on sample id
            ch_gex_grouped = ch_sample_branches.gex
                .map { row -> tuple row[0], row[1], row[2] }
                .groupTuple(by: [0])
                .map { row -> tuple row[0], row[1 .. 2].flatten() }

            // Cellranger gex alignment
            ch_gex_alignment = CELLRANGER_COUNT(
                ch_gex_grouped,
                gex_indexes
            ) 

            ch_cellrange_outs = ch_gex_alignment.outs

        }

        if(modality =~ /\b(TCR)/) {

            // Staging Cellranger VDJ reference
            vdj_indexes = params.genomes[genome].vdj

            // Grouping fastq based on sample id
            ch_tcr_grouped = ch_sample_branches.tcr
                .map { row -> tuple row[0], row[1], row[2] }
                .groupTuple(by: [0])
                .map { row -> tuple row[0], row[1 .. 2].flatten() }

            // Cellranger gex alignment
            ch_tcr_alignment = CELLRANGER_VDJ(
                ch_tcr_grouped,
                vdj_indexes
            )

            ch_cellrange_outs = ch_tcr_alignment.outs

        }
        

        if(modality =~ /\b(GEX+TCR)/) {

            ch_cellrange_outs = ch_gex_alignment.outs

        }

    emit:
        ch_cellrange_outs

}