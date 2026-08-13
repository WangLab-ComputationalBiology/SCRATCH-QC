process EXPORT_H5AD {

    tag "Exporting ${tag} h5ad"
    label 'process_medium'

    container "syedsazaidi/scratch-qc:latest"

    input:
        // tag distinguishes the object being exported (e.g. 'merged', 'singlet').
        tuple val(tag), path(seurat_rds), path(bpcells_store, stageAs: 'data/bpcells_counts')

    output:
        path("data/${params.project_name}_${tag}.h5ad"), emit: h5ad

    when:
        task.ext.when == null || task.ext.when

    script:
        """
        export_h5ad.R \\
            --rds ${seurat_rds} \\
            --store data/bpcells_counts \\
            --out data/${params.project_name}_${tag}.h5ad
        """
    stub:
        """
        mkdir -p data
        touch data/${params.project_name}_${tag}.h5ad
        """
}
