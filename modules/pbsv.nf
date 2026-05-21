process PBSV {
    label "core"
    label "large"
    tag "${sample}"
    publishDir "${params.outfolder}/${params.runID}/pbsv", mode: 'copy', overwrite: true

    input:
        tuple val(sample), path(bam), path(bai)
        tuple path(fasta), path(fai)

    output:
        tuple val(sample), path("${sample}.pbsv.vcf.gz"), path("${sample}.pbsv.vcf.gz.tbi"), emit: ch_pbsv_vcf
        tuple val(sample), path("${sample}.pbsv.discover.bed"), emit: ch_pbsv_bed, emit: ch_pbsv_bed
    script:
        """
        pbsv discover ${bam} ${sample}.pbsv.discover.bed --reference ${fasta} --threads ${task.cpus}
        pbsv call ${fasta} ${sample}.pbsv.discover.bed ${bam} ${sample}.pbsv.vcf.gz --threads ${task.cpus}
        """
}