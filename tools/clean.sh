#!/bin/bash
# X68000 Clean Script
# Removes all build artifacts

cd "$(dirname "$0")/.."
make clean
echo "Clean complete!"
