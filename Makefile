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
QC_SIF    := ${DEPLOYMENT_DIR}/singularity/sif/qc.sif
HAPPY_SIF := ${DEPLOYMENT_DIR}/singularity/sif/happi.sif
VEP_SIF := ${DEPLOYMENT_DIR}/singularity/sif/vep115.sif
SPLICEAI_SIF := ${DEPLOYMENT_DIR}/singularity/sif/spliceai.sif
DEEPVARIANT_SIF := ${DEPLOYMENT_DIR}/singularity/sif/deepvariant.sif
DEEPVARIANT_GPU_SIF := ${DEPLOYMENT_DIR}/singularity/sif/deepvariant_gpu.sif
GLNEXUS_SIF := ${DEPLOYMENT_DIR}/singularity/sif/glnexus.sif

HAPPY_DOCKER := docker://mgibio/hap.py:v0.3.12
DEEPVARIANT_DOCKER := docker://google/deepvariant:1.5.0
DEEPVARIANT_GPU_DOCKER := docker://google/deepvariant:1.5.0-gpu

# ── Fasta ───────────────────────────────────────────────────────

FASTA_URL := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta
FAI_URL := https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.fai

########################################################

.PHONY: setup containers fasta benchmark_download run_benchmark clean

setup: containers fasta

benchmark: benchmark_download run_benchmark

# ── Containers ────────────────────────────────────────────────────────────────
containers: $(CORE_SIF) $(QC_SIF) $(HAPPY_SIF) $(DEEPVARIANT_SIF) $(DEEPVARIANT_GPU_SIF) $(GLNEXUS_SIF) $(VEP_SIF)

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

$(DEEPVARIANT_SIF):
	$(SINGULARITY) build --disable-cache $@ $(DEEPVARIANT_DOCKER)

$(DEEPVARIANT_GPU_SIF):
	$(SINGULARITY) build --disable-cache $@ $(DEEPVARIANT_GPU_DOCKER)

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
		pbmm2 index $(FASTA_DIR)/Homo_sapiens_assembly38.fasta $(FASTA_DIR)/Homo_sapiens_assembly38.fasta.mmi

benchmark_download:
	$(SINGULARITY) run $(CORE_SIF) bash ${DEPLOYMENT_DIR}/scripts/GiAB_download.sh $(BENCHMARK_DIR) chr22
	
	# Download chr22 reference and build mmi index
	$(SINGULARITY) run $(CORE_SIF) \
		samtools faidx $(FASTA_URL) chr22 > $(FASTA_DIR)/chr22_Homo_sapiens_assembly38.fasta
	$(SINGULARITY) run $(CORE_SIF) \
		samtools faidx $(FASTA_DIR)/chr22_Homo_sapiens_assembly38.fasta
    
	$(SINGULARITY) run $(CORE_SIF) \
		pbmm2 index $(FASTA_DIR)/chr22_Homo_sapiens_assembly38.fasta $(FASTA_DIR)/chr22_Homo_sapiens_assembly38.fasta.mmi

run_benchmark:
	mkdir -p "${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results/logs"
	nextflow -log "${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results/logs/nextflow.log" run main.nf \
		--input_type ubam \
		--run_mode DV,SV,PHASE,METHYLATION \
		-profile singularity \
		--singularity_path ${DEPLOYMENT_DIR}/singularity/sif \
		--samplesheet ${DEPLOYMENT_DIR}/benchmark/benchmark_manifest_ubam.csv \
		--outfolder ${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results \
		--runID test_run \
		-resume \
		-w ${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results/work \
		--seq_type PACBIO \
		--fasta $(FASTA_DIR)/chr22_Homo_sapiens_assembly38.fasta \
		--annotate false

validate:
	bash ${DEPLOYMENT_DIR}/scripts/validate.sh ${DEPLOYMENT_DIR} chr22

# ── Clean ─────────────────────────────────────────────────────────────────────
clean:
	rm -rf ${DEPLOYMENT_DIR}/benchmark/trio_benchmark_results ${DEPLOYMENT_DIR}/benchmark/bams ${DEPLOYMENT_DIR}/reference logs ${DEPLOYMENT_DIR}/singularity/sif/*.sif