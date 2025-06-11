#!/bin/bash

# Путь к папке lib
LIB_DIR="./lib"

# Находим все файлы с расширением .dart.txt и переименовываем их обратно в .dart
find "$LIB_DIR" -type f -name "*.dart.txt" | while read -r file; do
    # Удаляем .txt из имени файла
    new_name="${file%.txt}"
    mv "$file" "$new_name"
    echo "Переименован: $file -> $new_name"
done