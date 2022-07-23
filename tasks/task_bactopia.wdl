version 1.0

task bactopia {
    input {
        # Inputs
        String   sample_name
        File?    r1
        File?    r2
        Boolean? is_accession

        # Optional inputs
        Boolean? is_ont=false
        File? nf_config
        File? datasets
        String? species
        String? gsize
        String? bactopia_opts

        String docker="quay.io/bactopia/bactopia-wdl:2.1.1"
    }

    parameter_meta {
        sample_name:   { description: "The input sample name or Experiment accession" }
        r1:            { description: "FASTQ file, can be Illumina R1/single-end, or Nanopore reads" }
        r2:            { description: "Other FASTQ file for paired-end reads" }
        is_accession:  { description: "The provided sample name is an Experiment accession" }
        is_ont:        { description: "The input reads (r1) are Nanopore reads" }
        nf_config:     { description: "A user provided Nextflow config file" }
        datasets:      { description: "Pre-built datasets to be used to supplement analyses" }
        species:       { description: "A species (or genus) name for the pre-built datasets" }
        gsize:         { description: "A genome size to be used for estimates. If datasets and organism is provided 'median' will be used" }
        bactopia_opts: { description: "Additional options to provided to fine tune your analysis" }
    }

    command <<<
        date | tee DATE
        bactopia --version | sed 's/bactopia //' | tee BACTOPIA_VERSION

        # Setup env variables to allow Nextflow to use Google Life Sciences
        export GOOGLE_REGION=$(basename $(curl --silent -H "Metadata-Flavor: Google" metadata/computeMetadata/v1/instance/zone 2> /dev/null) | cut -d "-" -f1-2)
        export GOOGLE_PROJECT=$(gcloud config get-value project)
        export PET_SA_EMAIL=$(gcloud config get-value account)
        export WORKSPACE_BUCKET=$(gsutil ls | grep "gs://fc-" | head  -n1 | sed 's=gs://==; s=/$==')
        export NXF_WORK="gs://${WORKSPACE_BUCKET}/nextflow-work/${HOSTNAME}"
        export EXPECTED_BUCKET=$(basename $(dirname ~{r1}))
        
        if [ "${WORKSPACE_BUCKET}" != "${EXPECTED_BUCKET}" ]; then
            # This should not happen, but just in case...
            echo "Bucket mismatch: ${WORKSPACE_BUCKET} != ${EXPECTED_BUCKET}"
            exit 42
        fi

        # Setup inputs
        BACTOPIA_INPUT=""
        if [ ~{true='true' false='false' is_accession} == "true" ]; then
            # Treat as Experiment accession
            BACTOPIA_INPUT="--accession ~{sample_name}"
        elif [ -f "${r2}" ]; then
            # Paired end reads
            BACTOPIA_INPUT="--R1 ~{r1} --R2 ~{r2} --sample ~{sample_name}"
        else
            if [ "~{is_ont}" == "true" ]; then
                # Nanopore reads
                BACTOPIA_INPUT="--SE ~{r1} --ont --sample ~{sample_name}"
            else
                # Single end reads
                BACTOPIA_INPUT="--SE ~{r1} --sample ~{sample_name}"
            fi
        fi

        # Setup datasets
        BACTOPIA_DATASETS=""
        HAS_SPECIES=0
        if [ -f ~{datasets} ]; then
            tar -xzf ~{datasets}
            if [ -n "~{species}" ]; then
                BACTOPIA_DATASETS="--datasets datasets/ --species ~{species}"
                HAS_SPECIES=1
            else
                BACTOPIA_DATASETS="--datasets datasets/"
            fi
        fi

        # Setup genome size
        BACTOPIA_GSIZE=""
        if [ -z "~{gsize}" ]; then
            if [ ${HAS_SPECIES} == 1 ]; then
                BACTOPIA_GSIZE="--genome_size median"
            fi
        else
            BACTOPIA_GSIZE="--genome_size ~{gsize}"
        fi

        # Create Config
        bactopia-config.py > bactopia-terra.config

        # Run Bactopia
        EXIT_CODE=0
        mkdir bactopia
        cd bactopia
        if bactopia ${BACTOPIA_INPUT} ${BACTOPIA_DATASETS} ${BACTOPIA_GSIZE} -profile docker,terra --nfconfig ../bactopia-terra.config -w ${NXF_WORK} ~{"-c " + nf_config} ~{bactopia_opts}; then
            # Everything finished, pack up the results and clean up
            rm -rf .nextflow/ work/
            cd ..
            tar -cf - bactopia/ | gzip -n --best > ~{sample_name}.tar.gz

            # Gather metrics
            bactopia-stats.py bactopia/~{sample_name}/ ~{sample_name}
        else
            # Run failed
            cat .nextflow.log
            EXIT_CODE=40
        fi

        # Clean up workdir (prevent pileup in bucket)
        gsutil rm ${NXF_WORK}

        # Exit
        exit ${EXIT_CODE}
    >>>

    output {
        String bactopia_version = read_string("BACTOPIA_VERSION")
        String bactopia_docker = docker
        String analysis_date = read_string("DATE")
        File versions = "bactopia/software_versions.yml"
        Boolean is_paired = read_boolean("IS_PAIRED")
        Int genome_size = read_int("GENOME_SIZE")
        Int qc_total_bp = read_int("QC_TOTAL_BP")
        Float qc_coverage = read_float("QC_COVERAGE")
        Int qc_read_total = read_int("QC_READ_TOTAL")
        Float qc_read_mean = read_float("QC_READ_MEAN")
        Float qc_qual_mean = read_float("QC_QUAL_MEAN")
        Int raw_total_bp = read_int("RAW_TOTAL_BP")
        Float raw_coverage = read_float("RAW_COVERAGE")
        Int raw_read_total = read_int("RAW_READ_TOTAL")
        Float raw_read_mean = read_float("RAW_READ_MEAN")
        Float raw_qual_mean = read_float("RAW_QUAL_MEAN")
        Array[File] reads = glob("bactopia/~{sample_name}/quality-control/*.fastq.gz")
        File assembly = "bactopia/~{sample_name}/assembly/~{sample_name}.fna.gz"
        Int total_contig = read_int("TOTAL_CONTIG")
        Int total_contig_length = read_int("TOTAL_CONTIG_LENGTH")
        Int max_contig_length = read_int("MAX_CONTIG_LENGTH")
        Int mean_contig_length = read_int("MEAN_CONTIG_LENGTH")
        Int n50_contig_length = read_int("N50_CONTIG_LENGTH")
        Float gc_percent = read_float("GC_PERCENT")
        File genes = "bactopia/~{sample_name}/annotation/~{sample_name}.ffn.gz"
        File proteins = "bactopia/~{sample_name}/annotation/~{sample_name}.faa.gz"
        File nextflow_log = "bactopia/.nextflow.log"
        File full_results  = "~{sample_name}.tar.gz"
    }

    runtime {
        cpu: 2
        disks: "local-disk 30 HDD"
        docker: "~{docker}"
        memory: "4 GB"
        maxRetries: 3
    }
}
