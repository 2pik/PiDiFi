#!/bin/bash
# Скрипт создания установочного DMG файла для macOS
# Результат: PDFToPPTXConverter.dmg в текущей директории

set -e

echo "📦 Создание установочного DMG файла..."

# Проверка на macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ Ошибка: Этот скрипт работает только на macOS"
    exit 1
fi

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Директории
BUILD_DIR="$(pwd)/build_dmg"
APP_NAME="PDFToPPTXConverter"
DMG_NAME="${APP_NAME}-Installer.dmg"
VOLUME_NAME="${APP_NAME}"

# Очистка предыдущей сборки
if [ -d "$BUILD_DIR" ]; then
    echo "🧹 Очистка предыдущей сборки..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"

# Создание структуры .app бандла
echo "📁 Создание структуры приложения..."
APP_DIR="$BUILD_DIR/${APP_NAME}.app/Contents"
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

# Копирование основного скрипта
cp "$(dirname "$0")/pdf_to_pptx_gui.py" "$APP_DIR/Resources/"

# Создание requirements.txt
cat > "$APP_DIR/Resources/requirements.txt" << 'EOF'
customtkinter>=5.2.0
PyMuPDF>=1.23.0
python-pptx>=0.6.21
Pillow>=10.0.0
EOF

# Создание Info.plist
cat > "$APP_DIR/Info.plist" << 'EOF'
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
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Создание скрипта запуска (Launcher)
cat > "$APP_DIR/MacOS/Launcher" << 'EOF'
#!/bin/bash
# Лаунчер приложения PDF в PPTX Converter

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES="$APP_ROOT/Resources"

# Проверка Python 3
if ! command -v python3 &> /dev/null; then
    osascript -e 'display dialog "Ошибка: Python 3 не найден.\n\nУстановите Python с python.org или через Homebrew:\nbrew install python3" buttons {"OK"} default button 1 with icon stop'
    exit 1
fi

# Проверка и установка зависимостей при необходимости
if ! python3 -c "import customtkinter, fitz, pptx, PIL" 2>/dev/null; then
    RESULT=$(osascript -e 'display dialog "Приложению необходимо установить зависимости Python.\n\nТребуется ~50MB свободного места.\n\nУстановить сейчас?" buttons {"Отмена", "Установить"} default button 2 with icon note' -e 'button returned of result')
    
    if [ "$RESULT" = "Установить" ]; then
        echo "📦 Установка зависимостей..."
        
        # Попытка установки через sudo если нужно
        if pip3 install --quiet -r "$RESOURCES/requirements.txt" 2>/dev/null; then
            echo "✅ Зависимости установлены"
        else
            # Запрос пароля через GUI
            osascript -e 'display dialog "Требуется ваш пароль для установки зависимостей." buttons {"OK"} default button 1 with icon note'
            
            # Установка с правами пользователя
            if ! pip3 install --user -r "$RESOURCES/requirements.txt"; then
                osascript -e 'display dialog "Не удалось установить зависимости.\n\nПопробуйте вручную:\npip3 install customtkinter PyMuPDF python-pptx Pillow" buttons {"OK"} default button 1 with icon stop'
                exit 1
            fi
        fi
    else
        exit 0
    fi
fi

# Запуск приложения
exec python3 "$RESOURCES/pdf_to_pptx_gui.py"
EOF

chmod +x "$APP_DIR/MacOS/Launcher"

# Создание простой иконки в формате ICNS
echo "🎨 Создание иконки приложения..."

# Создаем PNG иконку 512x512 с помощью Python
python3 << 'PYTHON_EOF'
from PIL import Image, ImageDraw, ImageFont
import os

# Создание иконки 512x512
size = 512
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Градиентный фон (синий в стиле PowerPoint)
for y in range(size):
    r = int(37 + (y / size) * 20)
    g = int(94 + (y / size) * 30)
    b = int(190 + (y / size) * 20)
    draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

# Рисуем символ PDF (красный прямоугольник)
pdf_x, pdf_y = 80, 150
pdf_w, pdf_h = 140, 180
draw.rounded_rectangle([(pdf_x, pdf_y), (pdf_x + pdf_w, pdf_y + pdf_h)], radius=15, fill=(220, 50, 50, 255))
draw.text((pdf_x + 35, pdf_y + 80), "PDF", fill=(255, 255, 255, 255))

# Рисуем стрелку
arrow_color = (255, 255, 255, 255)
draw.polygon([(260, 240), (260, 280), (340, 260)], fill=arrow_color)

# Рисуем символ PPTX (оранжевый прямоугольник)
pptx_x, pptx_y = 300, 150
draw.rounded_rectangle([(pptx_x, pptx_y), (pptx_x + pdf_w, pptx_y + pdf_h)], radius=15, fill=(255, 140, 50, 255))
draw.text((pptx_x + 25, pptx_y + 80), "PPTX", fill=(255, 255, 255, 255))

# Сохранение в разных размерах для ICNS
sizes = [16, 32, 64, 128, 256, 512]
iconset_dir = "/tmp/icon.iconset"
os.makedirs(iconset_dir, exist_ok=True)

for s in sizes:
    resized = img.resize((s, s), Image.Resampling.LANCZOS)
    resized.save(f"{iconset_dir}/icon_{s}x{s}.png")
    # Retina версии
    if s <= 256:
        retina_s = s * 2
        resized_retina = img.resize((retina_s, retina_s), Image.Resampling.LANCZOS)
        resized_retina.save(f"{iconset_dir}/icon_{s}x{s}@2x.png")

print("Иконка создана")
PYTHON_EOF

# Конвертация в ICNS формат
mkdir -p "$APP_DIR/Resources/icon.iconset"
cp /tmp/icon.iconset/* "$APP_DIR/Resources/icon.iconset/"
iconutil -c icns "$APP_DIR/Resources/icon.iconset" -o "$APP_DIR/Resources/icon.icns"

# Копирование README в DMG
cp "$(dirname "$0")/README.md" "$BUILD_DIR/"
cp "$(dirname "$0")/uninstall.sh" "$BUILD_DIR/"

# Создание DMG
echo "💿 Создание DMG образа..."

# Создаем временную папку для монтирования
TEMP_DMG="$BUILD_DIR/temp.dmg"

# Создание DMG с нужным размером
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$BUILD_DIR" -ov -format UDRW "$TEMP_DMG"

# Конвертация в финальный DMG (сжатый)
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$(dirname "$0")/$DMG_NAME"

# Очистка
rm -f "$TEMP_DMG"
rm -rf "$BUILD_DIR"
rm -rf /tmp/icon.iconset

echo ""
echo -e "${GREEN}✅ DMG файл успешно создан!${NC}"
echo ""
echo "📍 Файл: $(dirname "$0")/$DMG_NAME"
echo "📊 Размер: $(du -h "$(dirname "$0")/$DMG_NAME" | cut -f1)"
echo ""
echo "🔹 Для распространения:"
echo "   1. Загрузите $DMG_NAME на GitHub Releases"
echo "   2. Пользователи скачают DMG, откроют его и перетащат приложение в Applications"
echo ""
