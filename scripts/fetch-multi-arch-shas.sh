#!/usr/bin/env bash
# Multi-arch version + sha256 fetch helper for Linux casks.
# Generic usage supporting different vendor JSON schemas.
#
# Examples:
#   Antigravity (version parsed from download URL):
#     ./scripts/fetch-multi-arch-shas.sh antigravity-linux \
#       --endpoint 'https://antigravity-auto-updater-974169037036.us-central1.run.app/api/update/linux-{arch}/stable/latest' \
#       --arches 'x64 arm64'
#
#   VS Code (version from productVersion field):
#     ./scripts/fetch-multi-arch-shas.sh visual-studio-code-linux \
#       --endpoint 'https://update.code.visualstudio.com/api/update/linux-{arch}/stable/latest' \
#       --version-json-key productVersion \
#       --sha-json-key sha256hash \
#       --arches 'x64 arm64'
#
# Options:
#   --endpoint <template>    Endpoint template containing {arch}
#   --arches "x64 arm64"     Space-separated list of arch suffixes (default: x64 arm64)
#   --version-from-url       Extract version from JSON .url like /stable/<version>/ (default true if no version-json-key)
#   --version-json-key <k>   JSON key to take version from (disables URL extraction)
#   --sha-json-key <k>       JSON key for sha256 (default: sha256hash)
#   --json                   Output JSON only
#   --update <caskfile>      Patch version + sha256 block in cask file
#   --commit                 Git add & commit cask file if changed
#   --message <msg>          Commit message (default auto-generated)
#   --dry-run                Show planned changes without writing
#
set -euo pipefail

ENDPOINT_TEMPLATE=""
ARCH_LIST="x64 arm64"
VERSION_JSON_KEY=""
SHA_JSON_KEY="sha256hash"
USE_URL_VERSION=true
CASK_NAME=""
OUTPUT_JSON=false
CASK_FILE_UPDATE=""
DO_COMMIT=false
COMMIT_MSG=""
DRY_RUN=false

while [[ $# -gt 0 ]]
do
  case "$1" in
    --endpoint)
      ENDPOINT_TEMPLATE="$2"
      shift 2
      ;;
    --arches)
      ARCH_LIST="$2"
      shift 2
      ;;
    --version-json-key)
      VERSION_JSON_KEY="$2"
      USE_URL_VERSION=false
      shift 2
      ;;
    --sha-json-key)
      SHA_JSON_KEY="$2"
      shift 2
      ;;
    --version-from-url)
      USE_URL_VERSION=true
      shift
      ;;
    --json)
      OUTPUT_JSON=true
      shift
      ;;
    --update)
      CASK_FILE_UPDATE="$2"
      shift 2
      ;;
    --commit)
      DO_COMMIT=true
      shift
      ;;
    --message)
      COMMIT_MSG="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      if [[ -z "${CASK_NAME}" ]]; then CASK_NAME="$1"; else
         echo "Unexpected arg: $1" >&2
         exit 1
         fi
         shift
         ;;
         esac
         done
         
         if [[ -z "${CASK_NAME}" ]]
      then
  echo "Usage: $0 <cask_name> --endpoint <template> [options]" >&2
  exit 1
fi

if [[ -z "${ENDPOINT_TEMPLATE}" ]]
then
  echo "Error: --endpoint template required (must include {arch})." >&2
  exit 1
fi

if ! grep -q '{arch}' <<<"${ENDPOINT_TEMPLATE}"
then
  echo "Error: endpoint template must contain {arch}." >&2
  exit 1
fi

read -r -a ARCHES <<<"${ARCH_LIST}"

declare -A SHAS
VERSION=""

for arch in "${ARCHES[@]}"
do
  endpoint="${ENDPOINT_TEMPLATE//\{arch\}/${arch}}"
  json=$(curl -fsSL --retry 3 --retry-delay 2 "${endpoint}") || {
    echo "Failed to fetch ${endpoint}" >&2
    exit 1
  }

  # Determine version
  if [[ -n "${VERSION_JSON_KEY}" ]]
  then
    ver_segment=$(echo "${json}" | jq -r ".${VERSION_JSON_KEY}")
  elif ${USE_URL_VERSION}
  then
    download_url=$(echo "${json}" | jq -r '.url // empty')
    if [[ -z "${download_url}" ]]
    then
      echo "Missing .url field for version extraction." >&2
      exit 1
    fi
    ver_segment=$(sed -n 's#.*/stable/\([^/]*\)/.*#\1#p' <<<"${download_url}")
  else
    echo "No version extraction method configured." >&2
    exit 1
  fi

  sha=$(echo "${json}" | jq -r ".${SHA_JSON_KEY} // empty")
  if [[ -z "${ver_segment}" || -z "${sha}" ]]
  then
    echo "Invalid data (version or sha empty) from ${endpoint}" >&2
    exit 1
  fi

  if [[ -z "${VERSION}" ]]
  then
    VERSION="${ver_segment}"
  elif [[ "${VERSION}" != "${ver_segment}" ]]
  then
    echo "Version mismatch between arches: ${VERSION} vs ${ver_segment}" >&2
    exit 1
  fi
  SHAS["${arch}"]="${sha}"
done

if ${OUTPUT_JSON}
then
  # Build jq args safely
  jq_args=(--arg version "${VERSION}")
  for a in "${ARCHES[@]}"
  do
    jq_args+=(--arg "sha_${a}" "${SHAS[${a}]}")
  done
  jq "${jq_args[@]}" -n '($ARGS.named | to_entries | reduce .[] as $i ({}; .[$i.key] = $i.value)) as $named | {version: $named.version, sha256: {x86_64_linux: $named.sha_x64, arm64_linux: $named.sha_arm64}}'
  exit 0
fi

echo "version \"${VERSION}\""
echo "sha256 arm64_linux:  \"${SHAS[arm64]}\","
echo "       x86_64_linux: \"${SHAS[x64]}\""

diff_applied=false
if [[ -n "${CASK_FILE_UPDATE}" ]]
then
  if [[ ! -f "${CASK_FILE_UPDATE}" ]]
  then
    echo "Cask file not found: ${CASK_FILE_UPDATE}" >&2
    exit 1
  fi
  tmpfile=$(mktemp)
  awk -v ver="${VERSION}" -v sha_arm64="${SHAS[arm64]}" -v sha_x64="${SHAS[x64]}" -v dry="${DRY_RUN}" '
    BEGIN { replaced_v=0; replaced_s=0 }
    /^(\s*)version\s+"/ { sub(/version ".*"/, "version \"" ver "\""); replaced_v=1 }
    /^(\s*)sha256 arm64_linux:/ {
      if (!dry) {
         print "  sha256 arm64_linux:  \"" sha_arm64 "\",";
         getline; # consume x86_64 line
         print "         x86_64_linux: \"" sha_x64 "\"";
         } else {
         print; getline; print;
         }
         replaced_s=1; next
         }
         { print }
         END { if (replaced_v==0 || replaced_s==0) exit 2 }
         ' "${CASK_FILE_UPDATE}" >"${tmpfile}" || true
         if [[ $? -eq 2 ]]
      then
    echo "Warning: Did not find expected version/sha block to replace." >&2
    rm -f "${tmpfile}"
  else
    if ! ${DRY_RUN}
    then
      mv "${tmpfile}" "${CASK_FILE_UPDATE}"
      diff_applied=true
    else
      rm -f "${tmpfile}"
      echo "(dry-run) Not modifying ${CASK_FILE_UPDATE}" >&2
    fi
  fi
fi

if ${diff_applied}
then
  echo "Updated ${CASK_FILE_UPDATE} with new version and sha256 values." >&2
  if ${DO_COMMIT}
  then
    if [[ -z "${COMMIT_MSG}" ]]
    then
      COMMIT_MSG="${CASK_NAME} ${VERSION}"
    fi
    git add "${CASK_FILE_UPDATE}"
    git commit -m "${COMMIT_MSG}" --quiet || echo "Git commit failed or no changes." >&2
    echo "Committed changes: ${COMMIT_MSG}" >&2
  fi
fi
