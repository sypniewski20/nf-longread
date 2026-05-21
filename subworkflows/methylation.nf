include {
    MINIMOD; PB_CPG
} from '../modules/methylation.nf'


workflow METHYLATION_WORKFLOW {

    take:
        ch_bam
        ch_fasta

     main:


    minimod_results = MINIMOD(ch_bam, ch_fasta)
    pb_cpg_results = PB_CPG(ch_bam, ch_fasta)

} 