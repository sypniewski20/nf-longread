include { SNIFFLES_SNF; SNIFFLES_MULTISAMPLE } from '../modules/sniffles.nf'
include { PBSV_DISCOVER; PBSV_CALL } from '../modules/pbsv.nf'
include { MERGE_SVS } from '../modules/survivor.nf'

workflow sv_workflow {
    take:
        ch_bam    
    main:

        ch_fasta= Channel.value([
            file(params.fasta),
            file("${params.fasta}.fai")

        ])

        PBSV_DISCOVER(ch_bam)
        PBSV_CALL(PBSV_DISCOVER.out, ch_fasta)

        SNIFFLES_SNF(ch_bam)
        SNIFFLES_MULTISAMPLE(SNIFFLES_SNF.out.snf.collect())

    emit:
        ch_pbsv_vcf = PBSV_CALL.out
        ch_sniffles_vcf = SNIFFLES_SNF.out.vcf
}