version 1.0

import "../tasks/task_bactopia_search.wdl" as task_bactopia_search

workflow bactopia_search {
    meta {
        description: "A flexible pipeline for complete analysis of bacterial genomes"
        doi: "10.1128/mSystems.00190-20"
        author: "Robert A. Petit III"
        email:  "robert.petit@theiagen.com"
    }

    input {
        File? accession_list
        String? search_term
    }

    call task_bactopia_search.bactopia_search as search {
        input:
            search_term = search_term,
            accession_list = accession_list
    }

    output {
        String bactopia_version = search.bactopia_version
        String bactopia_docker = search.bactopia_docker
        String query_date = search.query_date
        String query = search.query
        Int total_accessions = search.total_accessions
        File accessions = search.accessions
        File filtered = search.filtered
        File metadata = search.metadata
        File summary = search.summary
    }
}
