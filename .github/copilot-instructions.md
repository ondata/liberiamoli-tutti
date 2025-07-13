# Copilot Instructions - Liberiamoli Tutti

This repository contains the **datiBeneComune** initiative data extraction and processing workflows for public interest datasets in Italy.

## Project Architecture

**Core Pattern**:

Each dataset lives in its own folder with standardized structure:

- `data/` or `dati/` - processed, clean datasets (CSV/JSON/JSONL)
- `rawdata/` - original source files (PDFs, Excel, etc.)
- `script/` or `scripts/` - extraction and processing scripts
- `README.md` - documentation with sources and methodology
- `LICENSE.md` - CC-BY 4.0 licensing

**Key Examples**:

`scioperi/`, `amianto_ats_milano/`, `cinque_per_mille/`, `italian_polls/`

## Project Logging

**Requirement**:

After any significant change (e.g., adding a new dataset, fixing a script, updating data), you MUST update the root `LOG.md` file.

- Add a new entry under the current date (`## YYYY-MM-DD`).
- Briefly describe the change in a new list item.

## Essential Tools & Dependencies

**Standardized toolchain** (available in `bin/`):

- `mlr`/`mlrgo` - Miller for CSV/JSON data processing (primary data manipulation tool)
- `duckdb` - SQL operations on datasets
- Python tools: `scrape-cli`, `yq`, `xq` for web scraping and data extraction

**Script patterns**:

All bash scripts follow rigorous error handling:

```bash
set -x  # Debug output
set -e  # Exit on error
set -u  # Exit on undefined variables
set -o pipefail  # Fail on pipeline errors
```

## Data Processing Workflows

**Extraction Pattern**:

HTML → JSON → CSV transformation pipeline

1. `curl` + `scrape-cli` for web data extraction using XPath
2. `xq`/`yq` for HTML→JSON conversion with null handling
3. `mlr` for data cleaning, date standardization (ISO format), deduplication

**Date Standardization**:

Always convert to `YYYY-MM-DD` format using mlr:

```bash
mlr put '$data_iso=strftime(strptime($data,"%d/%m/%Y"),"%Y-%m-%d")'
```

**Example from `scioperi/scripts/mit.sh`**:

- Scrapes MIT transport strikes data via XPath table extraction
- Maps HTML table columns to JSON with comprehensive null checking
- Uses mlr for date formatting and chronological sorting

## GitHub Actions Integration

**Automated data collection** via scheduled workflows in `.github/workflows/`:

- Daily scraping schedules (e.g., `cron: '40 3 * * *'`)
- Tor proxy usage for anonymous scraping in CI environments
- Retry mechanisms for network reliability
- Tools setup: copy `bin/mlrgo` to `~/bin/mlr` in workflows

**Dependencies**:

Each project includes `requirements.txt` for Python tools

## Data Standards

**Output Formats**: Always provide both CSV and JSONL versions
**Encoding**: UTF-8 with `,` separator and `.` decimal separator
**Licensing**: CC-BY 4.0 with attribution to "Liberiamoli tutti!"
**Documentation**: Include data dictionary with column descriptions

**Wide→Long Transformation**:

For survey/polling data (see `italian_polls/`):

- Split into separate anagrafica (metadata) and results tables
- Convert from wide format (one column per party) to long format (one row per party result)

## Common Resources

`risorse/` contains shared reference data:

- `Elenco-comuni-italiani.csv` - ISTAT municipality codes
- `Elenco-regioni.csv` - Regional codes
- Administrative boundary GeoJSON files

Use `risorse/script/basi-dati.sh` to update these from ISTAT APIs with proper encoding conversion (Windows-1252 → UTF-8).

## Newsletter Integration

Each dataset corresponds to a "Liberiamoli tutti!" newsletter issue. Include newsletter links and issue numbers in README files for traceability.

## Markdown Output Notes

Please adhere to standard Markdown formatting to ensure compatibility and readability.

Specifically:

- After any heading (e.g., `# Title`, `## Subtitle`), always insert a blank line.
- After a numbered list marker (e.g., `1.`, `2.`), insert a single space.
- After a bulleted list marker (e.g., `-`, `*`), insert a single space.
- After a colon (`:`) that precedes a list, always insert a blank line.
- For list indentation, use **two spaces**, not four.
