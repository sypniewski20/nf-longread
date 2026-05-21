#!/usr/bin/env bash
set -euo pipefail

input=$1

mkdir -p ${input}/truth_vcfs

FTPDIR=ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/AshkenazimTrio

wget --no-clobber -P ${input}/truth_vcfs ${FTPDIR}/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed
wget --no-clobber -P ${input}/truth_vcfs ${FTPDIR}/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz
wget --no-clobber -P ${input}/truth_vcfs ${FTPDIR}/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi

wget --no-clobber -P ${input}/truth_vcfs ${FTPDIR}/HG003_NA24149_father/NISTv4.2.1/GRCh38/HG003_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed
wget --no-clobber -P ${input}/truth_vcfs ${FTPDIR}/HG003_NA24149_father/NISTv4.2.1/GRCh38/HG003_GRCh38_1_22_v4.2.1_benchmark.vcf.gz
wget --no-clobber -P ${input}/truth_vcfs ${FTPDIR}/HG003_NA24149_father/NISTv4.2.1/GRCh38/HG003_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi

wget --no-clobber -P ${input}/truth_vcfs ${FTPDIR}/HG004_NA24143_mother/NISTv4.2.1/GRCh38/HG004_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed
wget --no-clobber -P ${input}/truth_vcfs ${FTPDIR}/HG004_NA24143_mother/NISTv4.2.1/GRCh38/HG004_GRCh38_1_22_v4.2.1_benchmark.vcf.gz
wget --no-clobber -P ${input}/truth_vcfs ${FTPDIR}/HG004_NA24143_mother/NISTv4.2.1/GRCh38/HG004_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi

mkdir -p ${input}/bams

HTTPDIR=ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/data/AshkenazimTrio

wget --no-clobber -P ${input}/bams ${HTTPDIR}/HG002_NA24385_son/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG002.SequelII.merged_15kb_20kb.GRCh38.duplomap.bam
wget --no-clobber -P ${input}/bams ${HTTPDIR}/HG002_NA24385_son/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG002.SequelII.merged_15kb_20kb.GRCh38.duplomap.bam.bai

wget --no-clobber -P ${input}/bams ${HTTPDIR}/HG003_NA24149_father/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG003.SequelII.merged_15kb_20kb.GRCh38.duplomap.bam
wget --no-clobber -P ${input}/bams ${HTTPDIR}/HG003_NA24149_father/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG003.SequelII.merged_15kb_20kb.GRCh38.duplomap.bam.bai

wget --no-clobber -P ${input}/bams ${HTTPDIR}/HG004_NA24143_mother/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG004.SequelII.merged_15kb_20kb.GRCh38.duplomap.bam
wget --no-clobber -P ${input}/bams ${HTTPDIR}/HG004_NA24143_mother/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG004.SequelII.merged_15kb_20kb.GRCh38.duplomap.bam.bai