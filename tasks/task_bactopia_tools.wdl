version 1.0

task bactopia_tools {
    input {
        # Inputs
        String bactopia_tool
        Array[File]+ bactopia_results

        # Optional inputs
        File? nf_config
        String? bactopia_opts

        String docker="quay.io/bactopia/bactopia-wdl:2.1.1"
    }

    parameter_meta {
        bactopia_tool:    { description: "The Bactopia Tool to be executed (--wf <TOOL_NAME>)" }
        bactopia_results: { description: "Tarballs with Bactopia outputs" }
        nf_config:        { description: "A user provided Nextflow config file" }
        bactopia_opts:    { description: "Additional options to provided to fine tune your analysis" }
    }

    command <<<
        set -x
        date | tee DATE
        bactopia --version | sed 's/bactopia //' | tee BACTOPIA_VERSION

        # Setup env variables to allow Nextflow to use Google Life Sciences
        export GOOGLE_REGION=$(basename $(curl --silent -H "Metadata-Flavor: Google" metadata/computeMetadata/v1/instance/zone 2> /dev/null) | cut -d "-" -f1-2)
        export GOOGLE_PROJECT=$(gcloud config get-value project)
        export PET_SA_EMAIL=$(gcloud config get-value account)
        export WORKSPACE_BUCKET=$(gsutil ls | grep "gs://fc-" | head  -n1 | sed 's=gs://==; s=/$==')
        export NXF_WORK="gs://${WORKSPACE_BUCKET}/nextflow-work/${HOSTNAME}"
        
        if [ ! -d "/cromwell_root/${WORKSPACE_BUCKET}" ]; then
            # This should not happen, but just in case...
            echo "/cromwell_root/${WORKSPACE_BUCKET} does not exist, exiting"
            exit 42
        fi

        # Setup inputs
        bactopia_array=(~{sep=' ' bactopia_results})
        for index in ${!bactopia_array[@]}; do
            tar -xvf ${bactopia_array[$index]}
        done

        # Create Config
        bactopia-config.py > bactopia-terra.config

        # Run Bactopia
        EXIT_CODE=0
        if bactopia --wf ~{bactopia_tool} --bactopia bactopia -profile docker,terra --nfconfig bactopia-terra.config -w ${NXF_WORK} ~{"-c " + nf_config} ~{bactopia_opts}; then
            # Everything finished, pack up the results and clean up
            rm -rf .nextflow/ work/
            tar -cf - bactopia-tools/ | gzip -n --best > ~{bactopia_tool}.tar.gz
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
        File versions = "bactopia-tools/~{bactopia_tool}/~{bactopia_tool}/software_versions.yml"
        File nextflow_log = "bactopia/.nextflow.log"
        File full_results  = "~{bactopia_tool}.tar.gz"
    }

    runtime {
        cpu: 2
        disks: "local-disk 30 HDD"
        docker: "~{docker}"
        memory: "4 GB"
        maxRetries: 3
    }
}
