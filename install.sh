#!/bin/bash
# Скрипт установки PDF в PPTX Converter для macOS

echo "🚀 Установка PDF в PPTX Converter..."

# Проверка на macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ Ошибка: Этот скрипт предназначен только для macOS"
    exit 1
fi

# Создание директории для приложения
APP_DIR="$HOME/Applications"
mkdir -p "$APP_DIR"

# Создание директории для ресурсов приложения
APP_RESOURCES="$APP_DIR/PDFToPPTXConverter.app/Contents/Resources"
mkdir -p "$APP_RESOURCES"

# Копирование основного скрипта
cp "$(dirname "$0")/pdf_to_pptx_gui.py" "$APP_RESOURCES/"

# Создание requirements.txt
cat > "$APP_RESOURCES/requirements.txt" << 'EOF'
customtkinter>=5.2.0
PyMuPDF>=1.23.0
python-pptx>=0.6.21
Pillow>=10.0.0
EOF

# Создание Info.plist
cat > "$APP_DIR/PDFToPPTXConverter.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacOS/Launcher</string>
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.pdftopptxconverter</string>
    <key>CFBundleName</key>
    <string>PDFToPPTXConverter</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

# Создание исполняемого скрипта запуска (Launcher)
cat > "$APP_DIR/PDFToPPTXConverter.app/Contents/MacOS/Launcher" << 'EOF'
#!/bin/bash
# Запуск приложения PDF в PPTX Converter

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES="$APP_ROOT/Resources"

# Проверка Python 3
if ! command -v python3 &> /dev/null; then
    osascript -e 'display dialog "Ошибка: Python 3 не найден.\n\nУстановите Python с python.org или через Homebrew:\nbrew install python3" buttons {"OK"} default button 1 with icon stop'
    exit 1
fi

# Проверка и установка зависимостей при необходимости
if ! python3 -c "import customtkinter, fitz, pptx, PIL" 2>/dev/null; then
    echo "📦 Установка зависимостей..."
    pip3 install --quiet --upgrade pip
    pip3 install --quiet -r "$RESOURCES/requirements.txt"
fi

# Запуск приложения
exec python3 "$RESOURCES/pdf_to_pptx_gui.py"
EOF

chmod +x "$APP_DIR/PDFToPPTXConverter.app/Contents/MacOS/Launcher"

# Создание простой иконки (базовый placeholder)
# В реальном приложении здесь был бы настоящий .icns файл
echo "🎨 Создание иконки приложения..."

# Установка прав
chmod -R 755 "$APP_DIR/PDFToPPTXConverter.app"

echo ""
echo "✅ Установка завершена!"
echo ""
echo "📍 Приложение установлено в: $APP_DIR/PDFToPPTXConverter.app"
echo ""
echo "🔹 Для запуска:"
echo "   1. Откройте Finder"
echo "   2. Перейдите в ~/Applications"
echo "   3. Дважды кликните на PDFToPPTXConverter.app"
echo ""
echo "🔹 Или через терминал:"
echo "   open ~/Applications/PDFToPPTXConverter.app"
echo ""
echo "⚠️  При первом запуске macOS может предупредить о неизвестном разработчике."
echo "   Решение: Системные настройки → Защита и безопасность → Разрешить"
echo ""
