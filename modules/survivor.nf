process MERGE_SVS {
    label 'core'
    label 'small'
    input:
        path(pbsv_vcf)
        path(sniffles_vcf)

    output:
        tuple path("merged_consensus.vcf"), path("merged_consensus.vcf.gz.tbi")
    script:
    """

    echo "${pbsv_vcf}" > sample_list.txt
    echo "${sniffles_vcf}" >> sample_list.txt

    SURVIVOR merge sample_list.txt 500 2 1 0 50 merged_consensus.vcf

    bgzip merged_consensus.vcf
    tabix -p vcf merged_consensus.vcf.gz

    """
}