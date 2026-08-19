#!/usr/bin/env bash
# Fetch the publication data for the website from the CV repo (b-fg/CV.typ):
#   - main.bib            -> _bibliography/main.bib  (rendered by jekyll-scholar)
#   - scholar_data.json   -> _data/scholar.json      (exposed as site.data.scholar)
# Both files are git-ignored; CI runs this before `jekyll build`, and locally
# `make fetch` (or running this script) does the same.
set -euo pipefail
cd "$(dirname "$0")/.."

CV_REPO="${CV_REPO:-b-fg/CV.typ}"
BIB_URL="https://raw.githubusercontent.com/${CV_REPO}/main/main.bib"
SCHOLAR_URL="https://github.com/${CV_REPO}/releases/latest/download/scholar_data.json"

mkdir -p _bibliography _data
echo "Fetching ${BIB_URL}"
curl -fsSL --retry 3 -o _bibliography/main.bib "${BIB_URL}"
echo "Fetching ${SCHOLAR_URL}"
curl -fsSL --retry 3 -o _data/scholar.json "${SCHOLAR_URL}"
python3 -c 'import json,sys; d=json.load(open("_data/scholar.json")); print("scholar:", d)' 2>/dev/null || true
