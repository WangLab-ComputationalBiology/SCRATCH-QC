//
// Description
//

include { EXTRACT_UNMAPPED         } from '../../modules/local/microbiome/extract_unmapped/main.nf'
include { BAM_TO_FASTQ             } from '../../modules/local/microbiome/bam_to_fastq/main.nf'
include { FILTER_HUMAN_READS       } from '../../modules/local/microbiome/filter_human_reads/main.nf'
include { CLASSIFY_MICROBIOME      } from '../../modules/local/microbiome/classify_microbiome/main.nf'
include { REFINE_CLASSIFICATION    } from '../../modules/local/microbiome/refine_classification/main.nf'
include { SPECIES_PROFILING        } from '../../modules/local/microbiome/species_profiling/main.nf'
include { LINK_MICROBES_TO_CELLS   } from '../../modules/local/microbiome/link_microbes_to_cells/main.nf'
include { GENERATE_CELL_PROFILE    } from '../../modules/local/microbiome/generate_cell_profile/main.nf'

workflow MICROBIOME {

    take:
        ch_bam_files  // Channel containing BAM files from Cell Ranger

    main:

        // Channel definitions
        ch_versions  = Channel.empty()

        // Extract unmapped reads
        ch_unmapped_bam = EXTRACT_UNMAPPED(
            ch_bam_files
        )

        // Convert BAM to FASTQ
        ch_fastq_pairs = BAM_TO_FASTQ(
            ch_unmapped_bam
        )

        // Remove human contamination
        ch_filtered_fastq = FILTER_HUMAN_READS(
            ch_fastq_pairs
        )

        // Microbiome classification with KrakenUniq
        ch_krakenuniq_report = CLASSIFY_MICROBIOME(
            ch_filtered_fastq
        )

        // Refine classification using Bracken
        ch_bracken_output = REFINE_CLASSIFICATION(
            ch_krakenuniq_report
        )

        // Species profiling with MetaPhlAn
        ch_metaphlan_output = SPECIES_PROFILING(
            ch_filtered_fastq
        )

        // Link microbial reads to single-cell barcodes
        ch_cell_barcode_counts = LINK_MICROBES_TO_CELLS(
            ch_bam_files
        )

        // Generate per-cell microbiome profiles
        ch_cell_microbiome_profile = GENERATE_CELL_PROFILE(
            ch_cell_barcode_counts
        )

    emit:
        ch_krakenuniq_report
        ch_bracken_output
        ch_metaphlan_output
        ch_cell_microbiome_profile
}
