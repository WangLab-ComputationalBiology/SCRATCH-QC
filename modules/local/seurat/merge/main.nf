process SEURAT_MERGE {

    tag "Merging post-QC samples"
    label 'process_high'

    container "syedsazaidi/scratch-qc:latest"

    input:
        path(qc_approved)
        path(notebook_merge)
        path(exp_table)
        path(page_config)

    output:
        path("data/${params.project_name}_qc_merged_object.RDS"), emit: seurat_rds
        // On-disk BPCells counts store backing the merged object. Emitted so
        // downstream steps (e.g. SCDBLFINDER) can stage it at the same relative
        // path the object's lazy layers reference.
        path("data/bpcells_counts"), emit: bpcells_store
        path("report/${notebook_merge.baseName}.html")

    when:
        task.ext.when == null || task.ext.when
        
    script:
        def param_file = task.ext.args ? "-P input_qc_approved:\'${qc_approved.join(';')}\' -P input_exp_table:${exp_table} -P ${task.ext.args}" : ""
        """
        quarto render ${notebook_merge} ${param_file}
        """
    stub:
        def param_file = task.ext.args ? "-P input_qc_approved:\'${qc_approved.join(';')}\' -P input_exp_table:${exp_table} -P ${task.ext.args}" : ""
        """
        mkdir -p report data/bpcells_counts figures/merge

        touch data/${params.project_name}_qc_merged_object.RDS
        touch data/bpcells_counts/matrix.mtx
        touch report/${notebook_merge.baseName}.html

        """
}
