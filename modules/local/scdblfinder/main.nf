process SCDBLFINDER {

    tag "Removing doublets"
    label 'process_high'

    container "syedsazaidi/scratch-qc:latest"

    input:
        path(seurat_object)
        // BPCells on-disk counts store backing the merged object; staged at the
        // relative path its lazy layers reference so NormalizeData can read it.
        path(bpcells_store, stageAs: 'data/bpcells_counts')
        path(notebook_scdblfinder)
        path(page_config)

    output:
        path("data/${params.project_name}_qc_*.RDS"), emit: seurat_rds
        path("report/${notebook_scdblfinder.baseName}.html")
        path("_freeze/**/figure-html/*.png"), emit: figures

    when:
        task.ext.when == null || task.ext.when
        
    script:
        def param_file = task.ext.args ? "-P seurat_object:${seurat_object} -P ${task.ext.args}" : ""
        """
        quarto render ${notebook_scdblfinder} ${param_file}
        """
    stub:
        """
        mkdir -p report data figures 
        mkdir -p _freeze/DUMMY/figure-html
        
        touch _freeze/DUMMY/figure-html/FILE.png

        touch data/${params.project_name}_qc_sample_object.RDS
        touch data/${params.project_name}_qc_cluster_object.RDS

        touch report/${notebook_scdblfinder.baseName}.html

        """

}