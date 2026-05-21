include { SNIFFLES } from './modules/sniffles.nf'
include { PBSV } from './modules/pbsv.nf'
include { SURVIVOR } from './modules/survivor.nf'

workflow sv_workflow {
    take:
        ch_bam    
    main:

        ch_fasta= Channel.value([
            file(params.fasta),
            file("${params.fasta}.fai")

        ])

        PBSV(ch_bam, ch_fasta)
        SNIFFLES(ch_bam, ch_fasta)
        SURVIVOR(PBSV.out.ch_pbsv_vcf, SNIFFLES.out)

    emit:
        ch_pbsv_vcf = PBSV.out.ch_pbsv_vcf
        ch_sniffles_vcf = SNIFFLES.out
}