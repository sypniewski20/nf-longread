#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// ============================================================
// CLINICAL IVD GERMLINE PIPELINE
// ============================================================

include { readBam }      from './modules/functions.nf'
include { pbmm2_mapping_workflow }      from './subworkflows/mapping.nf' 
include { fastq_QC_workflow; mosdepth_workflow; multiqc_workflow }     from './subworkflows/qc.nf'
include { deepvariant_workflow } from './subworkflows/deepvariant.nf'
include { hiphase_workflow } from './subworkflows/hiphase.nf'
include { sv_workflow } from './subworkflows/sv.nf'
include { methylation_workflow } from './subworkflows/methylation.nf'
include { annotation_workflow } from './subworkflows/annotation.nf'

def run_modes = params.run_mode?.split(',')*.trim()

workflow {

// 1. INPUT LAYER

    if (params.input_type == 'ubam') {

            // --- STANDARD LOCAL FASTQ MODE ---
        ch_ubam = readBam(params.samplesheet)

        mapping_results = pbmm2_mapping_workflow(ch_ubam)

        // --- COMMON POST-MAPPING LAYER ---
        mosdepth_results = mosdepth_workflow(mapping_results.ch_bam)
        
        ch_bam           = mapping_results.ch_bam
        ch_mosdepth      = mosdepth_results.ch_mosdepth.collect()

        multiqc_input = Channel.empty()
            .mix(
                ch_mosdepth
            )
            .flatten()
            .collect()

        multiqc_workflow(multiqc_input)

    } else if (params.input_type == 'bam') {

        ch_bam = readBam(params.samplesheet)

        ch_mosdepth = mosdepth_workflow(ch_bam).ch_mosdepth.collect()
        multiqc_workflow(ch_mosdepth)
    }

    if ('DV' in run_modes) {

        dv_results = deepvariant_workflow(ch_bam)

        phase_input = ch_bam
            .join(dv_results.ch_vcf, by: 0, failOnMismatch: true)

        hiphase_workflow(phase_input)

        if (params.annotate == true) {
            annotation_workflow(dv_results.ch_vcf, dv_results.ch_tbi)
        }
    }

    if ('SV' in run_modes) {
        sv_workflow(ch_bam)
    }


    if ('METHYLATION' in run_modes) {

        ch_bam_input = hiphase_workflow.out.ch_hiphase_bam ?: ch_bam

        methylation_workflow(ch_bam_input)
    }

}