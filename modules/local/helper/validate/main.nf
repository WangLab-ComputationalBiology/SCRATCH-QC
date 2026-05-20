process SAMPLESHEET_CHECK {
    tag "Samplesheet $samplesheet"
    label 'process_single'

    // container "nfcore/cellranger:7.1.0"
    // container "dustincys/cellranger:8.0.1"
    container "syedsazaidi/scratch-cellranger8:latest"

    input:
        path samplesheet

    output:
        path 'samplesheet.valid.csv', emit: csv
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        """
        cp ${samplesheet} samplesheet.valid.csv

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            python: \$(python --version | sed 's/Python //g')
        END_VERSIONS
        """
}