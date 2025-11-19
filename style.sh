#!/usr/bin/env bash

echo "Formatting Casks..."
echo "================"

for file in Casks/*
do
    echo "Running style fix for cask file: $(basename "${file%.rb}")"
    brew style --fix "Casks/$(basename "${file%.rb}")"
done

echo "Formatting complete."
echo "================"
