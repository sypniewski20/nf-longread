SINGULARITY ?= singularity
GSUTIL      ?= gsutil
WGET		?= wget

# ── Dirs ──────────────────────────────────────────────────────────────────────
DEPLOYMENT_DIR := deployment
REF_DIR    := ${DEPLOYMENT_DIR}/reference
FASTA_DIR  := $(REF_DIR)/fasta
ADD_RESOURCES    := $(REF_DIR)/additional_resources
BENCHMARK_DIR := ${DEPLOYMENT_DIR}/benchmark

# ── Manifests ─────────────────────────────────────────────────────────────────
FASTA_MANIFEST := ${DEPLOYMENT_DIR}/manifests/fasta_manifest.csv

# ── Images ────────────────────────────────────────────────────────────────────

CORE_SIF  := ${DEPLOYMENT_DIR}/singularity/sif/core.sif
HAPPY_SIF := ${DEPLOYMENT_DIR}/singularity/sif/happi.sif
VEP_SIF := ${DEPLOYMENT_DIR}/singularity/sif/vep115.sif
SPLICEAI_SIF := ${DEPLOYMENT_DIR}/singularity/sif/spliceai.sif
DEEP_VARIANT_SIF := ${DEPLOYMENT_DIR}/singularity/sif/deepvariant.sif
GLNEXUS_SIF := ${DEPLOYMENT_DIR}/singularity/sif/glnexus.sif

HAPPY_DOCKER := docker://mgibio/hap.py:v0.3.12
DEEP_VARIANT_DOCKER := docker://google/deepvariant:1.5.0

# ── Fasta ───────────────────────────────────────────────────────

FASTA_URL := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta
FAI_URL := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.fai

########################################################

.PHONY: setup containers fasta benchmark_download run_benchmark clean

setup: containers fasta

benchmark: benchmark_download run_benchmark

# ── Containers ────────────────────────────────────────────────────────────────
containers: $(CORE_SIF) $(QC_SIF) $(HAPPY_SIF) $(DEEP_VARIANT_SIF) $(GLNEXUS_SIF) $(VEP_SIF)

$(CORE_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/core.def

$(QC_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/qc.def

$(HAPPY_SIF):
	$(SINGULARITY) build --disable-cache $@ $(HAPPY_DOCKER)

$(VEP_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/vep115.def

$(SPLICEAI_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/spliceai.def

$(DEEP_VARIANT_SIF):
	$(SINGULARITY) build --disable-cache $@ $(DEEP_VARIANT_DOCKER)

$(GLNEXUS_SIF):
	$(SINGULARITY) build --fakeroot $@ ${DEPLOYMENT_DIR}/singularity/def/glnexus.def



# ── References ────────────────────────────────────────────────────────────────

fasta:
	mkdir -p $(FASTA_DIR)
	
	# Download references
	$(WGET) --no-clobber -P $(FASTA_DIR) $(FASTA_URL)
	$(WGET) --no-clobber -P $(FASTA_DIR) $(FAI_URL)

	# Build pbmm2 index
	$(SINGULARITY) run $(CORE_SIF) \
		pbmm2 index $(FASTA_DIR)/Homo_sapiens_assembly38.fasta $(FASTA_DIR)/Homo_sapiens_assembly38.mmi

benchmark_download:
	bash ${DEPLOYMENT_DIR}/scripts/GiAB_download.sh $(BENCHMARK_DIR)

run_benchmark:
	mkdir -p "${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results/logs"
	nextflow -log "${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results/logs/nextflow.log" run main.nf \
		--input_type bam \
		--run_mode DV,SV \
		-profile singularity \
		--singularity_path ${DEPLOYMENT_DIR}/singularity/sif \
		--samplesheet ${DEPLOYMENT_DIR}/benchmark/benchmark_manifest.csv \
		--outfolder ${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results \
		--runID test_run \
		-resume \
		-w ${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results/work \
		--seq_type PACBIO \
		--fasta ${DEPLOYMENT_DIR}/reference/fasta/Homo_sapiens_assembly38.fasta \
		--annotate false

validate:
	bash ${DEPLOYMENT_DIR}/scripts/validate.sh ${DEPLOYMENT_DIR}

# ── Clean ─────────────────────────────────────────────────────────────────────
clean:
	rm -rf ${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results reference logs singularity/*.sif