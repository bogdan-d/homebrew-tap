#!/usr/bin/env bash
# Fetch version + sha256 for both Linux architectures for a cask with JSON update endpoints.
# Currently tailored for antigravity (can be extended).
# Usage: ./scripts/fetch-multi-arch-shas.sh antigravity-linux
# Optional flags:
#   --product <name>   Override product key (default: antigravity)
#   --json             Output machine-readable JSON
#   --update <caskfile>  Patch the given cask file with new version & sha blocks (dry-run if not changed)
#
set -euo pipefail

PRODUCT="antigravity"
CASK_NAME=""
OUTPUT_JSON=false
CASK_FILE_UPDATE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --product)
      PRODUCT="$2"; shift 2 ;;
    --json)
      OUTPUT_JSON=true; shift ;;
    --update)
      CASK_FILE_UPDATE="$2"; shift 2 ;;
    *)
      if [[ -z "$CASK_NAME" ]]; then CASK_NAME="$1"; else echo "Unexpected arg: $1" >&2; exit 1; fi
      shift ;;
  esac
done

if [[ -z "$CASK_NAME" ]]; then
  echo "Usage: $0 <cask_name> [--product <name>] [--json] [--update <caskfile>]" >&2
  exit 1
fi

# Endpoints pattern (antigravity specific)
BASE="https://antigravity-auto-updater-974169037036.us-central1.run.app/api/update"
ARCHES=("linux-x64" "linux-arm64")

declare -A URLS
declare -A SHAS
VERSION=""

for arch in "${ARCHES[@]}"; do
  endpoint="${BASE}/${arch}/stable/latest"
  json=$(curl -fsSL --retry 3 --retry-delay 2 "$endpoint") || { echo "Failed to fetch $endpoint" >&2; exit 1; }
  url=$(echo "$json" | jq -r '.url')
  sha=$(echo "$json" | jq -r '.sha256hash')
  if [[ -z "$url" || -z "$sha" || "$url" == "null" || "$sha" == "null" ]]; then
    echo "Invalid JSON content from $endpoint" >&2
    exit 1
  fi
  # Extract version segment between /stable/ and next /
  ver_segment=$(echo "$url" | sed -n 's#.*/stable/\([^/]*\)/.*#\1#p')
  if [[ -z "$ver_segment" ]]; then
    echo "Could not parse version from URL: $url" >&2
    exit 1
  fi
  if [[ -z "$VERSION" ]]; then
    VERSION="$ver_segment"
  elif [[ "$VERSION" != "$ver_segment" ]]; then
    echo "Version mismatch between arches: $VERSION vs $ver_segment" >&2
    exit 1
  fi
  URLS[$arch]="$url"
  SHAS[$arch]="$sha"
done

if $OUTPUT_JSON; then
  jq -n --arg version "$VERSION" \
        --arg sha_x64 "${SHAS[linux-x64]}" \
        --arg sha_arm64 "${SHAS[linux-arm64]}" \
        '{version:$version, sha256:{x86_64_linux:$sha_x64, arm64_linux:$sha_arm64}}'
  exit 0
fi

echo "version \"$VERSION\""; echo "sha256 arm64_linux:  \"${SHAS[linux-arm64]}\","; echo "       x86_64_linux: \"${SHAS[linux-x64]}\"";

diff_applied=false
if [[ -n "$CASK_FILE_UPDATE" ]]; then
  if [[ ! -f "$CASK_FILE_UPDATE" ]]; then
    echo "Cask file not found: $CASK_FILE_UPDATE" >&2; exit 1
  fi
  # Patch in-place using awk to replace version & sha block
  tmpfile=$(mktemp)
  awk -v ver="$VERSION" -v sha_arm64="${SHAS[linux-arm64]}" -v sha_x64="${SHAS[linux-x64]}" '
    BEGIN { replaced_v=0; replaced_s=0 }
    /^(\s*)version\s+"/ { sub(/version ".*"/, "version \"" ver "\""); replaced_v=1 }
    /^(\s*)sha256 arm64_linux:/ {
      print "  sha256 arm64_linux:  \"" sha_arm64 "\",";
      getline; # consume x86_64 line
      print "         x86_64_linux: \"" sha_x64 "\"";
      replaced_s=1; next
    }
    { print }
    END { if (replaced_v==0 || replaced_s==0) exit 2 }
  ' "$CASK_FILE_UPDATE" > "$tmpfile" || true
  if [[ $? -eq 2 ]]; then
    echo "Warning: Did not find expected version/sha block to replace." >&2
    rm -f "$tmpfile"
  else
    mv "$tmpfile" "$CASK_FILE_UPDATE"
    diff_applied=true
  fi
fi

if $diff_applied; then
  echo "Updated $CASK_FILE_UPDATE with new version and sha256 values." >&2
fi
