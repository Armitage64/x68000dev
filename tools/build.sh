#!/bin/bash
# X68000 Build Script
# Builds the X68000 program using the Makefile

set -e

cd "$(dirname "$0")/.."

echo "Cleaning build directory..."
make clean

echo "Building X68000 program..."
make all

echo "Build complete!"
