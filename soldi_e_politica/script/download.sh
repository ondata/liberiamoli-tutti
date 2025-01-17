#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

base_url="https://parlamento18.camera.it"

mkdir -p "${folder}"/../raw_data

curl -kL "https://parlamento18.camera.it/199" | scrape -be '.pdf' | xq -c '.html.body.a[]' > "${folder}"/../raw_data/lista.jsonl

while read -r line; do
    url=$(echo "${line}" | jq -r '."@href"')
    output_file="${folder}/../raw_data/$(basename "${base_url}${url}")"
    if [ ! -f "$output_file" ]; then
        curl -L -o "$output_file" "${base_url}${url}"
    else
        echo "File $output_file already exists, skipping download"
    fi
done < "${folder}"/../raw_data/lista.jsonl
