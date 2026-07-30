#!/usr/bin/env bash
set -euo pipefail

cask_name="$1"
endpoint_template="$2"
arches="$3"
version_json_key="${4:-}"
sha_json_key="${5:-sha256hash}"

chmod +x scripts/fetch-multi-arch-shas.sh

# First fetch JSON metadata to determine version for branch naming
json_cmd=(scripts/fetch-multi-arch-shas.sh "${cask_name}" --endpoint "${endpoint_template}" --arches "${arches}" --sha-json-key "${sha_json_key}" --json)
if [[ -n "${version_json_key}" ]]
then
  json_cmd+=(--version-json-key "${version_json_key}")
fi
json_output="$("${json_cmd[@]}")"
version="$(echo "${json_output}" | jq -r '.version')"

branch="multi-arch-bump-${cask_name}-${version}"
if git rev-parse --quiet --verify "refs/heads/${branch}" >/dev/null
then
  git checkout "${branch}"
else
  git checkout -b "${branch}"
fi

# Now perform update + commit
update_cmd=(scripts/fetch-multi-arch-shas.sh "${cask_name}" --endpoint "${endpoint_template}" --arches "${arches}" --sha-json-key "${sha_json_key}" --update "Casks/${cask_name}.rb" --commit --message "${cask_name} ${version}")
if [[ -n "${version_json_key}" ]]
then
  update_cmd+=(--version-json-key "${version_json_key}")
fi
"${update_cmd[@]}"

brew style "Casks/${cask_name}.rb"
