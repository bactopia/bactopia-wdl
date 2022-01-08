version 1.0

task bactopia {
    input {
        File    r1
        File?   r2
        String  sample_name
        Boolean ont=false
    }

  command {
    BACTOPIA_READS=""
    if [ -z ${r2} ]; then
        if [ "${ont}" == "true" ]; then
            # Nanopore reads
            BACTOPIA_READS="--SE ${r1} --ont"
        else
            # Single end reads
            BACTOPIA_READS="--SE ${r1}"
        fi
    else
        # Paired end reads
        BACTOPIA_READS="--R1 ${r1} --R2 ${r2}"
    fi

    bactopia $BACTOPIA_READS --sample ${sample_name} --skip_qc_plots
  }

  output {
    File assembly = "${sample_name}/assembly/${sample_name}.fna.gz"
    File versions = "software_versions.yml"
  }

  runtime {
    docker: "quay.io/bactopia/bactopia-wdl:2.0.1"
    memory: "16 GB"
    disks:  "local-disk 50 LOCAL"
    maxRetries: 3
  }
}
