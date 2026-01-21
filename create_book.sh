#!/bin/bash
# create_book.sh - Simulates the PDF/EPUB generation

# Output directory
OUTPUT_DIR="export"

mkdir -p "$OUTPUT_DIR"

# Simulate creating files
echo "Generating PDF..."
date > "$OUTPUT_DIR/Receptbok.pdf" # Dummy file content

echo "Generating EPUB..."
date > "$OUTPUT_DIR/Receptbok.epub" # Dummy file content

# NOTE: In production, you would use pandoc commands like:
# pandoc metadata.yaml */*.md -o "$OUTPUT_DIR/Receptbok.pdf" --pdf-engine=tectonic
# pandoc metadata.yaml */*.md -o "$OUTPUT_DIR/Receptbok.epub"

echo "Book build complete in $OUTPUT_DIR"
