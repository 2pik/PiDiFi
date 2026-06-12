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

# Создание простой иконки (используем встроенные средства macOS)
# Создаем PNG иконку программно без внешних зависимостей
python3 << 'ICON_SCRIPT'
import sys
try:
    # Попытка использовать PIL если доступен
    from PIL import Image, ImageDraw
    img = Image.new('RGB', (512, 512), color=(70, 130, 180))
    draw = ImageDraw.Draw(img)
    draw.rectangle([50, 50, 462, 462], fill=(255, 255, 255), outline=(70, 130, 180), width=20)
    draw.text((150, 200), "PDF", fill=(70, 130, 180))
    draw.text((180, 300), "→", fill=(70, 130, 180))
    draw.text((150, 400), "PPTX", fill=(70, 130, 180))
    img.save('./build/PDFToPPTXConverter.app/Contents/Resources/AppIcon.png')
    print("✅ Иконка создана с помощью PIL")
except ImportError:
    # Если PIL недоступен, создаем простую иконку из системных ресурсов
    import os
    # Используем стандартную иконку документа macOS
    print("⚠️  PIL недоступен, используем стандартную иконку")
    # Создаем пустой файл-заглушку (macOS использует иконку по умолчанию)
    with open('./build/PDFToPPTXConverter.app/Contents/Resources/AppIcon.png', 'w') as f:
        f.write('')
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
