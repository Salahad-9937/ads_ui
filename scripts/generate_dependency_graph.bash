#!/bin/bash

# Скрипт для создания графа зависимостей проекта Flutter/Dart.
# Анализирует импорты в .dart файлах и создает визуальный граф с помощью Graphviz.
# Граф сохраняется в формате DOT и PNG в директории metadata/.
# Исключаются файлы test.* и внешние зависимости (package:flutter, package:*).

# Определение путей к выходным файлам
output_dir=".."
metadata_dir="$output_dir/metadata"
dot_file="$metadata_dir/dependency_graph.dot"
png_file="$metadata_dir/dependency_graph.png"
svg_file="$metadata_dir/dependency_graph.svg"

# Создание директории metadata, если она не существует
mkdir -p "$metadata_dir"

# Переход в директорию lib/
cd lib/ || { echo "Ошибка: директория lib/ не найдена"; exit 1; }

# Проверка наличия команды dot (Graphviz)
if ! command -v dot &> /dev/null; then
    echo "Команда 'dot' (Graphviz) не найдена."
    echo "Установите Graphviz:"
    echo "  Ubuntu/Debian: sudo apt install graphviz"
    echo "  macOS: brew install graphviz"
    echo "  Windows: choco install graphviz или скачайте с https://graphviz.org/download/"
    echo ""
    echo "Будет создан только DOT файл без изображения."
    create_image=false
else
    create_image=true
fi

# Очистка или создание выходного файла
> "$dot_file"

# Начало DOT файла
cat << 'EOF' >> "$dot_file"
digraph DependencyGraph {
    // Настройки графа
    rankdir=TB;
    node [shape=box, style=rounded, fontname="Arial", fontsize=10];
    edge [fontname="Arial", fontsize=8, color="#666666"];
    
    // Настройки кластеров (группировка по папкам)
    compound=true;
    
    // Настройки для предотвращения наложения стрелок
    splines=ortho;          // Ортогональные линии (прямые углы)
    concentrate=true;       // Объединение стрелок к одному узлу
    nodesep=0.8;           // Расстояние между узлами
    ranksep=1.2;           // Расстояние между уровнями
    overlap=false;         // Предотвращение наложения
    sep="+10";             // Дополнительное разделение элементов
    
EOF

echo "Анализ зависимостей проекта..."

# Создание временного файла для хранения всех узлов и связей
temp_nodes=$(mktemp)
temp_edges=$(mktemp)
temp_clusters=$(mktemp)

# Определение цветов для разных типов файлов/папок
declare -A folder_colors=(
    ["domain"]="#E3F2FD"      # Светло-синий
    ["presentation"]="#F3E5F5" # Светло-фиолетовый
    ["main_screen"]="#E8F5E8"  # Светло-зеленый
    ["servises"]="#FFF3E0"     # Светло-оранжевый
    ["root"]="#F5F5F5"         # Светло-серый
)

declare -A folder_border_colors=(
    ["domain"]="#1976D2"
    ["presentation"]="#7B1FA2"
    ["main_screen"]="#388E3C"
    ["servises"]="#F57C00"
    ["root"]="#616161"
)

# Функция для получения короткого имени файла
get_short_name() {
    local file_path="$1"
    local basename=$(basename "$file_path" .dart)
    echo "$basename"
}

# Функция для получения папки файла
get_folder() {
    local file_path="$1"
    local dirname=$(dirname "$file_path")
    if [[ "$dirname" == "." ]]; then
        echo "root"
    else
        echo "${dirname%%/*}"  # Берем только первую папку
    fi
}

# Функция для создания имени узла
get_node_name() {
    local file_path="$1"
    echo "$(echo "$file_path" | sed 's/[^a-zA-Z0-9_]/_/g')"
}

# Функция для нормализации пути
normalize_path() {
    local path="$1"
    # Убираем ./ в начале
    path="${path#./}"
    # Разбиваем путь на части
    IFS='/' read -ra PARTS <<< "$path"
    local normalized=()
    
    for part in "${PARTS[@]}"; do
        if [[ "$part" == ".." ]]; then
            # Убираем последний элемент из normalized
            if [[ ${#normalized[@]} -gt 0 ]]; then
                unset 'normalized[-1]'
                normalized=("${normalized[@]}")  # Пересобираем массив
            fi
        elif [[ "$part" != "." && "$part" != "" ]]; then
            normalized+=("$part")
        fi
    done
    
    # Соединяем части обратно
    local result=""
    for ((i=0; i<${#normalized[@]}; i++)); do
        if [[ $i -eq 0 ]]; then
            result="${normalized[i]}"
        else
            result="$result/${normalized[i]}"
        fi
    done
    echo "$result"
}

# Сбор всех Dart файлов и создание узлов
echo "Сбор файлов проекта..."
find . -type f -name "*.dart" ! -name "test.*" | while read -r file; do
    # Убираем ./ в начале пути
    clean_file="${file#./}"
    short_name=$(get_short_name "$clean_file")
    folder=$(get_folder "$clean_file")
    node_name=$(get_node_name "$clean_file")
    
    # Определяем цвета для узла
    fill_color="${folder_colors[$folder]:-#F5F5F5}"
    border_color="${folder_border_colors[$folder]:-#616161}"
    
    # Записываем информацию об узле
    echo "$node_name|$clean_file|$short_name|$folder|$fill_color|$border_color" >> "$temp_nodes"
done

# Создание кластеров (группировка по папкам)
echo "Создание кластеров..."
{
    echo "    // Кластеры по папкам"
    
    # Получаем уникальные папки
    cut -d'|' -f4 "$temp_nodes" | sort -u | while read -r folder; do
        if [[ "$folder" != "root" ]]; then
            fill_color="${folder_colors[$folder]:-#F5F5F5}"
            border_color="${folder_border_colors[$folder]:-#616161}"
            
            echo "    subgraph \"cluster_$folder\" {"
            echo "        label=\"$folder/\";"
            echo "        style=filled;"
            echo "        fillcolor=\"$fill_color\";"
            echo "        color=\"$border_color\";"
            echo "        fontname=\"Arial Bold\";"
            echo "        fontsize=12;"
            echo ""
            
            # Добавляем узлы этой папки в кластер
            grep "|$folder|" "$temp_nodes" | while IFS='|' read -r node_name file_path short_name node_folder fill_color border_color; do
                echo "        \"$node_name\" [label=\"$short_name\", fillcolor=\"$fill_color\", color=\"$border_color\", style=\"filled,rounded\"];"
            done
            
            echo "    }"
            echo ""
        fi
    done
    
    # Добавляем root узлы отдельно
    echo "    // Root файлы"
    grep "|root|" "$temp_nodes" | while IFS='|' read -r node_name file_path short_name node_folder fill_color border_color; do
        echo "    \"$node_name\" [label=\"$short_name\", fillcolor=\"$fill_color\", color=\"$border_color\", style=\"filled,rounded\"];"
    done
    echo ""
    
} >> "$dot_file"

# Создаем ассоциативный массив для быстрого поиска файлов
declare -A file_exists
while IFS='|' read -r node_name file_path short_name node_folder fill_color border_color; do
    file_exists["$file_path"]=1
done < "$temp_nodes"

# Анализ зависимостей и создание рёбер
echo "Анализ импортов и создание связей..."
find . -type f -name "*.dart" ! -name "test.*" | while read -r file; do
    clean_file="${file#./}"
    from_node=$(get_node_name "$clean_file")
    
    # Извлекаем все импорты из файла
    grep -E "^[[:space:]]*import[[:space:]]" "$file" | while read -r import_line; do
        # Извлекаем путь импорта, поддерживая как одинарные, так и двойные кавычки
        import_path=$(echo "$import_line" | sed -n "s/^[[:space:]]*import[[:space:]]*['\"]\\([^'\"]*\\)['\"].*/\\1/p")
        
        # Пропускаем пустые импорты
        if [[ -z "$import_path" ]]; then
            continue
        fi
        
        # Пропускаем внешние пакеты (кроме собственных)
        if [[ "$import_path" =~ ^package: ]]; then
            # Проверяем, не является ли это импортом из собственного пакета
            if [[ ! "$import_path" =~ ^package:[^/]*/lib/ ]]; then
                continue
            else
                # Убираем package:xxx/lib/ префикс для собственных пакетов
                import_path="${import_path#package:*/lib/}"
            fi
        fi
        
        # Обрабатываем относительные импорты
        if [[ "$import_path" =~ ^\.\./ ]] || [[ "$import_path" =~ ^\./ ]]; then
            # Получаем директорию текущего файла
            current_dir=$(dirname "$clean_file")
            
            # Объединяем текущую директорию с относительным путем
            if [[ "$current_dir" == "." ]]; then
                full_path="$import_path"
            else
                full_path="$current_dir/$import_path"
            fi
            
            # Нормализуем путь
            resolved_path=$(normalize_path "$full_path")
        else
            # Абсолютный путь от корня lib/
            resolved_path="$import_path"
        fi
        
        # Проверяем, существует ли целевой файл в нашем списке
        if [[ -n "${file_exists[$resolved_path]}" ]]; then
            to_node=$(get_node_name "$resolved_path")
            echo "\"$from_node\" -> \"$to_node\";" >> "$temp_edges"
        fi
    done
done

# Добавляем рёбра в DOT файл
{
    echo "    // Зависимости"
    # Убираем дубликаты и сортируем рёбра
    sort -u "$temp_edges" | while read -r edge; do
        # Определяем важность связи на основе типа узлов
        from_node=$(echo "$edge" | cut -d' ' -f1 | tr -d '"')
        to_node=$(echo "$edge" | cut -d' ' -f3 | tr -d '"' | tr -d ';')
        
        # Если связь идет к domain entity или use case, делаем её более заметной
        if [[ "$to_node" =~ domain.*entities ]] || [[ "$to_node" =~ domain.*use_cases ]]; then
            edge_with_style="${edge%;} [weight=2, penwidth=1];"
        else
            edge_with_style="$edge"
        fi
        
        echo "    $edge_with_style"
    done
    echo ""
} >> "$dot_file"

# Завершение DOT файла
cat << 'EOF' >> "$dot_file"
    // Легенда
    subgraph cluster_legend {
        label="Типы компонентов";
        style=filled;
        fillcolor="#FFFFFF";
        color="#000000";
        fontname="Arial Bold";
        fontsize=12;
        
        legend_domain [label="Domain Layer", fillcolor="#E3F2FD", color="#1976D2", style="filled,rounded"];
        legend_presentation [label="Presentation", fillcolor="#F3E5F5", color="#7B1FA2", style="filled,rounded"];
        legend_ui [label="UI Components", fillcolor="#E8F5E8", color="#388E3C", style="filled,rounded"];
        legend_services [label="Services", fillcolor="#FFF3E0", color="#F57C00", style="filled,rounded"];
        legend_root [label="Root Files", fillcolor="#F5F5F5", color="#616161", style="filled,rounded"];
        
        // Скрываем рёбра в легенде
        legend_domain -> legend_presentation [style=invis];
        legend_presentation -> legend_ui [style=invis];
        legend_ui -> legend_services [style=invis];
        legend_services -> legend_root [style=invis];
    }
}
EOF

echo "DOT файл создан: $dot_file"

# Создание изображения графа
if [ "$create_image" = true ]; then
    echo "Создание PNG изображения..."
    if dot -Tpng "$dot_file" -o "$png_file" 2>/dev/null; then
        echo "PNG граф создан: $png_file"
    else
        echo "Ошибка при создании PNG файла"
    fi
    
    echo "Создание SVG изображения..."
    if dot -Tsvg "$dot_file" -o "$svg_file" 2>/dev/null; then
        echo "SVG граф создан: $svg_file"
    else
        echo "Ошибка при создании SVG файла"
    fi
else
    echo "Для создания изображения установите Graphviz и запустите:"
    echo "  dot -Tpng \"$dot_file\" -o \"$png_file\""
    echo "  dot -Tsvg \"$dot_file\" -o \"$svg_file\""
fi

# Очистка временных файлов
rm -f "$temp_nodes" "$temp_edges" "$temp_clusters"

echo ""
echo "Граф зависимостей готов!"
echo "Файлы созданы в директории: $metadata_dir"
echo "- DOT исходник: dependency_graph.dot"
if [ "$create_image" = true ]; then
    echo "- PNG изображение: dependency_graph.png"
    echo "- SVG изображение: dependency_graph.svg"
fi