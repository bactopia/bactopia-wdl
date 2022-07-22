version 1.0

task bactopia_search {
    input {
        File?   accessions
        String? query
        String? prefix = "bactopia"
        Int? limit
        Int? min_read_length
        Int? min_base_count
        String? search_opts
        String docker = "quay.io/bactopia/bactopia-wdl:2.1.1"
    }

    command <<<
        set -x
        # Setup env variables
        date | tee DATE
        bactopia --version | sed 's/bactopia //' | tee BACTOPIA_VERSION

        QUERY=""
        if [ -z ~{accessions} ]; then
            QUERY="~{query}"
        else
            # query is a file of accessions
            QUERY="~{accessions}"
        fi

        # Query and gather a few stats
        bactopia search ${QUERY} --prefix ~{prefix} ~{"-limit " + limit} ~{"--min_read_length " + min_read_length} ~{"--min_base_count " + min_base_count} ~{search_opts}
        wc -l bactopia-accessions.txt | tee TOTAL_ACCESSIONS
        grep "QUERY" bactopia-summary.txt | sed 's/QUERY: //' | tee QUERY
    >>>

    output {
        String bactopia_version = read_string("BACTOPIA_VERSION")
        String bactopia_docker = docker
        String query_date = read_string("DATE")
        String query = read_string("QUERY")
        Int total_accessions = read_int("TOTAL_ACCESSIONS")
        Int qc_total_bp = read_int("QC_TOTAL_BP")
        File accessions = "~{prefix}-accessions.txt"
        File filtered = "~{prefix}-filtered.txt"
        File metadata = "~{prefix}-results.txt"
        File summary = "~{prefix}-summary.txt"
    }

    runtime {
        cpu: 1
        disks: "local-disk 10 HDD"
        memory: "1 GB"
        docker: "~{docker}"
    }
}
