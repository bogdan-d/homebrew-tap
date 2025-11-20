#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: audit.sh [cask-name|path ...]

Runs `brew audit --cask` on the given cask(s). If no arguments are provided,
the script audits all casks found in the Casks/ directory.

Examples:
  ./audit.sh                # audit all casks
  ./audit.sh antigravity-linux  # audit the cask by name
  ./audit.sh Casks/antigravity-linux.rb # audit by path

Options:
  -h, --help  Display this help message
USAGE
}

# If the first argument is a help flag, show usage and exit before creating a tap
if [[ "$#" -gt 0 ]] && [[ "$1" == "-h" || "$1" == "--help" ]]
then
  usage
  exit 0
fi

echo "Auditing Casks..."
echo "================"

repo_dir="$(brew --repository)"
echo "Setting up temporary tap for auditing at ${repo_dir}/Library/Taps/homebrew-releaser/homebrew-test/Casks..."
brew tap-new --verbose --no-git homebrew-releaser/test

mkdir -p "${repo_dir}"/Library/Taps/homebrew-releaser/homebrew-test/Casks

# If no arguments are given, audit all casks; otherwise audit only the
# specified cask(s). The argument may be a cask name (without .rb) or a path.
files_to_check=()
if [[ "$#" -eq 0 ]]
then
  files_to_check=(Casks/*)
else
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
      # Clean up the tap we created before exiting
      brew untap --verbose --force homebrew-releaser/test || true
      exit 1
    fi
  done
fi

# Copy only the selected cask files into the test tap to keep audit scoped
cp -rv "${files_to_check[@]}" "${repo_dir}"/Library/Taps/homebrew-releaser/homebrew-test/Casks

for file in "${repo_dir}"/Library/Taps/homebrew-releaser/homebrew-test/Casks/*
do
  echo "Auditing Cask: homebrew-releaser/test/$(basename "${file%.rb}")"
  brew audit --cask "homebrew-releaser/test/$(basename "${file%.rb}")"
done

echo "Cleaning up temporary tap..."
brew untap --verbose --force homebrew-releaser/test

echo "Audit complete."
echo "================"
