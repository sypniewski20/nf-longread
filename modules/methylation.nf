process MINIMOD {
    publishDir "${params.outfolder}/${params.runID}/methylation/minimod", mode: 'copy', overwrite: true    
    tag "${sample}"
    label 'core'
    label 'medium'
    input:
        tuple val(sample), path(bam), path(bai)
        tuple path(fasta), path(fai)
    output:
        tuple val(sample), path("${sample}_minimod.tsv.gz"), emit: minimod
    script:
        """
        minimod view \
            ${fasta} \
            ${bam} | bgzip -c > ${sample}_minimod.tsv.gz
        """ 
}

process PB_CPG {
    publishDir "${params.outfolder}/${params.runID}/methylation/pb-cpg", mode: 'copy', overwrite: true
    tag "${sample}"
    label 'core'
    label 'medium'
    input:
        tuple val(sample), path(bam), path(bai)
        tuple path(fasta), path(fai)
    output:
        tuple val(sample), path("${sample}.hap1.bed.gz"), emit: hap1_bed
        tuple val(sample), path("${sample}.hap1.bed.gz.tbi"), emit: hap1_tbi
        tuple val(sample), path("${sample}.hap1.bw"), emit: hap1_bw
        tuple val(sample), path("${sample}.hap2.bed.gz"), emit: hap2_bed
        tuple val(sample), path("${sample}.hap2.bed.gz.tbi"), emit: hap2_tbi
        tuple val(sample), path("${sample}.hap2.bw"), emit: hap2_bw
    script:
        """
    aligned_bam_to_cpg_scores \
      --bam ${bam} \
      --output-prefix ${sample} \
      --threads ${task.cpus}
        """ 
}