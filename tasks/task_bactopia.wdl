version 1.0

task bactopia {
    input {
        File    r1
        File?   r2
        String  sample_name
        File?   nf_config
        Boolean ont=false
        String docker="quay.io/bactopia/bactopia-wdl:2.1.1"
        String? bactopia_opts
    }

    command <<<
        set -x
        # Setup env variables
        basename $(curl --silent -H "Metadata-Flavor: Google" metadata/computeMetadata/v1/instance/zone) 2> /dev/null > zone.txt
        export GOOGLE_REGION=$(gcloud compute zones list | grep -f zone.txt | awk '{print $2}')
        export GOOGLE_PROJECT=$(gcloud config get-value project)
        export PET_SA_EMAIL=$(gcloud config get-value account)
        export WORKSPACE_BUCKET=$(gsutil ls | grep "gs://fc-" | head  -n1 | sed 's=gs://==')
        export EXPECTED_BUCKET=$(basename $(direname ~{r1}))
        env
        
        if [ "${WORKSPACE_BUCKET}" != "${EXPECTED_BUCKET}" ]; then
            echo "Bucket mismatch: ${WORKSPACE_BUCKET} != ${EXPECTED_BUCKET}"
            exit 1
        fi
        
        date | tee DATE
        bactopia --version | sed 's/bactopia //' | tee BACTOPIA_VERSION

        BACTOPIA_READS=""
        if [ -z ~{r2} ]; then
            if [ "${ont}" == "true" ]; then
                # Nanopore reads
                BACTOPIA_READS="--SE ~{r1} --ont"
            else
                # Single end reads
                BACTOPIA_READS="--SE ~{r1}"
            fi
        else
            # Paired end reads
            BACTOPIA_READS="--R1 ~{r1} --R2 ~{r2}"
        fi

        # Run Bactopia
        mkdir bactopia
        cd bactopia
        if bactopia $BACTOPIA_READS --sample ~{sample_name} --max_cpus 8 --skip_qc_plots ~{"-c " + nf_config} ~{bactopia_opts}; then
            # Everything finished, pack up the results and clean up
            rm -rf .nextflow/ work/
            cd ..
            tar -cf - bactopia/ | gzip -n --best  > ~{sample_name}.tar.gz

            # Gather metrics
            bactopia-stats.py bactopia/~{sample_name}/ ~{sample_name}
        else
            # Run failed
            exit 1
        fi
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
        File full_results  = "~{sample_name}.tar.gz"
    }

    runtime {
        docker: "~{docker}"
        memory: "16 GB"
        disks:  "local-disk 50 LOCAL"
        maxRetries: 3
    }
}
