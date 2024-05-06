process SAMPLESHEET_CHECK {
    tag "Samplesheet $samplesheet"
    label 'process_single'

    container "nfcore/cellranger:7.1.0"

    input:
        path samplesheet

    output:
        path '*.csv'       , emit: csv
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