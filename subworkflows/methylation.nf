include {
    PB_CPG
} from '../modules/methylation.nf'


workflow methylation_workflow {

    take:
        ch_bam

     main:

    ch_fasta = Channel.value([
        file(params.fasta),
        file("${params.fasta}.fai")
    ])

    PB_CPG(ch_bam, ch_fasta)

} 