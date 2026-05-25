process HIPHASE_PHASING {
    label 'core'
    label 'large'
    tag "${sample}"
    publishDir "${params.outfolder}/${params.runID}/hiphase", mode: 'copy', overwrite: true

    input:
        tuple val(sample), path(bam), path(bai)
        tuple val(sample), path(dv_vcf), path(dv_tbi)
        tuple val(sample), path(pbsv_vcf), path(pbsv_tbi)
        tuple val(sample), path(sniffles_vcf), path(sniffles_tbi)
        tuple path(fasta), path(fai)

    output:
        tuple val(sample), path("${sample}_hiphase.bam"), path("${sample}_hiphase.bam.bai"), emit: hiphase_bam
        tuple val(sample), path("${sample}_hiphase.dv.phased.vcf.gz"), path("${sample}_hiphase.dv.phased.vcf.gz.tbi"), emit: hiphase_vcf
        tuple val(sample), path("${sample}_hiphase.pbsv.phased.vcf.gz"), path("${sample}_hiphase.pbsv.phased.vcf.gz.tbi"), emit: pbsv_hiphase_vcf
        tuple val(sample), path("${sample}_hiphase.sniffles.phased.vcf.gz"), path("${sample}_hiphase.sniffles.phased.vcf.gz.tbi"), emit: sniffles_hiphase_vcf
    script:
        """
        hiphase \
            --reference ${fasta} \
            --bam ${bam} \
            --output-bam ${sample}_hiphase.bam \
            --vcf ${dv_vcf} \
            --output-vcf ${sample}_hiphase.dv.phased.vcf.gz \
            --vcf ${pbsv_vcf} \
            --output-vcf ${sample}_hiphase.pbsv.phased.vcf.gz \
            --vcf ${sniffles_vcf} \
            --output-vcf ${sample}_hiphase.sniffles.phased.vcf.gz \
            --threads ${task.cpus}
        """
}