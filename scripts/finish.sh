#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

if ! command -v patch >/dev/null
then
  brew install patch
fi

brew style --fix .
brew style .
tests/dev-cask-test.sh

changed_casks_file="$(mktemp)"
trap 'rm -f "${changed_casks_file}"' EXIT
git diff HEAD --name-only --diff-filter=ACMR -- 'Casks/*.rb' >"${changed_casks_file}"
git ls-files --others --exclude-standard -- 'Casks/*.rb' >>"${changed_casks_file}"
sort -u -o "${changed_casks_file}" "${changed_casks_file}"

while IFS='' read -r cask_file
do
  [[ -n "${cask_file}" ]] || continue
  ./dev-cask.sh audit "$(basename "${cask_file}" .rb)"
done <"${changed_casks_file}"
