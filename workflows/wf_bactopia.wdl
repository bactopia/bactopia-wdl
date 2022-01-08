version 1.0

import "../tasks/task_bactopia.wdl" as bactopia_nf

workflow bactopia {
    input {
        File    r1
        File    r2
        String  sample_name
        Boolean ont
    }

    call bactopia_nf.bactopia {
        input:
            r1 = r1,
            r2 = r2,
            sample_name = sample_name,
            ont = ont
    }

    output {
        File assembly = bactopia.assembly
        File versions = bactopia.versions
    }
}
