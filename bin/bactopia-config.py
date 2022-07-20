#! /usr/bin/env python3

import os
import textwrap
print(textwrap.dedent(f"""
    process {{
        // Defaults
        cpus = {{params.max_cpus}}
        memory = {{16.GB * task.attempt}}
        time = {{60.m * task.attempt}}
        errorStrategy = 'retry'

        // single cpus
        withLabel: max_cpus_1 {{
            cpus = {{check_max('request', RESOURCES.MAX_CPUS, 'cpus')}}
        }}

        // 75% cpus
        withLabel: max_cpu_75 {{
            cpus = {{check_max('request', RESOURCES.MAX_CPUS, 'cpus' )}}
        }}

        // Half cpus
        withLabel: max_cpu_50 {{
            cpus = {{check_max('request', RESOURCES.MAX_CPUS, 'cpus' )}}
        }}

        // Memory defaults
        withLabel: base_mem_4gb {{
            memory = {{check_max(16.GB * task.attempt, RESOURCES.MAX_MEMORY, 'memory' )}}
        }}

        withLabel: base_mem_8gb {{
            memory = {{check_max(16.GB * task.attempt, RESOURCES.MAX_MEMORY, 'memory' )}}
        }}

        // Process specific
        withLabel: 'assemble_genome' {{
            memory = {{check_max((32.GB * task.attempt), RESOURCES.MAX_MEMORY, 'memory')}}
            time = {{check_max( 2.h * task.attempt, (params.max_time).m, 'time' )}}
        }}

        withLabel: 'gather_samples' {{
            maxForks = 1
            maxRetries = 20
        }}

        // Modules imported from nf-core
        withLabel: process_low {{
            cpus = {{check_max('request', RESOURCES.MAX_CPUS, 'cpus')}}
            memory = {{check_max(16.GB * task.attempt, RESOURCES.MAX_MEMORY, 'memory' )}}
            time = {{check_max( 2.h * task.attempt, 2.h * task.attempt, 'time' )}}
        }}
        withLabel: process_medium {{
            cpus = {{check_max('request', RESOURCES.MAX_CPUS, 'cpus')}}
            memory = {{check_max(32.GB * task.attempt, RESOURCES.MAX_MEMORY, 'memory' )}}
            time = {{check_max( 12.h * task.attempt, 12.h * task.attempt, 'time' )}}
        }}
        withLabel: process_high {{
            cpus = {{check_max('request', RESOURCES.MAX_CPUS, 'cpus')}}
            memory = {{check_max(64.GB * task.attempt, RESOURCES.MAX_MEMORY, 'memory' )}}
            time = {{check_max( 24.h * task.attempt, 24.h * task.attempt, 'time' )}}
        }}
        withLabel: process_long {{
            time = {{check_max( 96.h * task.attempt, 96.h * task.attempt, 'time' )}}
        }}
        withLabel: process_high_memory {{
            memory = {{check_max(128.GB * task.attempt, RESOURCES.MAX_MEMORY, 'memory' )}}
        }}
        withLabel: error_ignore {{
            errorStrategy = 'ignore'
        }}
        withLabel: error_retry {{
            errorStrategy = 'retry'
            maxRetries    = 2
        }}
    }}


    profiles {{
        terra {{
            process {{
                executor = 'google-lifesciences'
            }}
            
            google {{
                google.region = 'us-central1'
                google.project = '{os.getenv('GOOGLE_PROJECT')}'
                google.lifeSciences.debug = true
                google.lifeSciences.serviceAccountEmail = "{os.getenv('PET_SA_EMAIL')}"
                google.lifeSciences.usePrivateAddress = false
                google.lifeSciences.copyImage = "gcr.io/google.com/cloudsdktool/cloud-sdk:alpine"
                google.lifeSciences.bootDiskSize = '50.GB'
                google.lifeSciences.preemptible = true
                google.lifeSciences.network = "/projects/{os.getenv('GOOGLE_PROJECT')}/global/networks/network"
                google.lifeSciences.subnetwork = "/projects/{os.getenv('GOOGLE_PROJECT')}/regions/us-central1/subnetworks/subnetwork"
            }}

            workDir = '{os.getenv('NXF_WORK')}'
        }}
    }}
"""
))
