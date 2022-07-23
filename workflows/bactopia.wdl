version 1.0

import "../tasks/task_bactopia.wdl" as bactopia_task

workflow bactopia {
    meta {
        description: "A flexible pipeline for complete analysis of bacterial genomes"
        doi: "10.1128/mSystems.00190-20"
        author: "Robert A. Petit III"
        email:  "robert.petit@theiagen.com"
    }

    input {
        String sample_name
        File? r1
        File? r2
        Boolean? is_accession
    }

    if (defined(r1) || defined(is_accession)) {
      call bactopia_task.bactopia as bactopia_nf {
          input:
              sample_name = sample_name,
              r1 = r1,
              r2 = r2,
              is_accession = is_accession
      }
    }

    output {
        String bactopia_version = bactopia_nf.bactopia_version
        String bactopia_docker = bactopia_nf.bactopia_docker
        String analysis_date = bactopia_nf.analysis_date
        File versions = bactopia_nf.versions
        Boolean is_paired = bactopia_nf.is_paired
        Int genome_size = bactopia_nf.genome_size
        Int qc_total_bp = bactopia_nf.qc_total_bp
        Float qc_coverage = bactopia_nf.qc_coverage
        Int qc_read_total = bactopia_nf.qc_read_total
        Float qc_read_mean = bactopia_nf.qc_read_mean
        Float qc_qual_mean = bactopia_nf.qc_qual_mean
        Int raw_total_bp = bactopia_nf.raw_total_bp
        Float raw_coverage = bactopia_nf.raw_coverage
        Int raw_read_total = bactopia_nf.raw_read_total
        Float raw_read_mean = bactopia_nf.raw_read_mean
        Float raw_qual_mean = bactopia_nf.raw_qual_mean
        Array[File] reads = bactopia_nf.reads
        File assembly = bactopia_nf.assembly
        Int total_contig = bactopia_nf.total_contig
        Int total_contig_length = bactopia_nf.total_contig_length
        Int max_contig_length = bactopia_nf.max_contig_length
        Int mean_contig_length = bactopia_nf.mean_contig_length
        Int n50_contig_length = bactopia_nf.n50_contig_length
        Float gc_percent = bactopia_nf.gc_percent
        File genes = bactopia_nf.genes
        File proteins = bactopia_nf.proteins
        File full_results = bactopia_nf.full_results
    }
}
