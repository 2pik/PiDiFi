#!/bin/bash
# Скрипт для скачивания всех зависимостей в локальную папку
# Используется для создания офлайн-установщика

set -e

DEPS_DIR="./offline_deps"
PYTHON_VERSION="3.12"

echo "📦 Подготовка офлайн-зависимостей для macOS..."

# Очистка предыдущих загрузок
rm -rf "$DEPS_DIR"
mkdir -p "$DEPS_DIR"

# Определяем платформу
PLATFORM=$(python3 -c "import platform; print(f'{platform.system().lower()}-{platform.machine().lower()}')")
echo "🎯 Платформа: $PLATFORM"

# Скачиваем wheel-пакеты для всех зависимостей
echo "⬇️  Загрузка зависимостей..."
pip3 download --only-binary=:all: \
    --platform macosx_11_0_arm64 \
    --python-version 3.12 \
    --implementation cp \
    --abi cp312 \
    -d "$DEPS_DIR" \
    -r requirements.txt

# Также скачиваем для x86_64 (Intel Mac)
echo "⬇️  Загрузка зависимостей для Intel Mac..."
pip3 download --only-binary=:all: \
    --platform macosx_11_0_x86_64 \
    --python-version 3.12 \
    --implementation cp \
    --abi cp312 \
    -d "$DEPS_DIR" \
    -r requirements.txt

# Копируем requirements.txt
cp requirements.txt "$DEPS_DIR/"

echo "✅ Зависимости загружены в $DEPS_DIR"
echo "📊 Количество файлов: $(ls -1 $DEPS_DIR/*.whl 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "Размер пакета: $(du -sh $DEPS_DIR | cut -f1)"
