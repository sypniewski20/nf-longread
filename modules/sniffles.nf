process SNIFFLES_SNF {
    label "core"
    label "large"
    tag "${sample}"
    publishDir "${params.outfolder}/${params.runID}/sniffles", mode: 'copy', overwrite: true

    input:
        tuple val(sample), path(bam), path(bai)
    output:
        tuple val(sample), path("${sample}.sniffles.vcf.gz"), path("${sample}.sniffles.vcf.gz.tbi"), emit: vcf
        path("${sample}.sniffles.snf"), emit: snf
    script:
        """

        sniffles --input ${bam} \
        --vcf ${sample}.sniffles.vcf \
        --snf ${sample}.sniffles.snf \
        --sample-id ${sample}

        bgzip ${sample}.sniffles.vcf
        tabix -p vcf ${sample}.sniffles.vcf.gz

        """
}

process SNIFFLES_MULTISAMPLE {
    label "core"
    label "large"
    publishDir "${params.outfolder}/${params.runID}/sniffles", mode: 'copy', overwrite: true
    input:
        path(snfs)

    output:
        tuple path("multisample.sniffles.vcf.gz"), path("multisample.sniffles.vcf.gz.tbi")
    script:
        """

        sniffles --input ${snfs} \
        --vcf multisample.sniffles.vcf

        bgzip multisample.sniffles.vcf
        tabix -p vcf multisample.sniffles.vcf.gz


        """
}