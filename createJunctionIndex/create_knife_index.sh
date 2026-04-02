#!/bin/sh

# Wrapper script to create KNIFE index files from a genome FASTA and annotation GTF.
# It runs makeExonDB.py to produce exon/record pickles and then calls
# createJunctionIndex.sh to produce junction FASTAs and bowtie2 indices in the
# pipeline index directory.
#
# Usage:
#   create_knife_index.sh /path/to/circularRNApipeline \
#                        /path/to/genome.fa \
#                        /path/to/annotation.gtf \
#                        /path/to/out_dir \
#                        FILE_ID [WINDOW] [GENE_NAME_1] [GENE_NAME_2] [INDEX_DIR]
#
# Example:
#   ./create_knife_index.sh /home/user/circularRNApipeline \
#                          /data/genomes/human.fa \
#                          /data/genomes/human.gtf \
#                          /tmp/human_index_out \
#                          hg38_2026 1000000 gene_name gene_id /data/knife_index

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -lt 5 ]; then
  echo "Usage: $0 PIPELINE_DIR GENOME_FASTA GTF OUT_DIR FILE_ID [WINDOW] [GENE_NAME_1] [GENE_NAME_2] [INDEX_DIR]"
  exit 1
fi

PIPELINE_DIR=$1
GENOME_FASTA=$2
GTF=$3
OUT_DIR=$4
FILE_ID=$5
WINDOW=${6:-1000000}
GENE_NAME_1=${7:-gene_name}
GENE_NAME_2=${8:-gene_id}
INDEX_DIR=${9:-${PIPELINE_DIR}/index}

# basic checks
command -v python >/dev/null 2>&1 || { echo "python not found in PATH" >&2; exit 2; }
command -v bowtie2-build >/dev/null 2>&1 || echo "Warning: bowtie2-build not found in PATH; index build will fail if missing" >&2

echo "Creating exon DB from FASTA and GTF..."
python "${SCRIPT_DIR}/makeExonDB.py" -f "${GENOME_FASTA}" -a "${GTF}" -o "${OUT_DIR}" -n1 "${GENE_NAME_1}" -n2 "${GENE_NAME_2}" -v
if [ $? -ne 0 ]; then
  echo "makeExonDB.py failed" >&2
  exit 3
fi

echo "Creating junction FASTAs and bowtie2 indices..."
sh "${SCRIPT_DIR}/createJunctionIndex.sh" "${PIPELINE_DIR}" "${OUT_DIR}" "${FILE_ID}" "${WINDOW}" "${GENE_NAME_1}" "${GENE_NAME_2}" "${INDEX_DIR}"
if [ $? -ne 0 ]; then
  echo "createJunctionIndex.sh failed" >&2
  exit 4
fi

echo "Index creation complete. Index files are in: ${INDEX_DIR}"
