version 1.0

import "../tasks/task_bactopia_search.wdl" as search

workflow bactopia_search {
    meta {
        description: "A flexible pipeline for complete analysis of bacterial genomes"
        doi: "10.1128/mSystems.00190-20"
        author: "Robert A. Petit III"
        email:  "robert.petit@theiagen.com"
    }

    input {
        File? accessions
        String? query
        String? prefix
        Int? limit
        Int? min_read_length
        Int? min_base_count
        String? search_opts
    }

    call search.bactopia_search {
        input:
            query = query,
            accessions = accessions,
            prefix = prefix,
            limit = limit,
            min_read_length = min_read_length,
            min_base_count = min_base_count,
            search_opts = search_opts
    }

    output {
        String bactopia_version = search.bactopia_version
        String bactopia_docker = search.bactopia_docker
        String query_date = search.query_date
        String query = search.query_term
        Int total_accessions = search.total_accessions
        File accessions = search.accessions
        File filtered = search.filtered
        File metadata = search.metadata
        File summary = search.summary
    }
}
