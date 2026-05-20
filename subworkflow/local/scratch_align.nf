//
// Description
//

include { SAMPLESHEET_CHECK  } from '../../modules/local/helper/validate/main.nf'
include { AUTO_DEMUX         } from '../../modules/local/auto_demux/main.nf'
include { CELLRANGER_COUNT   } from '../../modules/local/cellranger/count/main.nf'
include { CELLRANGER_VDJ     } from '../../modules/local/cellranger/vdj/main.nf'
include { CELLRANGER_MULTI   } from '../../modules/local/cellranger/multi/main.nf'

workflow SCRATCH_ALIGN {

    take:
        ch_sample_table // channel: path to samplesheet CSV
        modality        // string:  GEX, TCR, or GEX+TCR
        genome          // string:  genome code
        demux           // boolean: true = auto-detect samples from I1/I2 and demultiplex
        multi           // boolean: true = hashtag-multiplexed, run cellranger multi

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

        // Validate samplesheet
        ch_validated_csv = SAMPLESHEET_CHECK(ch_sample_table).csv

        if (multi) {

            // ---------------------------------------------------------------
            // MULTI PATH
            //
            // Samplesheet columns: sample_id, multi_config
            //
            //   sample_id   – unique run label (e.g. GBM_DFCI1_CSF_20260520)
            //   multi_config – absolute path to cellranger multi CSV config
            //                  (contains GEX + CITE-seq library paths, hashtag
            //                   sample assignments, and genome reference)
            //
            // Cellranger multi performs native hashtag demultiplexing and emits
            // per-sample filtered matrices under:
            //   <sample_id>/outs/per_sample_outs/<per_sample_name>/count/
            //
            // These are expanded into individual per-sample channel elements
            // and fed into the same downstream QC pipeline as other modes.
            // ---------------------------------------------------------------

            ch_multi_runs = ch_validated_csv
                .splitCsv(header: true, sep: ',')
                .map { row -> tuple(row.sample_id, file(row.multi_config)) }

            ch_multi_result = CELLRANGER_MULTI(ch_multi_runs)

            // Expand per_sample_outs into one channel element per demultiplexed sample
            ch_cellrange_outs = ch_multi_result.per_sample_outs
                .flatMap { run_id, per_sample_dir ->
                    per_sample_dir.listFiles()
                        .findAll { it.isDirectory() }
                        .collect { sample_dir ->
                            tuple(sample_dir.getName(), sample_dir.listFiles().toList())
                        }
                }

        } else if (demux) {

            // ---------------------------------------------------------------
            // DEMUX PATH
            //
            // Samplesheet columns: run_id, r1, r2, i1, i2, modality
            //
            //   run_id   – label for this sequencing run (used in auto-generated
            //              sample names: <run_id>_S01_<barcode>, ...)
            //   r1 / r2  – pooled R1/R2 FASTQs containing reads from ALL samples
            //   i1       – I1 index FASTQ (used to detect and assign samples)
            //   i2       – I2 index FASTQ for dual-indexed runs; leave empty for
            //              single-index runs
            //   modality – GEX or TCR (applied to all samples in this row)
            //
            // The pipeline scans I1, identifies barcodes above --demux_min_freq,
            // auto-names samples, then demultiplexes R1/R2 into per-sample FASTQs
            // named in cellranger format: <sample>_S1_L001_R1_001.fastq.gz
            // ---------------------------------------------------------------

            ch_demux_runs = ch_validated_csv
                .splitCsv(header: true, sep: ',')
                .map { row ->
                    tuple(
                        row.run_id,
                        file(row.r1),
                        file(row.r2),
                        file(row.i1),
                        row.i2 ?: '',       // empty string when i2 column is blank
                        row.modality
                    )
                }
                // Group all lanes that share the same run_id into one AUTO_DEMUX call.
                // After groupTuple: (run_id, [r1...], [r2...], [i1...], [i2...], [mod...])
                .groupTuple(by: 0)
                .map { run_id, r1_list, r2_list, i1_list, i2_list, mod_list ->
                    // All lanes in one run share the same modality; take the first.
                    // For i2, take the first non-empty value (or '' for single-index runs).
                    def i2_val  = i2_list.find { it?.trim() } ?: ''
                    tuple(run_id, r1_list, r2_list, i1_list, i2_val, mod_list[0])
                }

            ch_demux_runs.view()

            // AUTO_DEMUX: one process call per run_id (all lanes grouped).
            // Emits: tuple(demux_dir, detected_samples_csv)
            ch_demux_result = AUTO_DEMUX(ch_demux_runs).demux_result

            // Expand one run result into N per-sample channel elements.
            // detected_samples.csv columns: sample, centroid, modality
            ch_per_sample = ch_demux_result
                .flatMap { demux_dir, manifest ->
                    manifest.readLines()
                        .drop(1)                    // skip header
                        .findAll { it.trim() }      // skip blank lines
                        .collect { line ->
                            def fields   = line.split(',')
                            def sample   = fields[0]
                            def mod      = fields[2]
                            // Resolve full paths inside the staged demux_dir
                            def r1 = demux_dir.resolve("${sample}_S1_L001_R1_001.fastq.gz")
                            def r2 = demux_dir.resolve("${sample}_S1_L001_R2_001.fastq.gz")
                            tuple(sample, [r1, r2], mod)
                        }
                }

            ch_per_sample.view()

            // Branch into GEX and TCR lanes
            ch_demux_branches = ch_per_sample
                .branch {
                    gex: it[2] == 'GEX'
                    tcr: it[2] == 'TCR'
                }

            ch_demux_branches.gex
                .ifEmpty { println("No GEX samples detected. Skipping CELLRANGER_COUNT.") }

            ch_demux_branches.tcr
                .ifEmpty { println("No TCR samples detected. Skipping CELLRANGER_VDJ.") }

            if (modality =~ /\b(GEX)/) {

                gex_indexes = params.genomes[genome].gex

                // tuple: (sample, [r1, r2], modality) → (sample, [r1, r2])
                ch_gex_for_count = ch_demux_branches.gex
                    .map { sample, reads, mod -> tuple(sample, reads) }

                ch_gex_alignment = CELLRANGER_COUNT(ch_gex_for_count, gex_indexes)
                ch_cellrange_outs = ch_gex_alignment.outs

            }

            if (modality =~ /\b(TCR)/) {

                vdj_indexes = params.genomes[genome].vdj

                ch_tcr_for_vdj = ch_demux_branches.tcr
                    .map { sample, reads, mod -> tuple(sample, reads) }

                ch_tcr_alignment = CELLRANGER_VDJ(ch_tcr_for_vdj, vdj_indexes)
                ch_cellrange_outs = ch_tcr_alignment.outs

            }

            if (modality =~ /\b(GEX\+TCR)/) {

                ch_cellrange_outs = ch_gex_alignment.outs

            }

        } else {

            // ---------------------------------------------------------------
            // STANDARD PATH
            // Samplesheet columns: sample, fastq_1, fastq_2, modality
            // Pre-demultiplexed FASTQs — one row per sample, runs cellranger count
            // ---------------------------------------------------------------

            ch_sample_table = ch_validated_csv
                .splitCsv(header: true, sep: ',')
                .map { row -> tuple row.sample, row.fastq_1, row.fastq_2, row.modality }

            ch_sample_table.view()

            // Separate GEX and VDJ
            ch_sample_branches = ch_sample_table
                .branch {
                    gex: it[3] == 'GEX'
                    tcr: it[3] == 'TCR'
                }

            ch_sample_branches.gex
                .ifEmpty { println("No GEX samples were found. Skipping CELLRANGER_COUNT process.") }

            ch_sample_branches.tcr
                .ifEmpty { println("No TCR samples were found. Skipping CELLRANGER_VDJ process.") }

            if (modality =~ /\b(GEX)/) {

                gex_indexes = params.genomes[genome].gex

                ch_gex_grouped = ch_sample_branches.gex
                    .map { row -> tuple row[0], row[1], row[2] }
                    .groupTuple(by: [0])
                    .map { row -> tuple row[0], row[1 .. 2].flatten() }

                ch_gex_alignment = CELLRANGER_COUNT(
                    ch_gex_grouped,
                    gex_indexes
                )

                ch_cellrange_outs = ch_gex_alignment.outs

            }

            if (modality =~ /\b(TCR)/) {

                vdj_indexes = params.genomes[genome].vdj

                ch_tcr_grouped = ch_sample_branches.tcr
                    .map { row -> tuple row[0], row[1], row[2] }
                    .groupTuple(by: [0])
                    .map { row -> tuple row[0], row[1 .. 2].flatten() }

                ch_tcr_alignment = CELLRANGER_VDJ(
                    ch_tcr_grouped,
                    vdj_indexes
                )

                ch_cellrange_outs = ch_tcr_alignment.outs

            }

            if (modality =~ /\b(GEX\+TCR)/) {

                ch_cellrange_outs = ch_gex_alignment.outs

            }

        }

    emit:
        ch_cellrange_outs

}
