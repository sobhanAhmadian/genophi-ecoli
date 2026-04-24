#!/bin/bash

set -euo pipefail

OUTDIR=$1
mkdir -p "$OUTDIR"
cd "$OUTDIR"

curl -s "https://api.github.com/repos/mdmparis/coli_phage_interactions_2023/contents/data/genomics/phages/FNA" \
  | python3 -c "
import sys, json
for f in json.load(sys.stdin):
    print(f['download_url'], f['name'])
" | while read url name; do
    curl -L -s -o "${name//-/}" "$url"
    echo "Downloaded: $name"
done

rm desktop.ini

# Delete the first row of T4LD.fna, which is not a valid FASTA header
sed -i '1d' T4LD.fna

echo "All downloads complete"