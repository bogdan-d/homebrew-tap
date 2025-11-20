#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: style.sh [cask-name|path ...]

Runs `brew style --fix` on the given cask(s). If no arguments are provided,
the script formats all casks found in the Casks/ directory.

Examples:
  ./style.sh                # format all casks
  ./style.sh antigravity-linux  # format the cask by name
  ./style.sh Casks/antigravity-linux.rb # format by path

Options:
  -h, --help  Display this help message
USAGE
}

echo "Formatting Casks..."
echo "================"

# If no arguments are given, format all casks; otherwise format only the
# specified cask(s). The argument may be a cask name (without .rb) or a path.
files_to_check=()
if [[ "$#" -eq 0 ]]
then
  files_to_check=(Casks/*)
else
  if [[ "$1" == "-h" || "$1" == "--help" ]]
  then
    usage
    exit 0
  fi

  for arg in "$@"
  do
    if [[ -f "${arg}" ]]
    then
      files_to_check+=("${arg}")
    elif [[ -f "Casks/${arg}.rb" ]]
    then
      files_to_check+=("Casks/${arg}.rb")
    else
      echo "Error: cask '${arg}' not found as path or in Casks/"
      exit 1
    fi
  done
fi

for file in "${files_to_check[@]}"
do
  echo "Running style fix for cask file: ${file}"
  brew style --fix "${file}"
done

echo "Formatting complete."
echo "================"
