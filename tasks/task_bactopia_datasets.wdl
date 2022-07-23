version 1.0

task bactopia_datasets {
    input {
        String species
        Int? limit
        String? dataset_opts
        String docker = "quay.io/bactopia/bactopia-wdl:2.1.1"
        Int cpus=4
    }

    command <<<
      set -x

      # Build datasets
      bactopia datasets ~{'--species "' + species + '"'} ~{'--limit ' + limit} ~{dataset_opts} --cpus ~{cpus}
      tar -cf - datasets/ | gzip -n --best > datasets.tar.gz

      # Gather a few stats
      date | tee DATE
      bactopia --version | sed 's/bactopia //' | tee BACTOPIA_VERSION
    >>>

    output {
        String bactopia_version = read_string("BACTOPIA_VERSION")
        String bactopia_docker = docker
        String build_date = read_string("DATE")
        File datasets = "datasets.tar.gz"
    }

    runtime {
        cpu: cpus
        disks: "local-disk 25 HDD"
        memory: "8 GB"
        docker: "~{docker}"
    }
}
