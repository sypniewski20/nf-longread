include {
    HIPHASE_PHASING
} from '../modules/hiphase.nf'

workflow hiphase_workflow {
    take:
        ch_bam
        ch_dv_vcf
        ch_pbsv_vcf
        ch_sniffles_vcf
    main:
        ch_fasta= Channel.value([
            file(params.fasta),
            file("${params.fasta}.fai")

        ])
        HIPHASE_PHASING(
            ch_bam,
            ch_dv_vcf,
            ch_pbsv_vcf,
            ch_sniffles_vcf,
            ch_fasta
        )

    emit:
        hiphase_vcf = HIPHASE_PHASING.out.hiphase_vcf
        pbsv_hiphase_vcf = HIPHASE_PHASING.out.pbsv_hiphase_vcf
        sniffles_hiphase_vcf = HIPHASE_PHASING.out.sniffles_hiphase_vcf
}