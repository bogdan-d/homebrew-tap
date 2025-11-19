#!/usr/bin/env bash

echo "Formatting Casks..."
echo "================"

for file in Casks/*
do
  echo "Running style fix for cask file: ${file}"
  brew style --fix "${file}"
done

echo "Formatting complete."
echo "================"
