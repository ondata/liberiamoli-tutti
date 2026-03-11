# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

**Liberiamoli Tutti** is a data liberation initiative by the datiBeneComune campaign (ActionAid Italia, OnData, Transparency International Italia). Each newsletter issue corresponds to one or more public-interest datasets that are extracted, cleaned, documented, and published in open formats.

## Repository structure

Each dataset lives in its own top-level folder (e.g., `scioperi/`, `pnrr_cup_cig/`, `dati_ricostruzione/`) with this standard layout:

```
<dataset>/
├── data/  or  dati/    # cleaned output (CSV, JSONL)
├── rawdata/             # original source files (PDF, XLSX, …)
├── script/ or scripts/  # extraction and processing scripts
├── README.md            # sources, methodology, data dictionary
└── LICENSE.md           # CC-BY 4.0 by default
```

Shared reference data (ISTAT comune lists, regional boundaries) lives in `risorse/`. Binary CLI tools (`mlr`, `mlrgo`, `duckdb`) live in `bin/` and are copied to `~/bin` in CI.

Automated workflows are in `.github/workflows/` — each runs a dataset script on a schedule and commits results.

## CLI tools

Prefer these tools for all data work:

- `mlr` / `mlrgo` — primary tool for CSV/JSON processing
- `duckdb -c "..."` — SQL on CSV/Parquet; start with `DESCRIBE` and `SUMMARIZE`
- `scrape-cli` — HTML scraping via XPath
- `xq`, `yq` — HTML/JSON/YAML extraction
- `curl` — data download

Quick sanity checks:

```bash
mlr --csv head -n 5 data/file.csv
duckdb -c "SELECT COUNT(*) FROM 'data/file.csv'"
```

## Bash script conventions

Every script must start with:

```bash
set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

## Data standards

- Output formats: **CSV and JSONL**, UTF-8 encoding
- Dates: always `YYYY-MM-DD`
  ```bash
  mlr put '$data_iso=strftime(strptime($data,"%d/%m/%Y"),"%Y-%m-%d")'
  ```
- Raw filenames: `YYYY-MM-DD_snake_case.ext`
- Dataset folder names: lowercase with underscores
- License: CC-BY 4.0, attribution to "Liberiamoli tutti!"

## Typical data pipeline

HTML/PDF/XLSX → JSON → CSV/JSONL

1. `curl` + `scrape-cli` (XPath selectors) to extract raw HTML data
2. `xq` or `yq` to convert to JSON (handle nulls explicitly)
3. `mlr` to clean, standardize dates, deduplicate

## Reference data

`risorse/Elenco-comuni-italiani.csv` — ISTAT comune codes and names (use to enrich datasets with `cod_istat`).
`risorse/Elenco-regioni.csv` — regional reference.
`risorse/ondata_confini_amministrativi_api_v2_it_20240101_comuni.geo.json` — administrative boundaries.

## Logging and commits

- Update `LOG.md` in the root after every significant change (new dataset, script fix, data refresh). Add a `## YYYY-MM-DD` heading with bullet points; most recent entry at top.
- Commit messages: short, direct, in Italian — e.g., `aggiornamento dati scioperi cgsse: 2026-02-21T04:28:19+00:00`
