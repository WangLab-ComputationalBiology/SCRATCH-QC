#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { SCRATCH_QC } from './subworkflow/local/scratch_qc.nf'

workflow {

    // -------------------------------------------------------------------------
    // A single samplesheet drives the whole QC run. It lists every sample with
    // an explicit path to its matrices and (optionally) its metadata columns,
    // so samples spread across many source-dataset prefixes are all included.
    // This replaces the old single-prefix `--input_gex_matrices_path` glob,
    // which could only ever match matrices under one dataset UUID.
    //
    // Required columns: sample, h5, metrics_csv
    // Optional columns: any metadata (patient_id, timepoint, batch, ...) that
    //                   SEURAT_MERGE should attach to cells (joined by `sample`).
    // -------------------------------------------------------------------------

    if (!params.input_samplesheet) exit 1, 'Please, provide a --input_samplesheet <PATH> !'

    log.info """\

        Parameters:

        Samplesheet: ${params.input_samplesheet}

    """

    // Per-sample matrices: [ sample, metrics_csv, h5 ]
    ch_gex_matrices = Channel.fromPath(params.input_samplesheet, checkIfExists: true)
        .splitCsv(header: true, sep: ',')
        .map { row ->
            if (!row.sample)      exit 1, "Samplesheet row is missing a 'sample' value: ${row}"
            if (!row.h5)          exit 1, "Samplesheet row for '${row.sample}' is missing an 'h5' path"
            if (!row.metrics_csv) exit 1, "Samplesheet row for '${row.sample}' is missing a 'metrics_csv' path"
            def h5  = file(row.h5,          checkIfExists: true)
            def csv = file(row.metrics_csv, checkIfExists: true)
            tuple(row.sample, csv, h5)
        }

    // The same samplesheet carries the metadata columns consumed by SEURAT_MERGE
    // (joined onto cells by `sample`). Path columns are dropped inside the merge
    // notebook, so it is safe to reuse the sheet here.
    ch_exp_table = Channel.fromPath(params.input_samplesheet, checkIfExists: true)

    SCRATCH_QC(
        ch_gex_matrices,
        ch_exp_table
    )

}
