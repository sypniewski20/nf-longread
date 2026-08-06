# PacBio pipeline

---

## Table of Contents

- [Overview](#overview)
- [Pipeline Architecture](#pipeline-architecture)
- [Requirements](#requirements)
- [Repository Structure](#repository-structure)
- [Setup with Make](#setup-with-make)
- [Samplesheet Format](#samplesheet-format)
- [Quick Start](#quick-start)
- [Run Modes](#run-modes)
- [Configuration](#configuration)
- [Output Structure](#output-structure)
- [Benchmarking & Validation](#benchmarking--validation)
- [Scope Note](#scope-note)
- [License & Compliance](#license--compliance)

---

## Overview

`nf-ivd` supports the following analysis types:

- **WGS & WES** sequencing inputs
- **Single-sample** germline variant calling
- **Joint/cohort calling** with pedigree-aware family priors (Trio support)
- **Structural variant (SV)** detection via Manta and gCNV
- **GIAB calibration mode** for benchmarking against NIST truth sets (HG002, HG003, HG004)

### TO DO

- **Tumor-only and tumor/normal calling with Mutect2 + SEQC2 benchmarking**
- **VEP annotation**
- **PacBio HiFi support (separate repository)**

---

## Pipeline Architecture

```
Input Layer
├── FASTQ mode → QC (FastQC + fastp) → Alignment (DragMap)
│   ├── Standard local FASTQ
│   └── NIST streaming mode (URL-based, MD5-tagged chunks)
└── BAM mode → Skip to variant calling

Post-mapping Layer
└── DRAGstr calibration → Coverage QC (Mosdepth)

Routing Layer (run_mode)
├── HC    → HaplotypeCaller (DRAGEN-mode) → VQSR / filtering
├── SV    → Manta + gCNV
└── calibration → HC → hap.py benchmarking vs NIST truth

Reporting
└── MultiQC (FastQC + flagstat + Mosdepth + variant stats)
```

---

## Requirements

| Dependency              | Version                                         |
|-------------------------|-------------------------------------------------|
| Nextflow                | < 26
| Singularity / Apptainer | any recent                                      |
| Container images        | `core.sif`, `qc.sif`, `happi.sif`, `manta.sif` |
| Reference genome        | GRCh38 FASTA + index                            |
| DRAGstr STR table       | bundled with GATK 4.6+                          |
| Pedigree file           | optional (`.ped`, for joint-calling)            |

> Container images must be version-locked in your local Singularity registry to satisfy IVD reproducibility requirements.

---

## Repository Structure

```
nf-ivd/
├── main.nf                  # Workflow entry point
├── nextflow.config          # Parameters & profiles
├── fetch_ajtrio.R           # Ashkenazim Trio GIAB data helper
├── modules/
│   └── functions.nf         # Samplesheet & BAM readers
├── subworkflows/
│   ├── mapping.nf           # DragMap alignment
│   ├── qc.nf                # FastQC, fastp, Mosdepth, NIST streaming QC
│   ├── multiqc.nf           # Aggregated QC report
│   ├── HC.nf                # HaplotypeCaller (DRAGEN-mode)
│   ├── manta.nf             # Structural variant calling
│   ├── gCNV.nf              # Copy number variant calling
│   └── calibration.nf       # GIAB benchmarking
└── deployment/
    ├── manifests/           # Example samplesheets & PED files
    ├── reference/truth/     # NIST v4.2.1 truth VCFs & BEDs
    └── benchmark/
        └── trio_benchmark_results/
            └── validation/  # hap.py benchmark outputs
```

---

## Setup with Make

The `Makefile` manages the full clinical environment lifecycle — building containers, downloading references, and verifying all data integrity before use. All artefacts land under `deployment/`.

### Quick start

```bash
# Build containers and download all references (requires gsutil + singularity)
make setup

# Download Ashkenazim Trio reads separately (large files — run when ready)
make data
```

### Available targets

| Target               | Description                                                                                                       |
|----------------------|-------------------------------------------------------------------------------------------------------------------|
| `make all`           | Runs `setup` + `data` (full environment bootstrap)                                                                |
| `make setup`         | Runs `containers`, `strat`, `truth`, `fasta`, `add_resources`                                                     |
| `make containers`    | Builds all Singularity images from `.def` files (or pulls from Docker Hub for `happi.sif`)                        |
| `make fasta`         | Downloads GRCh38 FASTA and builds the DragMap hash table                                                          |
| `make truth`         | Downloads & verifies NIST v4.2.1 truth VCFs and BEDs for HG002–HG004                                             |
| `make strat`         | Downloads & verifies GIAB stratification BEDs                                                                     |
| `make add_resources` | Fetches ploidy priors, 1000G PoN, Broad WGS intervals, ENCODE blacklist, UCSC segdups; runs `refine_intervals.sh` |
| `make data`          | Downloads Ashkenazim Trio FASTQ reads (large — run manually)                                                      |
| `make clean`         | Removes outputs, logs, and built `.sif` images                                                                    |

### Container images

| Image       | Source                                                                                             |
|-------------|----------------------------------------------------------------------------------------------------|
| `core.sif`  | `deployment/singularity/def/core.def` (GATK + DragMap) — built with `--fakeroot`                  |
| `qc.sif`    | `deployment/singularity/def/qc.def` (FastQC, fastp, Mosdepth, samtools) — built with `--fakeroot` |
| `happi.sif` | `docker://mgibio/hap.py:v0.3.12`                                                                   |
| `manta.sif` | `deployment/singularity/def/manta.def`                                                             |

> `core.sif` and `qc.sif` are built from local definitions using `--fakeroot` to ensure no unverified layers are introduced from external registries.

### Data integrity & verification

All downloads are governed by manifests in `deployment/manifests/`. The setup process calls `scripts/download_and_verify.R`, which compares downloaded file hashes against the manifest CSVs and creates a versioned snapshot to ensure reference data cannot be silently modified post-download.

> `make fasta` also runs `dragen-os --build-hash-table` via `core.sif` — the FASTA directory must be writable and have sufficient disk space for the hash table.

---

## Samplesheet Format

The samplesheet is a comma-separated CSV passed to `--samplesheet`. Required columns differ by `--input_type`.

### FASTQ samplesheet (`--input_type fastq`)

| Column | Description                                                   | Required |
|--------|---------------------------------------------------------------|----------|
| `SM`   | Sample name — grouping key and BAM `SM` read group tag        | ✅        |
| `ID`   | Read group ID (`RGID`). Falls back to `{SM}_{LB}` if omitted | optional |
| `LB`   | Library name (`RGLB`). Defaults to `unknown_lib` if omitted   | optional |
| `PL`   | Sequencing platform (`RGPL`), e.g. `ILLUMINA`                 | optional |
| `PU`   | Platform unit (`RGPU`), e.g. flowcell barcode                 | optional |
| `R1`   | Path or URL to Read 1 FASTQ (gzipped)                         | ✅        |
| `R2`   | Path or URL to Read 2 FASTQ (gzipped)                         | ✅        |

```csv
SM,ID,LB,PL,PU,R1,R2
HG002,HG002_L001,lib1,ILLUMINA,HXXXXXX.1,/data/HG002_R1.fastq.gz,/data/HG002_R2.fastq.gz
HG003,HG003_L001,lib1,ILLUMINA,HXXXXXX.2,/data/HG003_R1.fastq.gz,/data/HG003_R2.fastq.gz
```

For **calibration mode**, `R1`/`R2` can be remote URLs (GIAB FTP/S3). The `ID` field is used as the MD5 chunk tag for streaming QC grouping.

### BAM samplesheet (`--input_type bam`)

| Column     | Description                                  | Required |
|------------|----------------------------------------------|----------|
| `sampleID` | Sample identifier                            | ✅        |
| `bam`      | Path to sorted BAM file                      | ✅        |
| `bai`      | Path to the corresponding BAM index (`.bai`) | ✅        |

```csv
sampleID,bam,bai
HG002,/data/HG002.bam,/data/HG002.bam.bai
HG003,/data/HG003.bam,/data/HG003.bam.bai
```

> Both samplesheet readers use `checkIfExists: true` — the pipeline will fail fast at startup if any path is invalid.

---

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/sypniewski20/nf-ivd.git
cd nf-ivd
```

### 2. Configure paths

Set your local paths in `nextflow.config`:

```
params.fasta            = "/path/to/GRCh38.fa"
params.singularity_path = "/path/to/sif_images"
```

### 3. Run

**Single sample — WGS, FASTQ input:**

```bash
nextflow run main.nf \
    --input_type fastq \
    --run_mode HC \
    --samplesheet deployment/manifests/HG002_samplesheet.csv \
    -profile singularity
```

**Trio — joint calling with pedigree:**

```bash
nextflow run main.nf \
    --input_type fastq \
    --run_mode HC \
    --calling_mode cohort \
    --pedigree deployment/manifests/ashkenazim_trio.ped \
    --samplesheet deployment/manifests/trio_samplesheet.csv \
    -profile singularity
```

**Structural variants:**

```bash
nextflow run main.nf \
    --input_type bam \
    --run_mode SV \
    --samplesheet deployment/manifests/sample_bams.csv \
    -profile singularity
```

**GIAB calibration / benchmarking:**

```bash
nextflow run main.nf \
    --input_type fastq \
    --run_mode calibration \
    --samplesheet deployment/manifests/HG002_nist_samplesheet.csv \
    -profile singularity
```

---

## Run Modes

| `--run_mode`  | Description                                                |
|---------------|------------------------------------------------------------|
| `HC`          | HaplotypeCaller germline SNV/indel calling in DRAGEN-mode  |
| `SV`          | Structural variant calling (Manta + gCNV)                  |
| `calibration` | NIST streaming QC → HC → hap.py benchmarking vs GIAB truth |

Multiple modes can be combined as a comma-separated string, e.g. `--run_mode HC,SV`.

---

## Configuration

All parameters are set in `nextflow.config`. Key options:

| Parameter          | Description                                              | Default   |
|--------------------|----------------------------------------------------------|-----------|
| `input_type`       | Input data format: `fastq` or `bam`                      | `fastq`   |
| `run_mode`         | Analysis mode: `HC`, `SV`, `calibration`                 | `HC`      |
| `seq_type`         | `WGS` or `WES` — affects intervals & DRAGstr calibration | `WGS`     |
| `calling_mode`     | `single` or `cohort` (GenomicsDB / GenotypeGVCFs)        | `cohort`  |
| `dragen_mode`      | Enable DRAGEN-equivalent HMM and parameters              | `true`    |
| `pedigree`         | Path to `.ped` file for Bayesian pedigree priors         | `null`    |
| `intervals_list`   | Genomic regions for parallel scatter                     | `chr1..M` |
| `interval_padding` | Padding in bp around WES target intervals                | `150`     |
| `fasta`            | Path to GRCh38 reference FASTA                           | `null`    |
| `bed`              | Target BED file (WES only)                               | `null`    |
| `strat_dir`        | GIAB stratification BEDs directory                       | `null`    |
| `outfolder`        | Root output directory                                    | `results` |
| `singularity_path` | Path to directory containing `.sif` container images     | `null`    |

### Resource labels (Singularity profile)

| Label     | CPUs | Memory | Wall time |
|-----------|------|--------|-----------|
| `tiny`    | 1    | 2 GB   | 1 h       |
| `small`   | 2    | 6 GB   | 4 h       |
| `medium`  | 4    | 16 GB  | 12 h      |
| `large`   | 8    | 32 GB  | 24 h      |
| `xlarge`  | 16   | 64 GB  | 36 h      |
| `xxlarge` | 32   | 128 GB | 48 h      |

---

## Output Structure

Each run generates a timestamped directory under `--outfolder` (format: `YYYYMMDD_HHMMSS`):

```
results/
└── 20250423_120000/
    ├── bam/        # Sorted, indexed BAMs with full Read Group headers
    ├── vcf/        # Filtered final VCFs (SNV/indel and/or SV)
    ├── qc/         # Per-sample FastQC, fastp, flagstat, Mosdepth reports
    ├── multiqc/    # Aggregated MultiQC HTML report
    └── logs/
        ├── execution_timeline.html
        ├── execution_report.html
        ├── execution_trace.txt
        └── pipeline_dag.html
```

### Clinical integrity checks

- **BAM validation:** `samtools quickcheck` before any variant calling step.
- **MD5 checksums:** Generated for all final alignment files.
- **Variant normalisation:** All variants are decomposed, left-aligned, and normalised.
- **Full audit trail:** Nextflow timeline, trace, and DAG are always written to `logs/`.

---

## Benchmarking & Validation

The pipeline is validated against the **Ashkenazim Trio (HG002 / HG003 / HG004)** using NIST v4.2.1 truth sets.

### Test dataset

Validation uses publicly available **Illumina NovaSeq PCR-free 35× chr20 BAMs** from the DeepVariant case-study testdata (Google Cloud Storage) and NIST v4.2.1 truth VCFs from NCBI FTP.

Download all validation data:

```bash
bash deployment/scripts/fetch_validation_data.sh /path/to/output
```

### Running the benchmark

```bash
nextflow run main.nf \
    --input_type bam \
    --run_mode calibration \
    --samplesheet deployment/manifests/trio_bams_chr20.csv \
    -profile singularity
```

### Results — Ashkenazim Trio chr20 (NIST v4.2.1, PASS variants)

DRAGEN-mode HaplotypeCaller benchmarked against NIST v4.2.1 truth set,
Illumina NovaSeq PCR-free 35×, chr20.

#### HG002 (NA24385 — Son)

| Type  | Recall | Precision | F1 Score | TP     | FP | FN  |
|-------|--------|-----------|----------|--------|----|-----|
| SNP   | 0.9956 | 0.9995    | 0.9976   | 71 019 | 33 | 314 |
| INDEL | 0.9942 | 0.9980    | 0.9961   | 11 191 | 23 | 65  |

#### HG003 (NA24149 — Father)

| Type  | Recall | Precision | F1 Score | TP     | FP | FN  |
|-------|--------|-----------|----------|--------|----|-----|
| SNP   | 0.9964 | 0.9993    | 0.9979   | 69 915 | 50 | 251 |
| INDEL | 0.9963 | 0.9985    | 0.9974   | 10 589 | 17 | 39  |

#### HG004 (NA24143 — Mother)

| Type  | Recall | Precision | F1 Score | TP     | FP | FN  |
|-------|--------|-----------|----------|--------|----|-----|
| SNP   | 0.9966 | 0.9990    | 0.9978   | 71 412 | 71 | 247 |
| INDEL | 0.9950 | 0.9978    | 0.9964   | 10 945 | 25 | 55  |

### Full benchmark outputs

| Sample | Summary CSV | Extended CSV | Metrics JSON |
|--------|-------------|--------------|--------------|
| HG002  | [summary](deployment/benchmark/trio_benchmark_results/validation/HG002_happy.output.summary.csv) | [extended](deployment/benchmark/trio_benchmark_results/validation/HG002_happy.output.extended.csv) | [metrics](deployment/benchmark/trio_benchmark_results/validation/HG002_happy.output.metrics.json.gz) |
| HG003  | [summary](deployment/benchmark/trio_benchmark_results/validation/HG003_happy.output.summary.csv) | [extended](deployment/benchmark/trio_benchmark_results/validation/HG003_happy.output.extended.csv) | [metrics](deployment/benchmark/trio_benchmark_results/validation/HG003_happy.output.metrics.json.gz) |
| HG004  | [summary](deployment/benchmark/trio_benchmark_results/validation/HG004_happy.output.summary.csv) | [extended](deployment/benchmark/trio_benchmark_results/validation/HG004_happy.output.extended.csv) | [metrics](deployment/benchmark/trio_benchmark_results/validation/HG004_happy.output.metrics.json.gz) |

---

## Scope Note

This repository covers **short-read (Illumina) germline variant calling**.
A separate pipeline for **PacBio HiFi long-read sequencing with native 5mCpG methylation calling** is under active development and will be linked here upon release.

---

## License & Compliance

Designed for research and clinical validation use. To satisfy IVD reproducibility requirements:

- Version-lock all container images (`core.sif`, `qc.sif`, `happi.sif`, `manta.sif`) in your local registry.
- Preserve the `logs/` directory for each run as your regulatory audit trail.
- Do not modify reference files between validation runs.

---

## Benchmarking & Validation — PacBio HiFi (nf-longread)

Validation of the HiFi long-read pipeline against the **Ashkenazim Trio (HG002 / HG003 / HG004)** using NIST v4.2.1 truth sets.

### Test dataset

PacBio HiFi 2024 Q4 Vega release, chr20, aligned BAM with native MM/ML base modification tags.
Truth VCFs: NIST v4.2.1 GRCh38 (NCBI FTP).

### Results — Ashkenazim Trio chr20 (NIST v4.2.1, PASS variants)

DeepVariant PacBio HiFi model benchmarked against NIST v4.2.1 truth set, chr20.

#### HG002 (NA24385 — Son)

| Type  | Recall | Precision | F1 Score | TP     | FP  | FN  |
|-------|--------|-----------|----------|--------|-----|-----|
| SNP   | 0.9863 | 0.9970    | 0.9916   | 44 439 | 133 | 618 |
| INDEL | 0.9664 | 0.9787    | 0.9725   |  7 417 | 166 | 258 |

#### HG003 (NA24149 — Father)

| Type  | Recall | Precision | F1 Score | TP     | FP  | FN  |
|-------|--------|-----------|----------|--------|-----|-----|
| SNP   | 0.9870 | 0.9985    | 0.9927   | 43 894 |  64 | 579 |
| INDEL | 0.9709 | 0.9850    | 0.9779   |  7 137 | 112 | 214 |

#### HG004 (NA24143 — Mother)

| Type  | Recall | Precision | F1 Score | TP     | FP  | FN  |
|-------|--------|-----------|----------|--------|-----|-----|
| SNP   | 0.9862 | 0.9966    | 0.9914   | 45 141 | 155 | 632 |
| INDEL | 0.9743 | 0.9857    | 0.9800   |  7 319 | 110 | 193 |

### Notes

High QUERY.UNK fraction (~33–52% for INDELs) reflects variants falling outside GIAB v4.2.1 confident regions, which is expected for HiFi data where coverage is more heterogeneous than short-read at chr20. Metrics reported on PASS-filtered variants only. Full hap.py outputs available in `deployment/benchmark/trio_benchmark_results/validation/`.

---

## HiFi Long-Read Benchmarking (nf-longread)

Separate validation for the PacBio HiFi pipeline against NIST v4.2.1 truth sets.

### Results — HG002/HG003/HG004 (NIST v4.2.1, PASS variants, PacBio HiFi)

DeepVariant PacBio HiFi model benchmarked against NIST v4.2.1 truth set, chr20.

#### HG002 (NA24385 — Son)

| Type  | Recall | Precision | F1 Score | TP     | FP  | FN  |
|-------|--------|-----------|----------|--------|-----|-----|
| SNP   | 0.9863 | 0.9970    | 0.9916   | 44 439 | 133 | 618 |
| INDEL | 0.9664 | 0.9787    | 0.9725   |  7 417 | 166 | 258 |

#### HG003 (NA24149 — Father)

| Type  | Recall | Precision | F1 Score | TP     | FP  | FN  |
|-------|--------|-----------|----------|--------|-----|-----|
| SNP   | 0.9870 | 0.9985    | 0.9927   | 43 894 |  64 | 579 |
| INDEL | 0.9709 | 0.9850    | 0.9779   |  7 137 | 112 | 214 |

#### HG004 (NA24143 — Mother)

| Type  | Recall | Precision | F1 Score | TP     | FP  | FN  |
|-------|--------|-----------|----------|--------|-----|-----|
| SNP   | 0.9862 | 0.9966    | 0.9914   | 45 141 | 155 | 632 |
| INDEL | 0.9743 | 0.9857    | 0.9800   |  7 319 | 110 | 193 |

> Benchmark run on PacBio HiFi chr20 data using DeepVariant --model_type PACBIO.
> Higher QUERY.UNK fraction (~33–50%) relative to short-read benchmark reflects
> HiFi coverage heterogeneity outside GIAB confident regions — expected behaviour
> for long-read data and does not affect recall/precision within confident regions.
