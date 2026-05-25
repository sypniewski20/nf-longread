process DEEP_VARIANT {
    publishDir "${params.outfolder}/${params.runID}/deepvariant", mode: 'copy', overwrite: true
    tag "${sample}"
    label (params.gpus == 0 ? 'deepvariant' : 'deepvariant_gpu')    
    label 'xlarge'
    input:
        tuple val(sample), path(bam), path(bai)
        tuple path(fasta), path(fai)

    output:
        tuple val(sample), path("${sample}_dv.vcf.gz"), path("${sample}_dv.vcf.gz.tbi"), emit: vcf
        tuple val(sample), path("${sample}_dv.gvcf.gz"), path("${sample}_dv.gvcf.gz.tbi"), emit: gvcf
    script:
        """
        /opt/deepvariant/bin/run_deepvariant \
        --model_type ${params.seq_type} \
        --ref ${fasta} \
        --reads ${bam} \
        --output_vcf ${sample}_dv.vcf.gz \
        --output_gvcf ${sample}_dv.gvcf.gz \
        --num_shards ${task.cpus}
        """
}

process GLNEXUS {
    publishDir "${params.outfolder}/${params.runID}/deepvariant", mode: 'copy', overwrite: true
    label 'glnexus'
    label 'large'
	input:
		path(gvcf)
		path(gvcf_tbi)
	output:
		tuple path("glnexus_deepvariant.vcf.gz"), path("glnexus_deepvariant.vcf.gz.tbi")
	script:
        def config = (params.seq_type == "WES" ? "WES" : "WGS")
		"""

		glnexus_cli \
		--threads ${task.cpus} \
		--config DeepVariant${config} \
		${gvcf} | \
		bcftools view -Oz -o glnexus_deepvariant.vcf.gz

		bcftools index --tbi glnexus_deepvariant.vcf.gz

		"""

}

process NORM_MULTISAMPLE {
    publishDir "${params.outfolder}/${params.runID}/deepvariant", mode: 'copy', overwrite: true
    label 'core'
    label 'large'
	input:
		tuple path(vcf), path(vcf_tbi)
        tuple path(fasta), path(fai)
	output:
		tuple path("norm_${vcf.simpleName}.vcf.gz"), path("norm_${vcf.simpleName}.vcf.gz.tbi")
    script:
		"""

        bcftools norm -a --atom-overlaps . -m - -f ${fasta} ${vcf} -Ou | \
        bcftools view -f PASS -Ou | \
        bcftools annotate --set-id +'%CHROM\\_%POS\\_%REF\\_%ALT' -Ou | \
        bcftools +fill-tags -Ou -- -t AF,AC | \
        bcftools sort -Oz -o norm_${vcf.simpleName}.vcf.gz

        tabix -p vcf norm_${vcf.simpleName}.vcf.gz

		"""

}

process DV_EXTRACT_GT {
    label 'tiny'
    label 'core'
    publishDir "${params.outfolder}/${params.runID}/deepvariant", mode: 'copy', overwrite: true

    input:
        tuple path(vcf), path(tbi)
    output:
        path("${vcf.simpleName}_gt.tsv.gz")
    script:
    """
    echo -e "ID\\tSAMPLE\\tDP\\tAF\\tQUAL\\tGT" | bgzip -c > ${vcf.simpleName}_gt.tsv.gz
    bcftools query -f "[%ID\\t%SAMPLE\\t%DP\\t%AF\\t%QUAL\\t%GT\\n]" ${vcf} | \
    bgzip -c >> ${vcf.simpleName}_gt.tsv.gz
    """
}