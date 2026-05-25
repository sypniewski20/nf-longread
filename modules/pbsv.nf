process PBSV_DISCOVER {
    label "core"
    label "large"
    tag "${sample}"

    input:
        tuple val(sample), path(bam), path(bai)

    output:
        tuple val(sample), path("${sample}.svsig.gz")
    script:
        """

        pbsv discover ${bam} ${sample}.svsig.gz

        """
}

process PBSV_CALL {
    label "core"
    label "large"
    tag "${sample}"
    publishDir "${params.outfolder}/${params.runID}/pbsv", mode: 'copy', overwrite: true

    input:
        tuple val(sample), path(sv_sig)
        tuple path(fasta), path(fai)

    output:
        tuple val(sample), path("${sample}.pbsv.vcf.gz"), path("${sample}.pbsv.vcf.gz.tbi")
    script:
        """

        pbsv call ${fasta} ${sv_sig} ${sample}.pbsv.vcf

        bgzip ${sample}.pbsv.vcf
        tabix -p vcf ${sample}.pbsv.vcf.gz


        """
}

