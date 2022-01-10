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
        String bactopia_version = bactopia.bactopia_version
        String bactopia_docker = bactopia.bactopia_docker
        String analysis_date = bactopia.analysis_date
        File versions = bactopia.versions
        Boolean is_paired = bactopia.is_paired
        Int genome_size = bactopia.genome_size
        Int qc_total_bp = bactopia.qc_total_bp
        Float qc_coverage = bactopia.qc_coverage
        Int qc_read_total = bactopia.qc_read_total
        Float qc_read_mean = bactopia.qc_read_mean
        Float qc_qual_mean = bactopia.qc_qual_mean
        Int raw_total_bp = bactopia.raw_total_bp
        Float raw_coverage = bactopia.raw_coverage
        Int raw_read_total = bactopia.raw_read_total
        Float raw_read_mean = bactopia.raw_read_mean
        Float raw_qual_mean = bactopia.raw_qual_mean
        Array[File] reads = bactopia.reads
        File assembly = bactopia.assembly
        Int total_contig = bactopia.total_contig
        Int total_contig_length = bactopia.total_contig_length
        Int max_contig_length = bactopia.max_contig_length
        Int mean_contig_length = bactopia.mean_contig_length
        Int n50_contig_length = bactopia.n50_contig_length
        Float gc_percent = bactopia.gc_percent
        File genes = bactopia.genes
        File proteins = bactopia.proteins
        File full_results = bactopia.full_results
    }
}
