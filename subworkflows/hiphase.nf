include {
    HIPHASE_PHASING
} from '../modules/hiphase.nf'

workflow hiphase_workflow {
    take:
        phase_input_ch

    main:
        ch_fasta = Channel.value([
            file(params.fasta),
            file("${params.fasta}.fai")
        ])

        HIPHASE_PHASING(phase_input_ch, ch_fasta)

    emit:
        ch_hiphase_bam = HIPHASE_PHASING.out.hiphase_bam
        ch_hiphase_vcf = HIPHASE_PHASING.out.hiphase_vcf
}