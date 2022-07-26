version 1.0

import "../tasks/task_bactopia_tools.wdl" as bactopia_tools_task

workflow bactopia {
    meta {
        description: "A flexible pipeline for complete analysis of bacterial genomes"
        doi: "10.1128/mSystems.00190-20"
        author: "Robert A. Petit III"
        email:  "robert.petit@theiagen.com"
    }

    input {
        String bactopia_tool
        Array[File] bactopia_results
    }

    call bactopia_tools_task.bactopia_tools as bactopia_tools_nf {
        input:
            bactopia_tool = bactopia_tool,
            bactopia_results = bactopia_results
    }

    output {
        String? bactopia_version = bactopia_tools_nf.bactopia_version
        String? bactopia_docker = bactopia_tools_nf.bactopia_docker
        String? analysis_date = bactopia_tools_nf.analysis_date
        File? versions = bactopia_tools_nf.versions
        File? full_results = bactopia_tools_nf.full_results
    }
}
