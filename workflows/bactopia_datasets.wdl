version 1.0

import "../tasks/task_bactopia_datasets.wdl" as task_bactopia_datasets

workflow bactopia_datasets {
    meta {
        description: "A flexible pipeline for complete analysis of bacterial genomes"
        doi: "10.1128/mSystems.00190-20"
        author: "Robert A. Petit III"
        email:  "robert.petit@theiagen.com"
    }

    input {
        String species
    }

    call task_bactopia_datasets.bactopia_datasets as dataset {
        input:
            species = species
    }

    output {
        String bactopia_version = dataset.bactopia_version
        String bactopia_docker = dataset.bactopia_docker
        String build_date = dataset.build_date
        File datasets = dataset.datasets
    }
}
