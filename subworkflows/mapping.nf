include { PBMM2_MAPPING } from '../modules/mapping.nf'

// ==========================
// MULTIQC
// ==========================
workflow pbmm2_mapping_workflow {

    take:
        ch_ubam

    main:

        ch_fasta = Channel.value([
        file(params.fasta),
        file("${params.fasta}.fai"),
        file("${params.fasta}.mmi")
        ])
        
        PBMM2_MAPPING(ch_ubam, ch_fasta)
    
    emit:
        ch_bam = PBMM2_MAPPING.out
        
}