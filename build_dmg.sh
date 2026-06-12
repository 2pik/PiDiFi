#!/bin/bash
# Скрипт создания установочного DMG файла для macOS
# Не требует дополнительных зависимостей кроме стандартных утилит macOS

set -e

APP_NAME="PDFToPPTXConverter"
VERSION="1.0.0"
BUILD_DIR="./build"
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"
DMG_FILE="${APP_NAME}-v${VERSION}.dmg"
VOLUME_NAME="${APP_NAME} v${VERSION}"

echo "📦 Создание установочного DMG файла..."

# Очистка предыдущей сборки
echo "🧹 Очистка предыдущей сборки..."
rm -rf "$BUILD_DIR"
rm -f "$DMG_FILE"

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

# Создание лаунчера (обертка для запуска Python скрипта)
cat > "$APP_BUNDLE/Contents/MacOS/Launcher" << LAUNCHER_EOF
#!/bin/bash
# Лаунчер приложения PDFToPPTXConverter

SCRIPT_DIR="\$(cd "\$(dirname "\$0")/../Resources" && pwd)"
PYTHON_SCRIPT="\$SCRIPT_DIR/pdf_to_pptx_gui.py"

# Проверка наличия Python 3
if ! command -v python3 &> /dev/null; then
    osascript -e 'display dialog "Ошибка: Python 3 не найден.\n\nПожалуйста, установите Python 3 с сайта python.org или через Homebrew:\nbrew install python3" buttons {"OK"} default button 1 with icon stop'
    exit 1
fi

# Проверка зависимостей
check_module() {
    python3 -c "import \$1" 2>/dev/null
    return \$?
}

MISSING_MODULES=""
if ! check_module fitz; then
    MISSING_MODULES="\$MISSING_MODULES PyMuPDF"
fi
if ! check_module pptx; then
    MISSING_MODULES="\$MISSING_MODULES python-pptx"
fi
if ! check_module PIL; then
    MISSING_MODULES="\$MISSING_MODULES Pillow"
fi

if [ -n "\$MISSING_MODULES" ]; then
    osascript -e "display dialog \"Ошибка: Отсутствуют необходимые модули:\$MISSING_MODULES\n\nУстановите их командой:\npip3 install\$MISSING_MODULES\" buttons {\"OK\"} default button 1 with icon stop"
    exit 1
fi

# Запуск основного скрипта
exec python3 "\$PYTHON_SCRIPT" "\$@"
LAUNCHER_EOF

chmod +x "$APP_BUNDLE/Contents/MacOS/Launcher"

# Копирование основного скрипта
echo "📄 Копирование файлов приложения..."
cp ./pdf_to_pptx_gui.py "$APP_BUNDLE/Contents/Resources/"

# Создание простой иконки (без внешних зависимостей)
# Создаем минимальный PNG файл программно на Python без PIL
python3 << 'ICON_SCRIPT'
import struct
import zlib

def create_minimal_png(filename):
    """Создает минимальный PNG файл 512x512 с простым дизайном"""
    width, height = 512, 512
    
    # Создаем простые данные изображения (синий фон)
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
    create_minimal_png('./build/PDFToPPTXConverter.app/Contents/Resources/AppIcon.png')
    print("✅ Иконка создана без внешних зависимостей")
except Exception as e:
    print(f"⚠️  Не удалось создать иконку: {e}")
    # Создаем пустой файл-заглушку
    import os
    os.makedirs('./build/PDFToPPTXConverter.app/Contents/Resources', exist_ok=True)
    with open('./build/PDFToPPTXConverter.app/Contents/Resources/AppIcon.png', 'w') as f:
        f.write('')
    print("⚠️  Создан файл-заглушка для иконки")
ICON_SCRIPT

# Копирование requirements.txt
cp ./requirements.txt "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true

# Создание DMG
echo "💿 Создание DMG образа..."
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
