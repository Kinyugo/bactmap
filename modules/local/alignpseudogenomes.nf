// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process ALIGNPSEUDOGENOMES {
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? "conda-forge::biopython=1.78" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/biopython:1.78"
    } else {
        container "quay.io/biocontainers/biopython:1.78"
    }

    input:
    path pseudogenomes
    path reference

    output:
    path "aligned_pseudogenomes.fas",      emit: aligned_pseudogenomes
    path "low_quality_pseudogenomes.tsv", emit: low_quality_metrics
    path "*.version.txt",       emit: version

    script: // This script is bundled with the pipeline, in nf-core/bactmap/bin/
    def software = getSoftwareName(task.process)
    """
    touch low_quality_pseudogenomes.tsv
    touch aligned_pseudogenomes.fas
    for pseudogenome in ${pseudogenomes}
    do
        fraction_non_GATC_bases=\$(calculate_fraction_of_non_GATC_bases.py -f \$pseudogenome | tr -d '\\n')
        if [[ 1 -eq "\$(echo "\$fraction_non_GATC_bases < ${params.options.non_GATC_threshold}" | bc)" ]]; then
            cat \$pseudogenome >> aligned_pseudogenomes.fas
        else
            echo "\$pseudogenome\t\$fraction_non_GATC_bases" >> low_quality_pseudogenomes.tsv
        fi
    done
    cat ${reference} >> aligned_pseudogenomes.fas

    echo '1.0' > ${software}.version.txt
    """
}
