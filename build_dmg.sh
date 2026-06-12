#!/bin/bash
# Скрипт создания установочного DMG файла для macOS
# Вдохновлен лучшими практиками umputun
# Поддерживает офлайн-установку с локальными зависимостями

set -e

APP_NAME="PDFToPPTXConverter"
VERSION="2.0.0"
BUILD_DIR="./build"
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"
DMG_FILE="${APP_NAME}-v${VERSION}.dmg"
VOLUME_NAME="${APP_NAME} v${VERSION}"
OFFLINE_DEPS_DIR="./offline_deps"

# Определяем путь к Python
PYTHON_CMD="python3"

echo "📦 Создание установочного DMG файла..."

# Очистка предыдущей сборки
echo "🧹 Очистка предыдущей сборки..."
rm -rf "$BUILD_DIR"
rm -f "$DMG_FILE"

# Функция проверки модуля
check_module() {
    $PYTHON_CMD -c "import $1" 2>/dev/null
    return $?
}

# Проверка зависимостей
echo "🔍 Проверка зависимостей..."
MISSING_MODULES=""
if ! check_module fitz; then
    MISSING_MODULES="$MISSING_MODULES PyMuPDF"
fi
if ! check_module pptx; then
    MISSING_MODULES="$MISSING_MODULES python-pptx"
fi
if ! check_module PIL; then
    MISSING_MODULES="$MISSING_MODULES Pillow"
fi

# Если есть отсутствующие модули, пробуем установить из offline_deps
if [ -n "$MISSING_MODULES" ]; then
    echo "⚠️  Отсутствуют модули:$MISSING_MODULES"
    
    if [ -d "$OFFLINE_DEPS_DIR" ] && [ "$(ls -A $OFFLINE_DEPS_DIR/*.whl 2>/dev/null)" ]; then
        echo "📦 Попытка установки из локальных wheel файлов..."
        python3 offline_installer.py
        
        # Повторная проверка
        MISSING_MODULES=""
        if ! check_module fitz; then
            MISSING_MODULES="$MISSING_MODULES PyMuPDF"
        fi
        if ! check_module pptx; then
            MISSING_MODULES="$MISSING_MODULES python-pptx"
        fi
        if ! check_module PIL; then
            MISSING_MODULES="$MISSING_MODULES Pillow"
        fi
        
        if [ -n "$MISSING_MODULES" ]; then
            echo "❌ Не удалось установить зависимости из offline_deps"
            echo ""
            echo "🔄 Попытка установки через pip3 с интернетом..."
            pip3 install --quiet PyMuPDF python-pptx Pillow || true
            
            # Финальная проверка
            MISSING_MODULES=""
            if ! check_module fitz; then MISSING_MODULES="$MISSING_MODULES PyMuPDF"; fi
            if ! check_module pptx; then MISSING_MODULES="$MISSING_MODULES python-pptx"; fi
            if ! check_module PIL; then MISSING_MODULES="$MISSING_MODULES Pillow"; fi
            
            if [ -n "$MISSING_MODULES" ]; then
                echo "❌ Критическая ошибка: не удалось установить:$MISSING_MODULES"
                echo "Попробуйте вручную: pip3 install PyMuPDF python-pptx Pillow"
                exit 1
            fi
        fi
        echo "✅ Зависимости установлены"
    else
        echo "📦 Офлайн-зависимости не найдены. Установка через pip3..."
        pip3 install --quiet PyMuPDF python-pptx Pillow || {
            echo "❌ Ошибка установки через pip3. Проверьте подключение к интернету."
            exit 1
        }
        echo "✅ Зависимости установлены через pip3"
    fi
fi
echo "✅ Все зависимости установлены"

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
    <string>AppIcon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
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
if ! check_module PIL; then
    MISSING_MODULES="$MISSING_MODULES Pillow"
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
        if ! check_module PIL; then
            MISSING_MODULES="$MISSING_MODULES Pillow"
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
cp ./pdf_to_pptx_gui.py "$APP_BUNDLE/Contents/Resources/"
cp ./requirements.txt "$APP_BUNDLE/Contents/Resources/"
cp ./offline_installer.py "$APP_BUNDLE/Contents/Resources/"

# Копируем offline_deps если существует
if [ -d "$OFFLINE_DEPS_DIR" ] && [ "$(ls -A $OFFLINE_DEPS_DIR 2>/dev/null)" ]; then
    echo "📦 Копирование офлайн-зависимостей в приложение..."
    cp -r "$OFFLINE_DEPS_DIR" "$APP_BUNDLE/Contents/Resources/"
    echo "✅ Офлайн-зависимости включены в приложение"
else
    echo "⚠️  Папка offline_deps не найдена или пуста"
    echo "   Приложение будет работать только при наличии интернета для установки зависимостей"
fi

# Создание иконки без внешних зависимостей (чистый bash/python без импортов)
echo "🎨 Создание иконки приложения..."
python3 << 'ICON_SCRIPT'
import struct
import zlib
import os

def create_minimal_png(filename):
    """Создает минимальный PNG файл 512x512 с простым дизайном"""
    width, height = 512, 512
    
    # Создаем простые данные изображения (синий градиент)
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # Filter byte для каждой строки
        for x in range(width):
            # Синий градиент
            r = 70
            g = 130
            b = 180
            raw_data += bytes([r, g, b])
    
    # Создаем PNG chunks
    def make_chunk(chunk_type, data):
        chunk = chunk_type + data
        crc = zlib.crc32(chunk) & 0xffffffff
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', crc)
    
    # PNG signature
    png_signature = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr_chunk = make_chunk(b'IHDR', ihdr_data)
    
    # IDAT chunk (сжатые данные изображения)
    compressed_data = zlib.compress(raw_data, 9)
    idat_chunk = make_chunk(b'IDAT', compressed_data)
    
    # IEND chunk
    iend_chunk = make_chunk(b'IEND', b'')
    
    # Записываем PNG файл
    with open(filename, 'wb') as f:
        f.write(png_signature + ihdr_chunk + idat_chunk + iend_chunk)

try:
    os.makedirs('./build/PDFToPPTXConverter.app/Contents/Resources', exist_ok=True)
    create_minimal_png('./build/PDFToPPTXConverter.app/Contents/Resources/AppIcon.png')
    print("✅ Иконка создана без внешних зависимостей")
except Exception as e:
    print(f"⚠️  Не удалось создать иконку: {e}")
    os.makedirs('./build/PDFToPPTXConverter.app/Contents/Resources', exist_ok=True)
    # Создаем пустой файл-заглушку
    with open('./build/PDFToPPTXConverter.app/Contents/Resources/AppIcon.png', 'wb') as f:
        f.write(b'')
    print("⚠️  Создан файл-заглушка для иконки")
ICON_SCRIPT

# Создание DMG (только на macOS)
echo "💿 Создание DMG образа..."
if command -v hdiutil &> /dev/null; then
    hdiutil create -volname "$VOLUME_NAME" \
        -srcfolder "$BUILD_DIR" \
        -ov -format UDZO "$DMG_FILE"
    
    echo ""
    echo "✅ Готово!"
    echo "📦 Установочный файл: $DMG_FILE"
    echo ""
    echo "Для установки:"
    echo "1. Откройте $DMG_FILE"
    echo "2. Перетащите ${APP_NAME}.app в папку Applications"
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
