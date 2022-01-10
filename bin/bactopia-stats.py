#! /usr/bin/env python3
"""
usage: bactopia-stats [-h] STR STR

bactopia-stats - Ouput files to be used by Bactopia-WDL

positional arguments:
  STR         Directory where Bactopia outputs are.
  STR         Sample name used in Bactopia run

optional arguments:
  -h, --help  show this help message and exit
"""
import os
import json
import sys

PROGRAM = "bactopia-stats"
DESCRIPTION = 'Ouput files to be used by Bactopia-WDL'

def read_json(json_file):
    """ Read input JSON file and return the dict. """
    json_data = None
    with open(json_file, 'rt') as json_fh:
        json_data = json.load(json_fh)
    return json_data

def write_output(file_name, output):
    """ Write the output to a specific file. """
    with open(file_name, 'wt') as file_fh:
        if isinstance(output, float):
            # Limit it two decimal places
            file_fh.write(f'{output:.2f}\n')
        elif isinstance(output, bool):
            val = 'true' if output else 'false'
            file_fh.write(f'{val}\n')
        else:
            file_fh.write(f'{output}\n')

if __name__ == '__main__':
    import argparse as ap
    import textwrap

    parser = ap.ArgumentParser(
        prog=PROGRAM,
        conflict_handler='resolve',
        description=(
            f'{PROGRAM} - {DESCRIPTION}'
        ),
        formatter_class=ap.RawDescriptionHelpFormatter
    )
    parser.add_argument('bactopia', metavar="STR", type=str,
                        help='Directory where Bactopia outputs are.')
    parser.add_argument('sample_name', metavar="STR", type=str,
                        help='Sample name used in Bactopia run')

    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(0)

    args = parser.parse_args()

    with open(f'{args.bactopia}/{args.sample_name}-genome-size.txt', 'rt') as file_fh:
        write_output("GENOME_SIZE", file_fh.readline().rstrip())

    # FASTQ Stats
    is_paired = True if os.path.exists(f'{args.bactopia}/quality-control/{args.sample_name}_R1.fastq.gz') else False
    write_output("IS_PAIRED", is_paired)
    read_stats = {}
    if (is_paired):
        r1_raw_stats = assembly_stats = read_json(f'{args.bactopia}/quality-control/summary/{args.sample_name}_R1-original.json')
        r2_raw_stats = assembly_stats = read_json(f'{args.bactopia}/quality-control/summary/{args.sample_name}_R2-original.json')
        r1_qc_stats = assembly_stats = read_json(f'{args.bactopia}/quality-control/summary/{args.sample_name}_R1-final.json')
        r2_qc_stats = assembly_stats = read_json(f'{args.bactopia}/quality-control/summary/{args.sample_name}_R2-final.json')
        # Original Reads
        write_output("RAW_TOTAL_BP", r1_raw_stats['qc_stats']['total_bp'] + r2_raw_stats['qc_stats']['total_bp'])
        write_output("RAW_COVERAGE", r1_raw_stats['qc_stats']['coverage'] + r2_raw_stats['qc_stats']['coverage'])
        write_output("RAW_READ_TOTAL", r1_raw_stats['qc_stats']['read_total'] + r2_raw_stats['qc_stats']['read_total'])
        write_output("RAW_READ_MEAN", (r1_raw_stats['qc_stats']['read_mean'] + r2_raw_stats['qc_stats']['read_mean']) / 2.0)
        write_output("RAW_QUAL_MEAN", (r1_raw_stats['qc_stats']['qual_mean'] + r2_raw_stats['qc_stats']['qual_mean']) / 2.0)
        # After QC Reads
        write_output("QC_TOTAL_BP", r1_qc_stats['qc_stats']['total_bp'] + r2_qc_stats['qc_stats']['total_bp'])
        write_output("QC_COVERAGE", r1_qc_stats['qc_stats']['coverage'] + r2_qc_stats['qc_stats']['coverage'])
        write_output("QC_READ_TOTAL", r1_qc_stats['qc_stats']['read_total'] + r2_qc_stats['qc_stats']['read_total'])
        write_output("QC_READ_MEAN", (r1_qc_stats['qc_stats']['read_mean'] + r2_qc_stats['qc_stats']['read_mean']) / 2.0)
        write_output("QC_QUAL_MEAN", (r1_qc_stats['qc_stats']['qual_mean'] + r2_qc_stats['qc_stats']['qual_mean']) / 2.0)
    else:
        se_raw_stats = assembly_stats = read_json(f'{args.bactopia}/quality-control/summary/{args.sample_name}-original.json')
        se_qc_stats = assembly_stats = read_json(f'{args.bactopia}/quality-control/summary/{args.sample_name}-final.json')
        # Original Reads
        write_output("RAW_TOTAL_BP", se_raw_stats['qc_stats']['total_bp'])
        write_output("RAW_COVERAGE", se_raw_stats['qc_stats']['coverage'])
        write_output("RAW_READ_TOTAL", se_raw_stats['qc_stats']['read_total'])
        write_output("RAW_READ_MEAN", se_raw_stats['qc_stats']['read_mean'])
        write_output("RAW_QUAL_MEAN", se_raw_stats['qc_stats']['qual_mean'])
        # After QC Reads
        write_output("QC_TOTAL_BP", se_qc_stats['qc_stats']['total_bp'])
        write_output("QC_COVERAGE", se_qc_stats['qc_stats']['coverage'])
        write_output("QC_READ_TOTAL", se_qc_stats['qc_stats']['read_total'])
        write_output("QC_READ_MEAN", se_qc_stats['qc_stats']['read_mean'])
        write_output("QC_QUAL_MEAN", se_qc_stats['qc_stats']['qual_mean'])

    # Assembly related stats
    assembly_stats = read_json(f'{args.bactopia}/assembly/{args.sample_name}.json')
    write_output("TOTAL_CONTIG", assembly_stats['total_contig'])
    write_output("TOTAL_CONTIG_LENGTH", assembly_stats['total_contig_length'])
    write_output("MAX_CONTIG_LENGTH", assembly_stats['max_contig_length'])
    write_output("MEAN_CONTIG_LENGTH", assembly_stats['mean_contig_length'])
    write_output("N50_CONTIG_LENGTH", assembly_stats['n50_contig_length'])
    write_output("GC_PERCENT", float(assembly_stats['contig_percent_c']) + float(assembly_stats['contig_percent_g']))
