#!/usr/bin/env bash

set -euo pipefail

TAP_PREFIX="bogdan-d/local-test-"
TAP_MARKER=".dev-cask-target"
INSTALL_MARKER=".dev-cask-installed"

usage() {
  cat <<'EOF'
Usage: ./dev-cask.sh <command> [cask_name] [options]

Commands:
  install     Install the cask, then uninstall it during cleanup
  audit       Audit the cask
  livecheck   Check for newer versions
  bump        Check for outdated versions
  style       Check the local cask file directly
  cleanup     Clean a kept scratch tap; requires cask_name and --tap
  untap       Remove an empty kept scratch tap; requires --tap

Options:
  --keep      Keep the scratch tap and any test installation
  --tap TAP   Scratch tap printed by a previous --keep run
  --debug     Enable shell tracing
  --verbose   Pass --verbose to Homebrew commands where applicable
EOF
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

install_receipt() {
  local caskroom
  caskroom="$(brew --caskroom "${TAP_CASK_NAME}")"
  printf '%s/.metadata/INSTALL_RECEIPT.json\n' "${caskroom}"
}

load_owned_tap() {
  [[ -n "${TAP_NAME:-}" ]] || fail "--tap is required for '${COMMAND}'."
  [[ "${TAP_NAME}" == "${TAP_PREFIX}"* ]] || fail "Refusing non-scratch tap '${TAP_NAME}'."

  TAP_PATH="$(brew --repo "${TAP_NAME}" 2>/dev/null)" || fail "Scratch tap '${TAP_NAME}' does not exist."
  [[ -f "${TAP_PATH}/${TAP_MARKER}" ]] || fail "Tap '${TAP_NAME}' is not owned by dev-cask.sh."
  TAP_CASK_NAME="$(<"${TAP_PATH}/${TAP_MARKER}")"
  [[ -n "${TAP_CASK_NAME}" ]] || fail "Scratch tap '${TAP_NAME}' has an invalid ownership marker."
}

cleanup_owned_tap() {
  local cask_file="${TAP_PATH}/Casks/${TAP_CASK_NAME}.rb"

  if [[ -f "${TAP_PATH}/${INSTALL_MARKER}" ]] && brew list --cask "${TAP_CASK_NAME}" >/dev/null 2>&1
  then
    local receipt
    local expected_receipt
    local actual_receipt
    receipt="$(install_receipt)"
    expected_receipt="$(<"${TAP_PATH}/${INSTALL_MARKER}")"
    actual_receipt="$(stat -c '%d:%i:%Y:%s' "${receipt}" 2>/dev/null || true)"
    if [[ -z "${expected_receipt}" || "${expected_receipt}" == "pending" || "${actual_receipt}" != "${expected_receipt}" ]]
    then
      echo "Cleanup stopped: installed '${TAP_CASK_NAME}' is not the test installation; kept ${TAP_NAME}." >&2
      return 1
    fi

    echo "Uninstalling test cask ${TAP_CASK_NAME}..."
    if ! brew uninstall --cask "${TAP_NAME}/${TAP_CASK_NAME}"
    then
      echo "Cleanup stopped: test cask uninstall failed; kept ${TAP_NAME}." >&2
      return 1
    fi
  fi

  rm -f "${TAP_PATH}/${INSTALL_MARKER}" "${cask_file}"
  echo "Removing scratch tap ${TAP_NAME}..."
  if ! brew untap "${TAP_NAME}"
  then
    echo "Cleanup stopped: could not safely untap ${TAP_NAME}." >&2
    return 1
  fi
}

AUTO_CLEANUP=false
on_exit() {
  local status=$?
  local cleanup_status=0
  trap - EXIT

  if [[ "${AUTO_CLEANUP}" == "true" ]]
  then
    set +e
    cleanup_owned_tap
    cleanup_status=$?
    set -e
    if ((status == 0 && cleanup_status != 0))
    then
      status=${cleanup_status}
    fi
    if ((status == 0))
    then
      echo "Done."
    fi
  fi

  exit "${status}"
}

[[ $# -gt 0 ]] || {
  usage
  exit 1
}

COMMAND="$1"
shift

KEEP=false
DEBUG=false
VERBOSE=false
TAP_NAME=""
ARGS=()
while [[ $# -gt 0 ]]
do
  case "$1" in
    --keep) KEEP=true ;;
    --debug) DEBUG=true ;;
    --verbose) VERBOSE=true ;;
    --tap)
      [[ $# -gt 1 ]] || fail "--tap requires a value."
      TAP_NAME="$2"
      shift
      ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done
set -- "${ARGS[@]}"

[[ "${DEBUG}" == "false" ]] || set -x

case "${COMMAND}" in
  install | audit | livecheck | bump | style | cleanup | untap) ;;
  *) fail "Unknown command '${COMMAND}'." ;;
esac

if [[ "${COMMAND}" == "untap" ]]
then
  load_owned_tap
  if [[ -f "${TAP_PATH}/${INSTALL_MARKER}" ]] && brew list --cask "${TAP_CASK_NAME}" >/dev/null 2>&1
  then
    fail "Scratch tap contains an installed test cask; use 'cleanup ${TAP_CASK_NAME} --tap ${TAP_NAME}'."
  fi
  rm -f "${TAP_PATH}/Casks/${TAP_CASK_NAME}.rb"
  cleanup_owned_tap
  exit 0
fi

[[ $# -gt 0 ]] || fail "Cask name required for '${COMMAND}'."
CASK_NAME="${1%.rb}"
shift
CASK_FILE="Casks/${CASK_NAME}.rb"

if [[ "${COMMAND}" == "style" ]]
then
  [[ -f "${CASK_FILE}" ]] || fail "Cask file '${CASK_FILE}' not found."
  BREW_ARGS=()
  [[ "${VERBOSE}" == "false" ]] || BREW_ARGS+=(--verbose)
  brew style "${BREW_ARGS[@]}" "${CASK_FILE}" "$@"
  exit 0
fi

if [[ "${COMMAND}" == "cleanup" ]]
then
  load_owned_tap
  [[ "${TAP_CASK_NAME}" == "${CASK_NAME}" ]] || fail "Tap '${TAP_NAME}' belongs to '${TAP_CASK_NAME}', not '${CASK_NAME}'."
  cleanup_owned_tap
  exit 0
fi

[[ -f "${CASK_FILE}" ]] || fail "Cask file '${CASK_FILE}' not found."
[[ -z "${TAP_NAME}" ]] || fail "--tap is only valid with cleanup or untap."
TAP_NAME="${TAP_PREFIX}$(date +%s)-$$-${RANDOM}"

echo "Creating scratch tap ${TAP_NAME}..."
brew tap-new --no-git "${TAP_NAME}" >/dev/null
if ! TAP_PATH="$(brew --repo "${TAP_NAME}" 2>/dev/null)"
then
  brew untap "${TAP_NAME}" >/dev/null 2>&1 || true
  fail "Could not locate scratch tap '${TAP_NAME}'."
fi
mkdir -p "${TAP_PATH}/Casks"
printf '%s\n' "${CASK_NAME}" >"${TAP_PATH}/${TAP_MARKER}"
cp "${CASK_FILE}" "${TAP_PATH}/Casks/"
TAP_CASK_NAME="${CASK_NAME}"
FULL_CASK_NAME="${TAP_NAME}/${CASK_NAME}"

if [[ "${KEEP}" == "false" ]]
then
  AUTO_CLEANUP=true
  trap on_exit EXIT
fi

echo "Running ${COMMAND} for ${FULL_CASK_NAME}..."
case "${COMMAND}" in
  install)
    if brew list --cask "${CASK_NAME}" >/dev/null 2>&1
    then
      fail "Cask '${CASK_NAME}' is already installed; refusing to replace or later uninstall it."
    fi
    printf 'pending\n' >"${TAP_PATH}/${INSTALL_MARKER}"
    BREW_ARGS=(--cask)
    [[ "${VERBOSE}" == "false" ]] || BREW_ARGS+=(--verbose)
    brew install "${BREW_ARGS[@]}" "${FULL_CASK_NAME}" "$@"
    receipt="$(install_receipt)"
    [[ -f "${receipt}" ]] || fail "Homebrew did not record an install receipt for '${CASK_NAME}'."
    stat -c '%d:%i:%Y:%s' "${receipt}" >"${TAP_PATH}/${INSTALL_MARKER}"
    ;;
  audit)
    BREW_ARGS=(--cask)
    [[ "${VERBOSE}" == "false" ]] || BREW_ARGS+=(--verbose)
    brew audit "${BREW_ARGS[@]}" "${FULL_CASK_NAME}" "$@"
    ;;
  livecheck)
    BREW_ARGS=()
    [[ "${VERBOSE}" == "false" ]] || BREW_ARGS+=(--verbose)
    brew livecheck "${BREW_ARGS[@]}" "${FULL_CASK_NAME}" "$@"
    ;;
  bump)
    BREW_ARGS=(--no-fork --cask)
    [[ "${VERBOSE}" == "false" ]] || BREW_ARGS+=(--verbose)
    brew bump "${BREW_ARGS[@]}" "${FULL_CASK_NAME}" "$@"
    ;;
  *) fail "Unsupported command '${COMMAND}'." ;;
esac

if [[ "${KEEP}" == "true" ]]
then
  echo "Kept scratch tap ${TAP_NAME}."
  echo "Cleanup: ./dev-cask.sh cleanup ${CASK_NAME} --tap ${TAP_NAME}"
fi
