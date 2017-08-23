#
# Sunbeam: an iridescent HTS pipeline
#
# Author: Erik Clarke <ecl@mail.med.upenn.edu>
# Created: 2016-04-28
#

import re
import sys
import yaml
import configparser
from pprint import pprint
from pathlib import Path, PurePath

from snakemake.utils import update_config, listfiles
from snakemake.exceptions import WorkflowError

from sunbeamlib import build_sample_list, read_seq_ids
from sunbeamlib.config import *
from sunbeamlib.reports import *

if not config:
        raise SystemExit(
                "No config file specified. Run `sunbeam_init` to generate a "
                "config file, and specify with --configfile")

# ---- Substitute $HOME_DIR variable
#varsub(config)

# ---- Setting up config files and samples
Cfg = check_config(config)
Blastdbs = process_databases(Cfg['blastdbs'])
Samples = build_sample_list(Cfg['all']['data_fp'], Cfg['all']['filename_fmt'], Cfg['all']['exclude'])

GenomeFiles = [f for f in Cfg['mapping']['genomes_fp'].glob('*.fasta')]
GenomeSegments = {PurePath(g.name).stem: read_seq_ids(Cfg['mapping']['genomes_fp'] / g) for g in GenomeFiles}

# ---- Change your workdir to output_fp
workdir: str(Cfg['all']['output_fp'])

# ---- Set up output paths for the various steps
QC_FP = output_subdir(Cfg, 'qc')
ASSEMBLY_FP = output_subdir(Cfg, 'assembly')
ANNOTATION_FP = output_subdir(Cfg, 'annotation')
CLASSIFY_FP = output_subdir(Cfg, 'classify')
MAPPING_FP = output_subdir(Cfg, 'mapping')

localrules: decontam

# ---- Targets rules
include: "rules/targets/targets.rules"


# ---- Quality control rules
include: "rules/qc/qc.rules"
include: "rules/qc/decontaminate.rules"
include: "rules/qc/repeat_masking.rules"

# ---- Assembly rules
include: "rules/assembly/assembly.rules"
include: "rules/assembly/pairing.rules"


# ---- Antibiotic resistance gene rules
include: "rules/abx/abx_genes.rules"

# ---- Contig annotation rules
include: "rules/annotation/annotation.rules"
include: "rules/annotation/blast.rules"
include: "rules/annotation/orf.rules"


# ---- Classifier rules
#include: "rules/classify/classify.rules"
#include: "rules/classify/clark.rules"
include: "rules/classify/kraken.rules"


# ---- Mapping rules
include: "rules/mapping/bowtie.rules"
#include: "rules/mapping/snap.rules"


# ---- Reports rules
include: "rules/reports/reports.rules"

# ---- Rule all: run all targets
rule all:
    input: TARGET_ALL

rule samples:
    run:
        print("Samples found:")
        pprint(sorted(list(Samples.keys())))

