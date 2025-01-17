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
    curl -L -o "${folder}"/../raw_data/$(basename "${base_url}${url}") "${base_url}${url}"
done < "${folder}"/../raw_data/lista.jsonl
