process PBMM2_MAPPING {
    tag "${sample}"
    label 'core'
    label 'xlarge'
    input:
        // tuple contains: sample name, Library ID (LB), Platform (PL), and FASTQ paths
        tuple val(sample), path(ubam), path(bai)
        tuple path(fasta_dir), path(fasta), path(fasta_fai), path(fasta_mmi)

    output:
        tuple val(sample), path("${sample}_sorted.bam"), path("${sample}_sorted.bam.bai")

    script:
        """
        #!/bin/bash
        set -eo pipefail
        
        pbmm2 align ${fasta} \
                    ${ubam} \
                    --sort -j ${task.cpus} \
                    -J ${task.cpus} \
                    -o ${sample}_sorted.bam

        """
}
