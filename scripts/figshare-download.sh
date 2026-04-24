#!/bin/bash

set -euo pipefail

ARTICLE_ID=$1
OUTDIR=$2

mkdir -p "$OUTDIR"
cd "$OUTDIR"

curl -s "https://api.figshare.com/v2/articles/${ARTICLE_ID}/files?page_size=500" \
  | python3 -c "
import sys, json
for f in json.load(sys.stdin):
    print(f['download_url'], f['name'])
" | while read url name; do
    curl -L -s -o "${name//-/}" "$url"
    echo "Downloaded: $name"
done

wait
echo "All downloads complete"
