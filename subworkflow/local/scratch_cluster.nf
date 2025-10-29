//
// Description
//

include { SEURAT_NORMALIZE          } from '../../modules/local/seurat/normalization/main.nf'
include { SEURAT_CLUSTER            } from '../../modules/local/seurat/cluster/main.nf'

// Importing Quarto notebooks

workflow SCRATCH_CLUSTERING {

    // Channel definitions
    ch_versions  = Channel.empty()

    take:
        ch_merge_object // channel: [ val(meta), [ ... ] ]

    main:

        // Importing notebook
        ch_notebook_normalize  = Channel.fromPath(params.notebook_normalize, checkIfExists: true)
        ch_notebook_clustering = Channel.fromPath(params.notebook_clustering, checkIfExists: true)

        // Quarto settings
        ch_template    = Channel.fromPath(params.template, checkIfExists: true)
            .collect()

        ch_page_config = Channel.fromPath(params.page_config, checkIfExists: true)
            .collect()

        ch_page_config = ch_template
            .map{ file -> file.find { it.toString().endsWith('.png') } }
            .combine(ch_page_config)
            .collect()

        ch_page_config
            .view()

        // Normalizing dataset
        SEURAT_NORMALIZE(
            ch_merge_object,
            ch_notebook_normalize,
            ch_page_config
        )

        ch_normalized_object = SEURAT_NORMALIZE.out.seurat_rds

        // Performing clustering        
        SEURAT_CLUSTER(          
            ch_normalized_object,
            ch_notebook_clustering,
            ch_page_config
        )

        ch_cluster = SEURAT_CLUSTER.out.seurat_rds

    emit:
        ch_cluster
}

