process HIPHASE_PHASING {
    label 'core'
    label 'large'
    tag "${sample}"
    publishDir "${params.outfolder}/${params.runID}/hiphase", mode: 'copy', overwrite: true

    input:
        tuple val(sample), path(bam), path(bai), path(dv_vcf), path(dv_tbi)
        tuple path(fasta), path(fai)

    output:
        tuple val(sample), path("${sample}_hiphase.bam"), path("${sample}_hiphase.bam.bai"), emit: hiphase_bam
        tuple val(sample), path("${sample}_hiphase.dv.phased.vcf.gz"), path("${sample}_hiphase.dv.phased.vcf.gz.tbi"), emit: hiphase_vcf
    script:
        """
        hiphase \
            --reference ${fasta} \
            --bam ${bam} \
            --output-bam ${sample}_hiphase.bam \
            --vcf ${dv_vcf} \
            --output-vcf ${sample}_hiphase.dv.phased.vcf.gz \
            --threads ${task.cpus}
        """
}