#!/bin/bash

# Скрипт для создания детального графа зависимостей проекта Flutter/Dart.
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
    nodesep=0.6;           // Расстояние между узлами
    ranksep=1.0;           // Расстояние между уровнями
    overlap=false;         // Предотвращение наложения
    sep="+8";              // Дополнительное разделение элементов
    
EOF

echo "Анализ зависимостей проекта..."

# Создание временного файла для хранения всех узлов и связей
temp_nodes=$(mktemp)
temp_edges=$(mktemp)
temp_clusters=$(mktemp)

# Определение цветов и описаний для разных групп
declare -A group_colors=(
    # Domain Layer
    ["domain_entities"]="#E8F5E8"
    ["domain_repositories"]="#E3F2FD"
    ["domain_use_cases"]="#F3E5F5"
    
    # Presentation Layer
    ["presentation_view_models"]="#FFF3E0"
    
    # UI Layer
    ["main_screen_main"]="#FFEBEE"
    ["main_screen_menubar"]="#F1F8E9"
    ["main_screen_panels"]="#E0F2F1"
    ["main_screen_view_window"]="#FCE4EC"
    
    # Services
    ["servises"]="#FFF8E1"
    
    # Root
    ["root"]="#F5F5F5"
)

declare -A group_border_colors=(
    # Domain Layer
    ["domain_entities"]="#4CAF50"
    ["domain_repositories"]="#2196F3"
    ["domain_use_cases"]="#9C27B0"
    
    # Presentation Layer
    ["presentation_view_models"]="#FF9800"
    
    # UI Layer
    ["main_screen_main"]="#F44336"
    ["main_screen_menubar"]="#8BC34A"
    ["main_screen_panels"]="#009688"
    ["main_screen_view_window"]="#E91E63"
    
    # Services
    ["servises"]="#FFC107"
    
    # Root
    ["root"]="#757575"
)

declare -A group_descriptions=(
    # Domain Layer
    ["domain_entities"]="Сущности бизнес-логики"
    ["domain_repositories"]="Абстракции хранилищ"
    ["domain_use_cases"]="Сценарии использования"
    
    # Presentation Layer
    ["presentation_view_models"]="Модели представления"
    
    # UI Layer
    ["main_screen_main"]="Основной экран"
    ["main_screen_menubar"]="Меню и настройки"
    ["main_screen_panels"]="Панели интерфейса"
    ["main_screen_view_window"]="Окна отображения"
    
    # Services
    ["servises"]="Внешние сервисы"
    
    # Root
    ["root"]="Корневые файлы"
)

# Функция для получения короткого имени файла
get_short_name() {
    local file_path="$1"
    local basename=$(basename "$file_path" .dart)
    echo "$basename"
}

# Функция для определения группы файла
get_group() {
    local file_path="$1"
    local dirname=$(dirname "$file_path")
    
    if [[ "$dirname" == "." ]]; then
        echo "root"
    elif [[ "$file_path" =~ ^domain/entities/ ]]; then
        echo "domain_entities"
    elif [[ "$file_path" =~ ^domain/repositories/ ]]; then
        echo "domain_repositories"
    elif [[ "$file_path" =~ ^domain/use_cases/ ]]; then
        echo "domain_use_cases"
    elif [[ "$file_path" =~ ^presentation/view_models/ ]]; then
        echo "presentation_view_models"
    elif [[ "$file_path" =~ ^main_screen/main_screen\.dart$ ]]; then
        echo "main_screen_main"
    elif [[ "$file_path" =~ ^main_screen/menubar/ ]]; then
        echo "main_screen_menubar"
    elif [[ "$file_path" =~ ^main_screen/panels/ ]]; then
        echo "main_screen_panels"
    elif [[ "$file_path" =~ ^main_screen/view_window/ ]]; then
        echo "main_screen_view_window"
    elif [[ "$file_path" =~ ^servises/ ]]; then
        echo "servises"
    else
        echo "other"
    fi
}

# Функция для получения слоя группы
get_layer() {
    local group="$1"
    
    if [[ "$group" =~ ^domain_ ]]; then
        echo "domain"
    elif [[ "$group" =~ ^presentation_ ]]; then
        echo "presentation"
    elif [[ "$group" =~ ^main_screen_ ]]; then
        echo "ui"
    elif [[ "$group" == "servises" ]]; then
        echo "services"
    else
        echo "root"
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
    group=$(get_group "$clean_file")
    layer=$(get_layer "$group")
    node_name=$(get_node_name "$clean_file")
    
    # Определяем цвета для узла
    fill_color="${group_colors[$group]:-#F5F5F5}"
    border_color="${group_border_colors[$group]:-#757575}"
    
    # Записываем информацию об узле
    echo "$node_name|$clean_file|$short_name|$group|$layer|$fill_color|$border_color" >> "$temp_nodes"
done

# Создание кластеров (группировка по слоям и группам)
echo "Создание кластеров..."
{
    echo "    // Кластеры по слоям и группам"
    echo ""
    
    # Domain Layer
    echo "    subgraph cluster_domain {"
    echo "        label=\"DOMAIN LAYER\\nБизнес-логика и правила\";"
    echo "        style=filled;"
    echo "        fillcolor=\"#FAFAFA\";"
    echo "        color=\"#424242\";"
    echo "        fontname=\"Arial Bold\";"
    echo "        fontsize=14;"
    echo "        penwidth=2;"
    echo ""
    
    # Domain sub-clusters
    for group in domain_entities domain_repositories domain_use_cases; do
        if grep -q "|$group|" "$temp_nodes"; then
            fill_color="${group_colors[$group]}"
            border_color="${group_border_colors[$group]}"
            description="${group_descriptions[$group]}"
            
            echo "        subgraph cluster_$group {"
            echo "            label=\"$description\";"
            echo "            style=filled;"
            echo "            fillcolor=\"$fill_color\";"
            echo "            color=\"$border_color\";"
            echo "            fontname=\"Arial\";"
            echo "            fontsize=11;"
            echo ""
            
            grep "|$group|" "$temp_nodes" | while IFS='|' read -r node_name file_path short_name node_group layer fill_color border_color; do
                echo "            \"$node_name\" [label=\"$short_name\", fillcolor=\"$fill_color\", color=\"$border_color\", style=\"filled,rounded\"];"
            done
            
            echo "        }"
            echo ""
        fi
    done
    
    echo "    }"
    echo ""
    
    # Presentation Layer
    if grep -q "|presentation_view_models|" "$temp_nodes"; then
        echo "    subgraph cluster_presentation {"
        echo "        label=\"PRESENTATION LAYER\\nМодели представления\";"
        echo "        style=filled;"
        echo "        fillcolor=\"#FAFAFA\";"
        echo "        color=\"#424242\";"
        echo "        fontname=\"Arial Bold\";"
        echo "        fontsize=14;"
        echo "        penwidth=2;"
        echo ""
        
        fill_color="${group_colors[presentation_view_models]}"
        border_color="${group_border_colors[presentation_view_models]}"
        description="${group_descriptions[presentation_view_models]}"
        
        echo "        subgraph cluster_presentation_view_models {"
        echo "            label=\"$description\";"
        echo "            style=filled;"
        echo "            fillcolor=\"$fill_color\";"
        echo "            color=\"$border_color\";"
        echo "            fontname=\"Arial\";"
        echo "            fontsize=11;"
        echo ""
        
        grep "|presentation_view_models|" "$temp_nodes" | while IFS='|' read -r node_name file_path short_name node_group layer fill_color border_color; do
            echo "            \"$node_name\" [label=\"$short_name\", fillcolor=\"$fill_color\", color=\"$border_color\", style=\"filled,rounded\"];"
        done
        
        echo "        }"
        echo "    }"
        echo ""
    fi
    
    # UI Layer
    echo "    subgraph cluster_ui {"
    echo "        label=\"UI LAYER\\nПользовательский интерфейс\";"
    echo "        style=filled;"
    echo "        fillcolor=\"#FAFAFA\";"
    echo "        color=\"#424242\";"
    echo "        fontname=\"Arial Bold\";"
    echo "        fontsize=14;"
    echo "        penwidth=2;"
    echo ""
    
    # UI sub-clusters
    for group in main_screen_main main_screen_menubar main_screen_panels main_screen_view_window; do
        if grep -q "|$group|" "$temp_nodes"; then
            fill_color="${group_colors[$group]}"
            border_color="${group_border_colors[$group]}"
            description="${group_descriptions[$group]}"
            
            echo "        subgraph cluster_$group {"
            echo "            label=\"$description\";"
            echo "            style=filled;"
            echo "            fillcolor=\"$fill_color\";"
            echo "            color=\"$border_color\";"
            echo "            fontname=\"Arial\";"
            echo "            fontsize=11;"
            echo ""
            
            grep "|$group|" "$temp_nodes" | while IFS='|' read -r node_name file_path short_name node_group layer fill_color border_color; do
                echo "            \"$node_name\" [label=\"$short_name\", fillcolor=\"$fill_color\", color=\"$border_color\", style=\"filled,rounded\"];"
            done
            
            echo "        }"
            echo ""
        fi
    done
    
    echo "    }"
    echo ""
    
    # Services Layer
    if grep -q "|servises|" "$temp_nodes"; then
        echo "    subgraph cluster_services {"
        echo "        label=\"SERVICES LAYER\\nВнешние сервисы и инфраструктура\";"
        echo "        style=filled;"
        echo "        fillcolor=\"#FAFAFA\";"
        echo "        color=\"#424242\";"
        echo "        fontname=\"Arial Bold\";"
        echo "        fontsize=14;"
        echo "        penwidth=2;"
        echo ""
        
        fill_color="${group_colors[servises]}"
        border_color="${group_border_colors[servises]}"
        description="${group_descriptions[servises]}"
        
        echo "        subgraph cluster_servises {"
        echo "            label=\"$description\";"
        echo "            style=filled;"
        echo "            fillcolor=\"$fill_color\";"
        echo "            color=\"$border_color\";"
        echo "            fontname=\"Arial\";"
        echo "            fontsize=11;"
        echo ""
        
        grep "|servises|" "$temp_nodes" | while IFS='|' read -r node_name file_path short_name node_group layer fill_color border_color; do
            echo "            \"$node_name\" [label=\"$short_name\", fillcolor=\"$fill_color\", color=\"$border_color\", style=\"filled,rounded\"];"
        done
        
        echo "        }"
        echo "    }"
        echo ""
    fi
    
    # Root files
    if grep -q "|root|" "$temp_nodes"; then
        echo "    // Корневые файлы"
        fill_color="${group_colors[root]}"
        border_color="${group_border_colors[root]}"
        
        grep "|root|" "$temp_nodes" | while IFS='|' read -r node_name file_path short_name node_group layer fill_color border_color; do
            echo "    \"$node_name\" [label=\"$short_name\", fillcolor=\"$fill_color\", color=\"$border_color\", style=\"filled,rounded\"];"
        done
        echo ""
    fi
    
} >> "$dot_file"

# Создаем ассоциативный массив для быстрого поиска файлов
declare -A file_exists
while IFS='|' read -r node_name file_path short_name node_group layer fill_color border_color; do
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
            # Обрабатываем относительные пути без ./ и ../
            current_dir=$(dirname "$clean_file")
            
            if [[ "$current_dir" == "." ]]; then
                resolved_path="$import_path"
            else
                full_path="$current_dir/$import_path"
                resolved_path=$(normalize_path "$full_path")
            fi
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
            edge_with_style="${edge%;} [weight=2, penwidth=1.5, color=\"#1976D2\"];"
        else
            edge_with_style="$edge"
        fi
        
        echo "    $edge_with_style"
    done
    echo ""
} >> "$dot_file"

# Завершение DOT файла с улучшенной легендой
cat << 'EOF' >> "$dot_file"
    // Расширенная легенда
    subgraph cluster_legend {
        label="АРХИТЕКТУРНЫЕ СЛОИ";
        style=filled;
        fillcolor="#FFFFFF";
        color="#000000";
        fontname="Arial Bold";
        fontsize=12;
        penwidth=2;
        
        // Настройка расположения легенды
        rank=sink;
        
        // Domain Layer группы
        legend_domain_title [label="DOMAIN LAYER", shape=plaintext, fontname="Arial Bold", fontsize=12];
        legend_entities [label="Entities\nСущности бизнес-логики\n(DroneConfig)", fillcolor="#E8F5E8", color="#4CAF50", style="filled,rounded", fontsize=9];
        legend_repositories [label="Repositories\nАбстракции хранилищ\n(DroneConfigRepository)", fillcolor="#E3F2FD", color="#2196F3", style="filled,rounded", fontsize=9];
        legend_use_cases [label="Use Cases\nСценарии использования\n(ManageDronesUseCase)", fillcolor="#F3E5F5", color="#9C27B0", style="filled,rounded", fontsize=9];
        
        // Presentation Layer
        legend_presentation_title [label="PRESENTATION LAYER", shape=plaintext, fontname="Arial Bold", fontsize=12];
        legend_view_models [label="View Models\nМодели представления\n(MainScreenViewModel)", fillcolor="#FFF3E0", color="#FF9800", style="filled,rounded", fontsize=9];
        
        // UI Layer группы
        legend_ui_title [label="UI LAYER", shape=plaintext, fontname="Arial Bold", fontsize=12];
        legend_main_screen [label="Main Screen\nОсновной экран\n(MainScreen)", fillcolor="#FFEBEE", color="#F44336", style="filled,rounded", fontsize=9];
        legend_menubar [label="Menu & Settings\nМеню и настройки\n(DroneMenuBar)", fillcolor="#F1F8E9", color="#8BC34A", style="filled,rounded", fontsize=9];
        legend_panels [label="Panels\nПанели интерфейса\n(StatusPanel)", fillcolor="#E0F2F1", color="#009688", style="filled,rounded", fontsize=9];
        legend_view_window [label="View Windows\nОкна отображения\n(MainWindow)", fillcolor="#FCE4EC", color="#E91E63", style="filled,rounded", fontsize=9];
        
        // Services Layer
        legend_services_title [label="SERVICES LAYER", shape=plaintext, fontname="Arial Bold", fontsize=12];
        legend_services [label="Services\nВнешние сервисы\n(WebSocketService)", fillcolor="#FFF8E1", color="#FFC107", style="filled,rounded", fontsize=9];
        
        // Root
        legend_root_title [label="ROOT FILES", shape=plaintext, fontname="Arial Bold", fontsize=12];
        legend_root [label="Root Files\nКорневые файлы\n(main.dart, di.dart)", fillcolor="#F5F5F5", color="#757575", style="filled,rounded", fontsize=9];
        
        // Скрываем рёбра в легенде, но создаем структуру
        legend_domain_title -> legend_entities [style=invis];
        legend_entities -> legend_repositories [style=invis];
        legend_repositories -> legend_use_cases [style=invis];
        
        legend_use_cases -> legend_presentation_title [style=invis];
        legend_presentation_title -> legend_view_models [style=invis];
        
        legend_view_models -> legend_ui_title [style=invis];
        legend_ui_title -> legend_main_screen [style=invis];
        legend_main_screen -> legend_menubar [style=invis];
        legend_menubar -> legend_panels [style=invis];
        legend_panels -> legend_view_window [style=invis];
        
        legend_view_window -> legend_services_title [style=invis];
        legend_services_title -> legend_services [style=invis];
        
        legend_services -> legend_root_title [style=invis];
        legend_root_title -> legend_root [style=invis];
    }
}
EOF

echo "DOT файл создан: $dot_file"

# Создание изображения графа
if [ "$create_image" = true ]; then
    echo "Создание PNG изображения..."
    if dot -Tpng "$dot_file" -o "$png_file" -Gdpi=300 2>/dev/null; then
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
    echo "  dot -Tpng \"$dot_file\" -o \"$png_file\" -Gdpi=300"
    echo "  dot -Tsvg \"$dot_file\" -o \"$svg_file\""
fi

# Очистка временных файлов
rm -f "$temp_nodes" "$temp_edges" "$temp_clusters"

echo ""
echo "Детальный граф зависимостей готов!"
echo "Файлы созданы в директории: $metadata_dir"
echo "- DOT исходник: dependency_graph.dot"
if [ "$create_image" = true ]; then
    echo "- PNG изображение: dependency_graph.png (высокое разрешение)"
    echo "- SVG изображение: dependency_graph.svg"
fi
echo ""
echo "Граф содержит детальную группировку по архитектурным слоям:"
echo "• Domain Layer: entities, repositories, use cases"
echo "• Presentation Layer: view models"
echo "• UI Layer: main screen, menubar, panels, view windows"
echo "• Services Layer: внешние сервисы"
echo "• Root Files: точки входа и конфигурация"