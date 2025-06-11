#!/bin/bash

# БЫСТРОЕ ПЕРЕИМЕНОВАНИЕ В .txt для передачи в чат нейронки

# Path to the lib directory
LIB_DIR="./lib"

# Find all .dart files in the lib directory and its subdirectories
find "$LIB_DIR" -type f -name "*.dart" | while read -r file; do
    # Rename each .dart file to .dart.txt
    mv "$file" "${file}.txt"
    echo "Renamed: $file -> ${file}.txt"
done