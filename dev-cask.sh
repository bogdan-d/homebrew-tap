#!/usr/bin/env bash

# Usage: ./dev-cask.sh <command> <cask_name> [options]
# Commands:
#   install     Install the cask (wrapper for brew install --cask). Defaults to cleanup after unless --keep is used.
#   audit       Audit the cask (wrapper for brew audit --cask)
#   livecheck   Check for newer versions (wrapper for brew livecheck)
#   style       Check code style (wrapper for brew style)
#   cleanup     Uninstall the cask and remove the tap
#   untap       Remove the tap
#
# Options:
#   --keep      Do not cleanup (uninstall/untap) after the command
#   --debug     Enable debug output (set -x)
#   --verbose   Pass --verbose to brew commands where applicable

set -e

TAP_NAME="bogdan-d/local-test"

if [[ -z "$1" ]]
then
  echo "Usage: ./dev-cask.sh <command> <cask_name> [options]"
  echo "Commands: install, audit, livecheck, style, cleanup, untap"
  exit 1
fi

COMMAND="$1"
shift

# Parse options
KEEP=false
DEBUG=false
VERBOSE=false
ARGS=()
while [[ "$#" -gt 0 ]]
do
  case "$1" in
    --keep) KEEP=true ;;
    --debug) DEBUG=true ;;
    --verbose) VERBOSE=true ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done

# Restore positional arguments
set -- "${ARGS[@]}"

# Enable debug mode if requested
if [[ "${DEBUG}" == "true" ]]
then
  set -x
fi

if [[ "${COMMAND}" == "untap" ]]
then
  echo "Removing temporary tap ${TAP_NAME}..."
  BREW_ARGS=(--force)
  [[ "${VERBOSE}" == "true" ]] && BREW_ARGS+=(--verbose)
  brew untap "${BREW_ARGS[@]}" "${TAP_NAME}" || echo "Tap not found or already removed."
  exit 0
fi

if [[ -z "$1" ]]
then
  echo "Error: Cask name required for command '${COMMAND}'."
  exit 1
fi

CASK_NAME="$1"
shift

# Handle .rb extension if provided
CASK_NAME="${CASK_NAME%.rb}"
CASK_FILE="Casks/${CASK_NAME}.rb"
FULL_CASK_NAME="${TAP_NAME}/${CASK_NAME}"

# Just run the style directly on the file(s)
if [[ "${COMMAND}" == "style" ]]
then
  echo "Running style check..."
  BREW_ARGS=()
  [[ "${VERBOSE}" == "true" ]] && BREW_ARGS+=(--verbose)
  brew style "${BREW_ARGS[@]}" "${FULL_CASK_NAME}" "$@"
  exit 0
fi

if [[ "${COMMAND}" == "cleanup" ]]
then
  echo "Cleaning up ${FULL_CASK_NAME}..."
  BREW_ARGS=(--cask)
  [[ "${VERBOSE}" == "true" ]] && BREW_ARGS+=(--verbose)
  brew uninstall "${BREW_ARGS[@]}" "${FULL_CASK_NAME}" || echo "Not installed or uninstall failed."
  echo "Removing temporary tap..."
  BREW_ARGS=(--force)
  [[ "${VERBOSE}" == "true" ]] && BREW_ARGS+=(--verbose)
  brew untap "${BREW_ARGS[@]}" "${TAP_NAME}" || echo "Tap not found or already removed."
  exit 0
fi

if [[ ! -f "${CASK_FILE}" ]]
then
  echo "Error: Cask file ${CASK_FILE} not found."
  exit 1
fi

# Setup temporary tap if not already present
# We use the current directory as the tap source
echo "Setting up local tap ${TAP_NAME}..."
brew_taps="$(brew tap)" || true
if ! grep -q "${TAP_NAME}" <<<"${brew_taps}"
then
  CURRENT_DIR="$(pwd)"
  brew tap "${TAP_NAME}" "${CURRENT_DIR}"
fi

# Get the tap directory
REPO_DIR="$(brew --repository)"
TAP_SUBDIR="$(echo "${TAP_NAME}" | awk -F/ '{print $1 "/homebrew-" $2}')"
TAP_PATH="${REPO_DIR}/Library/Taps/${TAP_SUBDIR}"

# Copy the cask file to the tap directory to ensure we test the latest local changes
echo "Copying ${CASK_FILE} to ${TAP_PATH}/Casks/..."
cp "${CASK_FILE}" "${TAP_PATH}/Casks/"

echo "Running ${COMMAND} for ${FULL_CASK_NAME}..."

case "${COMMAND}" in
  install)
    BREW_ARGS=(--cask)
    [[ "${VERBOSE}" == "true" ]] && BREW_ARGS+=(--verbose)
    brew install "${BREW_ARGS[@]}" "${FULL_CASK_NAME}" "$@"
    ;;
  audit)
    BREW_ARGS=(--cask)
    [[ "${VERBOSE}" == "true" ]] && BREW_ARGS+=(--verbose)
    brew audit "${BREW_ARGS[@]}" "${FULL_CASK_NAME}" "$@"
    ;;
  livecheck)
    BREW_ARGS=()
    [[ "${VERBOSE}" == "true" ]] && BREW_ARGS+=(--verbose)
    brew livecheck "${BREW_ARGS[@]}" "${FULL_CASK_NAME}" "$@"
    ;;
  *)
    echo "Unknown command: ${COMMAND}"
    exit 1
    ;;
esac

if [[ "${KEEP}" == "true" ]]
then
  echo "Skipping cleanup as requested."
else
  echo "Cleaning up..."
  if [[ "${COMMAND}" == "install" ]]
  then
    BREW_ARGS=(--cask)
    [[ "${VERBOSE}" == "true" ]] && BREW_ARGS+=(--verbose)
    brew uninstall "${BREW_ARGS[@]}" "${FULL_CASK_NAME}" || true
  fi
  # For all commands (including install), we untap if not keeping
  echo "Removing temporary tap..."
  BREW_ARGS=(--force)
  [[ "${VERBOSE}" == "true" ]] && BREW_ARGS+=(--verbose)
  brew untap "${BREW_ARGS[@]}" "${TAP_NAME}" || true
  echo "Cleanup complete."
fi

echo "Done."
