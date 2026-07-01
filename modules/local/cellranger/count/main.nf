process CELLRANGER_COUNT {

    tag "Running GEX on ${sample}"
    label 'process_high'

    container 'syedsazaidi/scratch-cellranger8:latest'

    input:
        tuple val(sample), path(reads)
        path(reference)

    output:
        tuple val(sample), path("${sample}/outs/*"), emit: outs

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        """
            cellranger_renaming.py "${sample}" .

            cellranger \\
                count \\
                --id="${sample}" \\
                --fastqs=. \\
                --transcriptome="${reference.name}" \\
                --sample="${sample}" \\
                --localcores=${task.cpus} \\
                --localmem=${task.memory.toGiga()} \\
                --create-bam true


            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                cellranger: \$(echo \$( cellranger --version 2>&1) | sed 's/^.*[^0-9]\\([0-9]*\\.[0-9]*\\.[0-9]*\\).*\$/\\1/' )
                reference: ${reference.name}
            END_VERSIONS
        """

    stub:
        def args = task.ext.args ?: ''
        """
            cellranger_renaming.py "${sample}" .

            mkdir -p ${sample}/outs/filtered_feature_bc_matrix

            touch ${sample}/outs/filtered_feature_bc_matrix/barcodes.tsv.gz
            touch ${sample}/outs/filtered_feature_bc_matrix/features.tsv.gz
            touch ${sample}/outs/filtered_feature_bc_matrix/matrix.mtx.gz
            touch ${sample}/outs/metrics_summary.csv

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                cellranger: \$(echo \$( cellranger --version 2>&1) | sed 's/^.*[^0-9]\\([0-9]*\\.[0-9]*\\.[0-9]*\\).*\$/\\1/' )
                reference: ${reference.name}
            END_VERSIONS
        """
}
