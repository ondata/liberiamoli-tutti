# Repository Guidelines

## Project Structure & Module Organization

This repository is a collection of dataset folders. Each dataset follows the same pattern:

- `data/` or `dati/`: cleaned, publishable data (CSV, JSONL).
- `rawdata/`: original source files (PDF, XLSX, etc.).
- `script/` or `scripts/`: extraction/processing scripts.
- `README.md`: sources, methodology, and data dictionary.
- `LICENSE.md`: data license (default CC-BY 4.0).

Shared reference materials live in `risorse/`. Root-level `LOG.md` records notable updates.

## Build, Test, and Development Commands

There is no single build system. Work is dataset-specific:

- Run scripts inside the dataset folder (e.g., `scioperi/scripts/` or `soldi_e_politica/script/`).
- Common CLI tools in `bin/`: `mlr`, `mlrgo`, `duckdb`.
- Example: `mlr --csv cut -f col1,col2 data/file.csv` (quick checks).
- Example: `duckdb -c "SELECT COUNT(*) FROM 'data/file.csv'"` (sanity checks).

## Coding Style & Naming Conventions

- For bash scripts, enable strict mode:
  - `set -x`, `set -e`, `set -u`, `set -o pipefail`.
- Dates must be standardized to `YYYY-MM-DD`.
- Output formats: CSV and JSONL, UTF-8 encoding.
- Use clear, descriptive filenames; keep dataset folder names lowercase with underscores.

## Testing Guidelines

No formal test suite is present. Validate outputs with:

- `mlr` for schema/format checks.
- `duckdb` for row counts and duplicates.
- Manual review of `README.md` data dictionary.

## Commit & Pull Request Guidelines

Recent commits use short, direct Italian messages (e.g., `update`, `pulizia`, `aggiornamento dati <dataset>: <ISO timestamp>`). Prefer the same style and keep messages one line.

PRs should:

- Focus on one dataset or topic.
- Include updated `README.md`/`LICENSE.md` if data changes.
- Mention any new sources and scripts used.
- Add a `LOG.md` entry for significant changes.

## Logging & Release Notes

After any significant update (new dataset, data refresh, script fix), append a bullet under today’s date in `LOG.md`.

## Agent-Specific Instructions

- Follow the standard dataset folder pattern above.
- Prefer `mlr`, `duckdb`, `scrape-cli`, `yq`, `xq` for data work.
