#!/usr/bin/env bash

echo "Auditing Casks..."
echo "================"

echo "Setting up temporary tap for auditing at $(brew --repository)/Library/Taps/homebrew-releaser/homebrew-test/Casks..."
brew tap-new --verbose --no-git homebrew-releaser/test

mkdir -p "$(brew --repository)"/Library/Taps/homebrew-releaser/homebrew-test/Casks

cp -rv Casks/* "$(brew --repository)"/Library/Taps/homebrew-releaser/homebrew-test/Casks

for file in "$(brew --repository)"/Library/Taps/homebrew-releaser/homebrew-test/Casks/*
do
    echo "Auditing Cask: homebrew-releaser/test/$(basename "${file%.rb}")"
    brew audit --cask "homebrew-releaser/test/$(basename "${file%.rb}")"
done

echo "Cleaning up temporary tap..."
brew untap --verbose --force homebrew-releaser/test

echo "Audit complete."
echo "================"
