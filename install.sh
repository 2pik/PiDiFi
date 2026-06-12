#!/bin/bash
# Скрипт установки PDFToPPTXConverter для macOS
# Создает .app бандл в ~/Applications

set -e

APP_NAME="PDFToPPTXConverter"
INSTALL_DIR="$HOME/Applications"
APP_BUNDLE="$INSTALL_DIR/${APP_NAME}.app"

echo "📦 Установка ${APP_NAME}..."

# Проверка Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ Ошибка: Python 3 не найден"
    echo ""
    echo "Установите Python 3:"
    echo "  brew install python3"
    echo "или скачайте с https://www.python.org/downloads/macos/"
    exit 1
fi

# Создание директории Applications если не существует
if [ ! -d "$INSTALL_DIR" ]; then
    echo "📁 Создание директории $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
fi

# Очистка предыдущей версии
if [ -d "$APP_BUNDLE" ]; then
    echo "🗑️ Удаление предыдущей версии..."
    rm -rf "$APP_BUNDLE"
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
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
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
cat > "$APP_BUNDLE/Contents/MacOS/Launcher" << LAUNCHER_EOF
#!/bin/bash
SCRIPT_DIR="\$(cd "\$(dirname "\$0")/../Resources" && pwd)"
exec python3 "\$SCRIPT_DIR/pdf_to_pptx_gui.py" "\$@"
LAUNCHER_EOF

chmod +x "$APP_BUNDLE/Contents/MacOS/Launcher"

# Копирование основного скрипта
echo "📄 Копирование файлов..."
cp "$(dirname "$0")/pdf_to_pptx_gui.py" "$APP_BUNDLE/Contents/Resources/"
cp "$(dirname "$0")/requirements.txt" "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true

# Проверка зависимостей
echo "🔍 Проверка зависимостей..."
python3 -c "import fitz" 2>/dev/null || MISSING="${MISSING} PyMuPDF"
python3 -c "from pptx import Presentation" 2>/dev/null || MISSING="${MISSING} python-pptx"
python3 -c "from PIL import Image" 2>/dev/null || MISSING="${MISSING} Pillow"

if [ -n "$MISSING" ]; then
    echo ""
    echo "⚠️  Отсутствуют модули:$MISSING"
    echo ""
    read -p "Установить их сейчас? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pip3 install$MISSING
    else
        echo ""
        echo "Вы можете установить их позже командой:"
        echo "pip3 install$MISSING"
    fi
fi

echo ""
echo "✅ Установка завершена!"
echo ""
echo "📍 Приложение установлено в: $APP_BUNDLE"
echo ""
echo "Для запуска:"
echo "  1. Откройте Finder"
echo "  2. Перейдите в ~/Applications"
echo "  3. Дважды кликните на ${APP_NAME}.app"
echo ""
echo "⚠️  При первом запуске macOS может предупредить о неизвестном разработчике."
echo "   Нажмите правой кнопкой → Открыть → Открыть в диалоге безопасности."
