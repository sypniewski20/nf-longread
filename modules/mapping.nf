process PBMM2_MAPPING {
    tag "${sample}"
    label 'core'
    label 'xlarge'
    input:
        tuple val(sample), path(ubam), path(bai)
        tuple path(fasta), path(fasta_fai), path(fasta_mmi)

    output:
        tuple val(sample), path("${sample}_sorted.bam"), path("${sample}_sorted.bam.bai")

    script:
        """
        #!/bin/bash
        set -eo pipefail
        
        pbmm2 align --sort \
                    -j ${task.cpus} \
                    -J ${task.cpus} \
                    ${fasta} \
                    ${ubam} \
                    ${sample}_sorted.bam

        samtools quickcheck ${sample}_sorted.bam

        """
}
