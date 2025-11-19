#!/usr/bin/env bash

# Usage: ./test-cask.sh <cask_name> [options]
# Options:
#   --keep      Do not uninstall after installation (useful for manual testing)
#   --cleanup   Only run cleanup for the specified cask
#   --untap     Only remove the temporary tap

set -e

TAP_NAME="bogdan-d/local-test"

if [[ -z "$1" ]]; then
    echo "Usage: ./test-cask.sh <cask_name> [--keep] [--cleanup] [--untap]"
    exit 1
fi

CASK_NAME=$1
shift

KEEP=false
CLEANUP_ONLY=false
UNTAP_ONLY=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --keep) KEEP=true ;;
        --cleanup) CLEANUP_ONLY=true ;;
        --untap) UNTAP_ONLY=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Handle .rb extension if provided
CASK_NAME=${CASK_NAME%.rb}
CASK_FILE="Casks/$CASK_NAME.rb"

if [[ "$UNTAP_ONLY" == "true" ]]; then
    echo "Removing temporary tap $TAP_NAME..."
    brew untap "$TAP_NAME" || echo "Tap not found or already removed."
    exit 0
fi

if [[ "$CLEANUP_ONLY" == "true" ]]; then
    echo "Cleaning up $TAP_NAME/$CASK_NAME..."
    brew uninstall --cask "$TAP_NAME/$CASK_NAME" || echo "Not installed or uninstall failed."
    echo "Removing temporary tap..."
    brew untap "$TAP_NAME" || echo "Tap not found or already removed."
    exit 0
fi

if [[ ! -f "$CASK_FILE" ]]; then
    echo "Error: Cask file $CASK_FILE not found."
    exit 1
fi

# Setup temporary tap if not already present
TAP_PATH="$(brew --repository)/Library/Taps/$(echo "$TAP_NAME" | awk -F/ '{print $1 "/homebrew-" $2}')"

if ! brew tap | grep -q "$TAP_NAME"; then
    echo "Setting up temporary tap $TAP_NAME..."
    brew tap "$TAP_NAME" "$(pwd)"
    cd "$TAP_PATH"
    git add -A
    git commit -m "Local testing changes" || true
    cd - > /dev/null
else
    echo "Temporary tap $TAP_NAME already exists. Updating..."
    cd "$TAP_PATH"
    git pull
    git add -A
    git commit -m "Local testing changes" || true
    cd - > /dev/null
fi

echo "Installing $TAP_NAME/$CASK_NAME..."
# Use --verbose for better debugging as per AGENTS.md
brew install --cask --verbose "$TAP_NAME/$CASK_NAME"

echo "Installation successful!"

if [[ "$KEEP" == "true" ]]; then
    echo "Skipping cleanup as requested. You can remove it later with:"
    echo "  ./test-cask.sh $CASK_NAME --cleanup"
else
    echo "Cleaning up..."
    brew uninstall --cask "$TAP_NAME/$CASK_NAME"
    echo "Removing temporary tap..."
    brew untap --force --verbose "$TAP_NAME"
    echo "Cleanup complete."
fi
