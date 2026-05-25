#!/usr/bin/env bash
set -euo pipefail

input=$1
TARGET_CHR="chr21"

mkdir -p ${input}/truth_vcfs
mkdir -p ${input}/bams

URL_RELEASE="https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/AshkenazimTrio"
URL_DATA="https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/data/AshkenazimTrio"

echo "  -> Slicing remote VCF files for ${TARGET_CHR}..."

tabix -h "${URL_RELEASE}/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz" "${TARGET_CHR}" | bgzip -c > ${input}/truth_vcfs/HG002_GRCh38_${TARGET_CHR}_v4.2.1_benchmark.vcf.gz
tabix -h "${URL_RELEASE}/HG003_NA24149_father/NISTv4.2.1/GRCh38/HG003_GRCh38_1_22_v4.2.1_benchmark.vcf.gz" "${TARGET_CHR}" | bgzip -c > ${input}/truth_vcfs/HG003_GRCh38_${TARGET_CHR}_v4.2.1_benchmark.vcf.gz
tabix -h "${URL_RELEASE}/HG004_NA24143_mother/NISTv4.2.1/GRCh38/HG004_GRCh38_1_22_v4.2.1_benchmark.vcf.gz" "${TARGET_CHR}" | bgzip -c > ${input}/truth_vcfs/HG004_GRCh38_${TARGET_CHR}_v4.2.1_benchmark.vcf.gz

tabix -p vcf ${input}/truth_vcfs/HG002_GRCh38_${TARGET_CHR}_v4.2.1_benchmark.vcf.gz
tabix -p vcf ${input}/truth_vcfs/HG003_GRCh38_${TARGET_CHR}_v4.2.1_benchmark.vcf.gz
tabix -p vcf ${input}/truth_vcfs/HG004_GRCh38_${TARGET_CHR}_v4.2.1_benchmark.vcf.gz
rm *_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi

echo "  -> Slicing remote BED files for ${TARGET_CHR}..."

curl -s ${URL_RELEASE}/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed | awk -v chr="$TARGET_CHR" '$1 == chr' > ${input}/truth_vcfs/HG002_GRCh38_${TARGET_CHR}_benchmark_noinconsistent.bed
curl -s ${URL_RELEASE}/HG003_NA24149_father/NISTv4.2.1/GRCh38/HG003_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed | awk -v chr="$TARGET_CHR" '$1 == chr' > ${input}/truth_vcfs/HG003_GRCh38_${TARGET_CHR}_benchmark_noinconsistent.bed
curl -s ${URL_RELEASE}/HG004_NA24143_mother/NISTv4.2.1/GRCh38/HG004_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed | awk -v chr="$TARGET_CHR" '$1 == chr' > ${input}/truth_vcfs/HG004_GRCh38_${TARGET_CHR}_benchmark_noinconsistent.bed

echo "  -> Slicing remote HG002_NA24385_son BAM files for ${TARGET_CHR}..."

samtools view -b -@ 4 -X ${URL_DATA}/HG002_NA24385_son/PacBio_HiFi-Revio_20231031/HG002_PacBio-HiFi-Revio_20231031_48x_GRCh38-GIABv3.bam \
                        ${URL_DATA}/HG002_NA24385_son/PacBio_HiFi-Revio_20231031/HG002_PacBio-HiFi-Revio_20231031_48x_GRCh38-GIABv3.bam.bai \
                        ${TARGET_CHR} > ${input}/bams/HG002_${TARGET_CHR}_PacBio-HiFi-Revio_20231031_48x_GRCh38-GIABv3.bam
samtools index ${input}/bams/HG002_${TARGET_CHR}_PacBio-HiFi-Revio_20231031_48x_GRCh38-GIABv3.bam

echo "  -> Slicing remote HG003_NA24149_father BAM files for ${TARGET_CHR}..."

samtools view -b -@ 4 -X ${URL_DATA}/HG003_NA24149_father/PacBio_HiFi-Revio_20231031/HG003_PacBio-HiFi-Revio_20231031_46x_GRCh38-GIABv3.bam \
                        ${URL_DATA}/HG003_NA24149_father/PacBio_HiFi-Revio_20231031/HG003_PacBio-HiFi-Revio_20231031_46x_GRCh38-GIABv3.bam.bai \
                        ${TARGET_CHR} > ${input}/bams/HG003_${TARGET_CHR}_PacBio-HiFi-Revio_20231031_46x_GRCh38-GIABv3.bam
samtools index ${input}/bams/HG003_${TARGET_CHR}_PacBio-HiFi-Revio_20231031_46x_GRCh38-GIABv3.bam

echo "  -> Slicing remote HG004_NA24143_mother BAM files for ${TARGET_CHR}..."

samtools view -b -@ 4 -X ${URL_DATA}/HG004_NA24143_mother/PacBio_HiFi-Revio_20231031/HG004_PacBio-HiFi-Revio_20231031_36x_GRCh38-GIABv3.bam \
                        ${URL_DATA}/HG004_NA24143_mother/PacBio_HiFi-Revio_20231031/HG004_PacBio-HiFi-Revio_20231031_36x_GRCh38-GIABv3.bam.bai \
                        ${TARGET_CHR} > ${input}/bams/HG004_${TARGET_CHR}_PacBio-HiFi-Revio_20231031_36x_GRCh38-GIABv3.bam
samtools index ${input}/bams/HG004_${TARGET_CHR}_PacBio-HiFi-Revio_20231031_36x_GRCh38-GIABv3.bam



echo "  -> Validating bam files..."

samtools quickcheck -qv ${input}/bams/*.bam > ${input}/bams/bad_bams.fofn \
        && echo 'all ok' \
        || echo "some files failed check, see ${input}/bams/bad_bams.fofn"

echo "  -> Reversing to uBAM format..."

samtools reset \
  --keep-tag RG,MM,ML \
  -o ${input}/bams/HG002_Revio_48x_GRCh38-GIABv3.ubam.bam \
  ${input}/bams/HG002_${TARGET_CHR}_PacBio-HiFi-Revio_20231031_48x_GRCh38-GIABv3.bam

samtools index ${input}/bams/HG002_Revio_48x_GRCh38-GIABv3.ubam.bam

samtools reset \
  --keep-tag RG,MM,ML \
  -o ${input}/bams/HG003_Revio_46x_GRCh38-GIABv3.ubam.bam \
  ${input}/bams/HG003_${TARGET_CHR}_PacBio-HiFi-Revio_20231031_46x_GRCh38-GIABv3.bam

samtools index ${input}/bams/HG003_Revio_46x_GRCh38-GIABv3.ubam.bam

samtools reset \
  --keep-tag RG,MM,ML \
  -o ${input}/bams/HG004_Revio_36x_GRCh38-GIABv3.ubam.bam \
  ${input}/bams/HG004_${TARGET_CHR}_PacBio-HiFi-Revio_20231031_36x_GRCh38-GIABv3.bam

samtools index ${input}/bams/HG004_Revio_36x_GRCh38-GIABv3.ubam.bam

rm *_PacBio-HiFi-Revio_20231031_*x_GRCh38-GIABv3.bam.bai

echo "Success. Mini-trio extracted to: ${input}/truth_vcfs and ${input}/bams"

