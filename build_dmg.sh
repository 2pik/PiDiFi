#!/bin/bash
# Скрипт создания установочного DMG файла для macOS
# Вдохновлен лучшими практиками umputun
# Поддерживает офлайн-установку с локальными зависимостями
# Создает один установочный файл .dmg с иконкой и возможностью удаления в корзину

set -e

# Определяем директорию скрипта (абсолютный путь)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Используем абсолютные пути для всех переменных
APP_NAME="PDFToPPTXConverter"
VERSION="2.2.0"
BUILD_DIR="${SCRIPT_DIR}/build_installer"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_FILE="${SCRIPT_DIR}/${APP_NAME}-${VERSION}.dmg"
VOLUME_NAME="${APP_NAME} v${VERSION}"
OFFLINE_DEPS_DIR="${SCRIPT_DIR}/offline_deps"
TEMP_DMG="/tmp/${APP_NAME}_temp.dmg"

# Определяем путь к Python
PYTHON_CMD="python3"

echo "📦 Создание установочного DMG файла..."
echo "   Директория скрипта: ${SCRIPT_DIR}"

# Очистка предыдущей сборки
echo "🧹 Очистка предыдущей сборки..."
rm -rf "$BUILD_DIR"
rm -f "$DMG_FILE"
rm -f "$TEMP_DMG"

# Переходим в директорию скрипта
cd "$SCRIPT_DIR"

# Экспортируем SCRIPT_DIR для использования в Python-скриптах
export SCRIPT_DIR

# Функция проверки модуля
check_module() {
    $PYTHON_CMD -c "import $1" 2>/dev/null
    return $?
}

# ПРИНУДИТЕЛЬНАЯ установка зависимостей ПЕРЕД любыми другими действиями
echo "🔍 Проверка и установка зависимостей..."

# Проверяем, что нужно установить
NEEDS_INSTALL=false
if ! check_module fitz || ! check_module pptx; then
    NEEDS_INSTALL=true
fi

if [ "$NEEDS_INSTALL" = true ]; then
    echo "📦 Установка необходимых библиотек..."
    
    # Сначала пробуем offline_deps
    if [ -d "$OFFLINE_DEPS_DIR" ] && [ "$(ls -A $OFFLINE_DEPS_DIR/*.whl 2>/dev/null)" ]; then
        echo "   📥 Установка из локальных wheel файлов..."
        python3 offline_installer.py || true
    fi
    
    # Проверяем снова
    if ! check_module fitz || ! check_module pptx; then
        echo "   🌐 Установка через pip3..."
        pip3 install --quiet --upgrade PyMuPDF python-pptx
    fi
    
    # Финальная проверка
    if ! check_module fitz; then
        echo "❌ Критическая ошибка: не удалось установить PyMuPDF"
        exit 1
    fi
    if ! check_module pptx; then
        echo "❌ Критическая ошибка: не удалось установить python-pptx"
        exit 1
    fi
    
    echo "✅ Все зависимости успешно установлены"
else
    echo "✅ Все зависимости уже установлены"
fi

# Создание структуры приложения
echo "📁 Создание структуры приложения..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Создание Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>PDF в PPTX Конвертер</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.pdftopptxconverter</string>
    <key>CFBundleExecutable</key>
    <string>Launcher</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
PLIST_EOF

# Создание лаунчера
cat > "$APP_BUNDLE/Contents/MacOS/Launcher" << 'LAUNCHER_EOF'
#!/bin/bash
# Лаунчер приложения PDFToPPTXConverter

SCRIPT_DIR="$(cd "$(dirname "$0")/../Resources" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/pdf_to_pptx_gui.py"
OFFLINE_DEPS_DIR="$SCRIPT_DIR/offline_deps"

# Проверка наличия Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Ошибка: Python 3 не найден."
    echo ""
    echo "Пожалуйста, установите Python 3 с сайта python.org или через Homebrew:"
    echo "brew install python3"
    exit 1
fi

# Функция проверки модуля
check_module() {
    python3 -c "import $1" 2>/dev/null
    return $?
}

# Проверка зависимостей
MISSING_MODULES=""
if ! check_module fitz; then
    MISSING_MODULES="$MISSING_MODULES PyMuPDF"
fi
if ! check_module pptx; then
    MISSING_MODULES="$MISSING_MODULES python-pptx"
fi

# Если есть отсутствующие модули, пробуем установить из offline_deps
if [ -n "$MISSING_MODULES" ]; then
    echo "⚠️  Отсутствуют модули:$MISSING_MODULES"
    
    if [ -d "$OFFLINE_DEPS_DIR" ] && [ "$(ls -A $OFFLINE_DEPS_DIR/*.whl 2>/dev/null)" ]; then
        echo "📦 Попытка установки из локальных wheel файлов..."
        python3 "$SCRIPT_DIR/offline_installer.py"
        
        # Повторная проверка
        MISSING_MODULES=""
        if ! check_module fitz; then
            MISSING_MODULES="$MISSING_MODULES PyMuPDF"
        fi
        if ! check_module pptx; then
            MISSING_MODULES="$MISSING_MODULES python-pptx"
        fi
        
        if [ -n "$MISSING_MODULES" ]; then
            osascript -e "display dialog \"Не удалось установить зависимости. Пожалуйста, запустите приложение с интернетом или установите зависимости вручную:\npip3 install -r requirements.txt\" buttons {\"OK\"} default button 1 with icon stop"
            exit 1
        fi
        echo "✅ Зависимости установлены из offline_deps"
    else
        osascript -e "display dialog \"Отсутствуют необходимые модули:$MISSING_MODULES\n\nУстановите их командой:\npip3 install -r requirements.txt\n\nИли скачайте зависимости заранее и поместите в папку offline_deps\" buttons {\"OK\"} default button 1 with icon stop"
        exit 1
    fi
fi

# Запуск основного скрипта
exec python3 "$PYTHON_SCRIPT" "$@"
LAUNCHER_EOF

chmod +x "$APP_BUNDLE/Contents/MacOS/Launcher"

# Копирование основного скрипта и офлайн-установщика
echo "📄 Копирование файлов приложения..."
cp "$SCRIPT_DIR/pdf_to_pptx_gui.py" "$APP_BUNDLE/Contents/Resources/"
cp "$SCRIPT_DIR/requirements.txt" "$APP_BUNDLE/Contents/Resources/"
cp "$SCRIPT_DIR/offline_installer.py" "$APP_BUNDLE/Contents/Resources/"

# Копируем offline_deps если существует
if [ -d "$SCRIPT_DIR/offline_deps" ] && [ "$(ls -A $SCRIPT_DIR/offline_deps 2>/dev/null)" ]; then
    echo "📦 Копирование офлайн-зависимостей в приложение..."
    cp -r "$SCRIPT_DIR/offline_deps" "$APP_BUNDLE/Contents/Resources/"
    echo "✅ Офлайн-зависимости включены в приложение"
else
    echo "⚠️  Папка offline_deps не найдена или пуста"
    echo "   Приложение будет работать только при наличии интернета для установки зависимостей"
fi

# Создание иконки приложения в формате ICNS
echo "🎨 Создание иконки приложения..."
python3 << 'ICON_SCRIPT'
import struct
import zlib
import os
import shutil

def create_minimal_png(width, height, color=(70, 130, 180)):
    """Создает PNG изображение с простым дизайном"""
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # Filter byte
        for x in range(width):
            # Градиентный эффект
            r = min(255, color[0] + (y // 4))
            g = min(255, color[1] + (x // 8))
            b = color[2]
            raw_data += bytes([r, g, b])
    
    def make_chunk(chunk_type, data):
        chunk = chunk_type + data
        crc = zlib.crc32(chunk) & 0xffffffff
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', crc)
    
    png_signature = b'\x89PNG\r\n\x1a\n'
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr_chunk = make_chunk(b'IHDR', ihdr_data)
    compressed_data = zlib.compress(raw_data, 9)
    idat_chunk = make_chunk(b'IDAT', compressed_data)
    iend_chunk = make_chunk(b'IEND', b'')
    
    return png_signature + ihdr_chunk + idat_chunk + iend_chunk

def create_icns_from_png(png_data, icon_type):
    """Создает элемент ICNS из PNG данных"""
    # Типы иконок: ic07=128x128, ic08=256x256, ic09=512x512, ic10=1024x1024
    type_map = {
        'ic07': (128, 128),
        'ic08': (256, 256),
        'ic09': (512, 512),
        'ic10': (1024, 1024)
    }
    
    if icon_type not in type_map:
        return None
    
    w, h = type_map[icon_type]
    png_resized = create_minimal_png(w, h)
    
    # Структура элемента ICNS: 4 байта тип + 4 байта размер + данные
    element_size = 8 + len(png_resized)
    element = icon_type.encode('ascii') + struct.pack('>I', element_size) + png_resized
    
    return element

try:
    # Используем SCRIPT_DIR для корректных путей
    resources_dir = os.path.join(os.environ.get('SCRIPT_DIR', '.'), 'build_installer', 'PDFToPPTXConverter.app', 'Contents', 'Resources')
    temp_dir = os.path.join(resources_dir, 'icon_temp')
    os.makedirs(temp_dir, exist_ok=True)
    
    # Создаем PNG разных размеров (только необходимые для macOS)
    sizes = [
        ('ic07', 128),
        ('ic08', 256),
        ('ic09', 512)
    ]
    
    icns_elements = []
    for icon_type, size in sizes:
        png_data = create_minimal_png(size, size)
        filename = os.path.join(temp_dir, f'icon_{size}.png')
        with open(filename, 'wb') as f:
            f.write(png_data)
        
        # Создаем элемент ICNS
        element_size = 8 + len(png_data)
        element = icon_type.encode('ascii') + struct.pack('>I', element_size) + png_data
        icns_elements.append(element)
        print(f"✅ Создана иконка {size}x{size}")
    
    # Добавляем иконку 1024x1024 как копию 512x512 (для экономии времени)
    png_512 = icns_elements[-1][8:]  # Извлекаем данные из последнего элемента
    element_1024 = b'ic10' + struct.pack('>I', 8 + len(png_512)) + png_512
    icns_elements.append(element_1024)
    print("✅ Добавлена иконка 1024x1024")
    
    # Создаем файл ICNS
    icns_header = b'icns' + struct.pack('>I', 8)  # Magic + total size (будет обновлен)
    
    # Собираем все элементы
    icns_data = icns_header + b''.join(icns_elements)
    
    # Обновляем общий размер
    total_size = len(icns_data)
    icns_data = b'icns' + struct.pack('>I', total_size) + icns_data[8:]
    
    # Записываем ICNS файл
    icns_path = os.path.join(resources_dir, 'AppIcon.icns')
    with open(icns_path, 'wb') as f:
        f.write(icns_data)
    
    print(f"✅ ICNS иконка создана: {icns_path}")
    
    # Очищаем временную папку
    shutil.rmtree(temp_dir)
    
except Exception as e:
    print(f"⚠️  Не удалось создать ICNS иконку: {e}")
    # Создаем пустой файл-заглушку
    import os
    fallback_resources = os.path.join(os.environ.get('SCRIPT_DIR', '.'), 'build_installer', 'PDFToPPTXConverter.app', 'Contents', 'Resources')
    os.makedirs(fallback_resources, exist_ok=True)
    with open(os.path.join(fallback_resources, 'AppIcon.icns'), 'wb') as f:
        f.write(b'')
    print("⚠️  Создан файл-заглушка для иконки")
ICON_SCRIPT

# Создание DMG с правильной структурой для macOS
echo "💿 Создание DMG образа..."
if command -v hdiutil &> /dev/null; then
    # Создаем временную папку для структуры DMG
    DMG_CONTENTS="$BUILD_DIR/dmg_contents"
    mkdir -p "$DMG_CONTENTS"
    
    # Копируем приложение в папку для DMG
    cp -r "$APP_BUNDLE" "$DMG_CONTENTS/"
    
    # Создаем symlink на Applications
    ln -s /Applications "$DMG_CONTENTS/Applications"
    
    # Создаем фон для DMG (опционально)
    # Создаем скрытую папку .background для фона
    mkdir -p "$DMG_CONTENTS/.background"
    
    # Создаем простой PNG для фона
    python3 << 'BG_SCRIPT'
import struct
import zlib

def create_background_png(filename, width=600, height=400):
    """Создает простой градиентный фон для DMG"""
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'
        for x in range(width):
            # Светлый градиент
            r = min(255, 240 + (y // 20))
            g = min(255, 240 + (y // 20))
            b = min(255, 245 + (y // 20))
            raw_data += bytes([r, g, b])
    
    def make_chunk(chunk_type, data):
        chunk = chunk_type + data
        crc = zlib.crc32(chunk) & 0xffffffff
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', crc)
    
    png_signature = b'\x89PNG\r\n\x1a\n'
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr_chunk = make_chunk(b'IHDR', ihdr_data)
    compressed_data = zlib.compress(raw_data, 9)
    idat_chunk = make_chunk(b'IDAT', compressed_data)
    iend_chunk = make_chunk(b'IEND', b'')
    
    with open(filename, 'wb') as f:
        f.write(png_signature + ihdr_chunk + idat_chunk + iend_chunk)

try:
    # Используем SCRIPT_DIR для корректных путей
    import os
    dmg_contents_dir = os.path.join(os.environ.get('SCRIPT_DIR', '.'), 'build_installer', 'dmg_contents')
    background_dir = os.path.join(dmg_contents_dir, '.background')
    os.makedirs(background_dir, exist_ok=True)
    create_background_png(os.path.join(background_dir, 'background.png'))
    print("✅ Фон для DMG создан")
except Exception as e:
    print(f"⚠️  Не удалось создать фон: {e}")
BG_SCRIPT

    # Создаем DMG образ
    hdiutil create -volname "$VOLUME_NAME" \
        -srcfolder "$DMG_CONTENTS" \
        -ov -format UDZO "$DMG_FILE"
    
    # Очищаем временную папку
    rm -rf "$DMG_CONTENTS"
    
    echo ""
    echo "✅ Готово!"
    echo "📦 Установочный файл: $DMG_FILE"
    echo ""
    echo "Для установки:"
    echo "1. Откройте $DMG_FILE"
    echo "2. Перетащите ${APP_NAME}.app в папку Applications"
    echo "3. Для удаления просто перетащите приложение из Applications в Корзину"
    echo ""
else
    echo "⚠️  hdiutil не найден (доступен только на macOS)"
    echo ""
    echo "✅ Структура приложения готова: $APP_BUNDLE"
    echo ""
    echo "Для запуска приложения:"
    echo "  python3 pdf_to_pptx_gui.py"
    echo ""
    echo "Или скопируйте ${APP_NAME}.app в любое место и запустите двойным кликом."
fi
