process SNIFFLES {
    label "core"
    label "large"
    tag "${sample}"
    publishDir "${params.outfolder}/${params.runID}/sniffles", mode: 'copy', overwrite: true

    input:
        tuple val(sample), path(bam), path(bai)
        tuple path(fasta), path(fai)

    output:
        tuple val(sample), path("${sample}.sniffles.vcf.gz"), path("${sample}.sniffles.vcf.gz.tbi")
    script:
        """
        sniffles \
            --input ${bam} \
            --vcf ${sample}.sniffles.vcf.gz \
            --reference ${fasta} \
            --threads ${task.cpus}
        """
}