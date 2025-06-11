#!/bin/bash

# Скрипт для получения структуры проекта и фолдинга кода.
# Структура проекта сохраняется в project_structure.txt, фолдинг кода — в code_folding.txt.
# Все файлы сохраняются в корневую директорию проекта (на уровень выше lib/).
# Исключаются файлы test.*.
# Фолдинг кода: импорты (2 пробела), классы и их комментарии (2 пробела), методы (4 пробела), 
# комментарии к методам (2 пробела, на одну табуляцию меньше, чем методы).
# Пустая строка добавляется между блоками файлов.

# Определение путей к выходным файлам в корневой директории проекта
output_dir=".."
structure_file="$output_dir/metadata/project_structure.txt"
folding_file="$output_dir/metadata/code_folding.txt"
code_rows_file="$output_dir/metadata/code_rows.txt"

# Переход в директорию lib/
cd lib/ || { echo "Ошибка: директория lib/ не найдена"; exit 1; }

# Подсчет строк кода с помощью cloc
cloc . --by-file > "$code_rows_file"

# Проверка наличия команды tree
if ! command -v tree &> /dev/null; then
    echo "Команда 'tree' не найдена. Установите её (например, 'sudo apt install tree' или 'brew install tree'). Используется ls -R."
    fallback=true
else
    fallback=false
fi

# Очистка или создание выходных файлов
> "$structure_file"
> "$folding_file"

# Запись структуры директорий в project_structure.txt
echo "Структура проекта (lib/):" >> "$structure_file"
echo "------------------------" >> "$structure_file"
if [ "$fallback" = true ]; then
    ls -R "$(pwd)" | grep -v '^test\.' >> "$structure_file"
else
    tree -I 'test.*' --noreport >> "$structure_file"
fi

# Запись информации о фолдинге кода в code_folding.txt
echo "Детали фолдинга кода:" >> "$folding_file"
echo "------------------------" >> "$folding_file"

# Поиск всех Dart файлов, исключая test.*, и анализ их содержимого
find . -type f -name "*.dart" ! -name "test.*" | while read -r file; do
    echo "Файл: $file" >> "$folding_file"
    # Извлечение импортов
    grep -E "^import[[:space:]]" "$file" | sed 's/^/  /' >> "$folding_file"
    
    # Извлечение классов и их методов (кроме initState, dispose и build) с комментариями ///
    awk '
    BEGIN {
        brace_count=0;
        in_class=0;
        class_name="";
        comment_lines=0;
        comments[0]="";  # Массив для хранения строк комментариев
    }
    /{/ {brace_count++}
    /}/ {brace_count--; if (brace_count == 0) in_class=0}
    /^[[:space:]]*\/\/\/.*/ {
        if (comment_lines < 3) {  # Ограничение до 3 строк комментариев
            comments[comment_lines]=$0;
            comment_lines++;
        }
    }
    /^[[:space:]]*(abstract[[:space:]]+)?class[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*(extends|implements|{|$)/ {
        in_class=1;
        for (i=0; i<comment_lines; i++) {
            print "  " comments[i];  # Вывод комментариев к классам с отступом 2 пробела
        }
        comment_lines=0;
        sub(/^[[:space:]]*/, "");
        sub(/{.*$/, "");
        class_name=$0;
        print "  " class_name;
    }
    /^[[:space:]]*(([@][a-zA-Z]+[[:space:]]*)?(async[[:space:]]*)?([a-zA-Z_][a-zA-Z0-9_]*[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\([^)]*\)[[:space:]]*(async)?[[:space:]]*{)/ {
        if (in_class && brace_count <= 2 && !/initState[[:space:]]*\(/ && !/dispose[[:space:]]*\(/ && !/build[[:space:]]*\(/) {
            for (i=0; i<comment_lines; i++) {
                print "  " comments[i];  # Вывод комментариев к методам с отступом 2 пробела
            }
            comment_lines=0;
            sub(/^[[:space:]]*/, "");
            sub(/{.*$/, "");
            print "    " $0;
        }
    }
    !/^[[:space:]]*\/\/\/.*/ {comment_lines=0}
    ' "$file" >> "$folding_file"
    echo "" >> "$folding_file"  # Добавление пустой строки между блоками файлов
done

echo "Структура проекта сохранена в $structure_file"
echo "Информация о фолдинге кода сохранена в $folding_file"
echo "Подсчет строк кода сохранен в $code_rows_file"
