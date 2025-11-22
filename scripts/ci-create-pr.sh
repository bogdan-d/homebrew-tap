#!/usr/bin/env bash
set -euo pipefail
cask_name="$1"
if [[ -z "${cask_name}" ]]
then
  echo "Usage: $0 <cask_name>" >&2
  exit 1
fi
cask_file="Casks/${cask_name}.rb"
if [[ ! -f "${cask_file}" ]]
then
  echo "Cask file not found: ${cask_file}" >&2
  exit 1
fi
version=$(grep -E '^\s*version "' "${cask_file}" | head -1 | sed -E 's/^[[:space:]]*version "([^"]+)".*/\1/')
if [[ -z "${version}" ]]
then
  echo "Could not extract version from ${cask_file}" >&2
  exit 1
fi
branch="multi-arch-bump-${cask_name}-${version}"
if git rev-parse --quiet --verify "refs/heads/${branch}" >/dev/null
then
  git checkout "${branch}"
else
  git checkout -b "${branch}"
fi

echo "Detected version: ${version}" >&2
if ! gh pr create --title "${cask_name} ${version}" --body "Automated multi-arch bump" --head "${branch}"
then
  echo "PR creation skipped or failed (may already exist)." >&2
fi
