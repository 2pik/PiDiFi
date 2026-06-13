#!/bin/bash
# Скрипт создания установочного DMG файла для macOS
# Создает ОДИН установочный файл .dmg с иконкой и возможностью удаления в корзину

set -e

# Получаем абсолютный путь к директории скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📦 Создание установочного DMG файла..."
echo "   Директория скрипта: ${SCRIPT_DIR}"

# Проверяем наличие всех необходимых файлов
echo "🔍 Проверка необходимых файлов..."
if [ ! -f "${SCRIPT_DIR}/pdf_to_pptx_gui.py" ]; then
    echo "❌ Ошибка: pdf_to_pptx_gui.py не найден в ${SCRIPT_DIR}"
    exit 1
fi
if [ ! -f "${SCRIPT_DIR}/offline_installer.py" ]; then
    echo "❌ Ошибка: offline_installer.py не найден в ${SCRIPT_DIR}"
    exit 1
fi
if [ ! -f "${SCRIPT_DIR}/requirements.txt" ]; then
    echo "❌ Ошибка: requirements.txt не найден в ${SCRIPT_DIR}"
    exit 1
fi
echo "✅ Все файлы найдены"

APP_NAME="PDFToPPTXConverter"
VERSION="2.2.0"
BUILD_DIR="${SCRIPT_DIR}/build_temp"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_FILE="${SCRIPT_DIR}/${APP_NAME}-${VERSION}.dmg"
VOLUME_NAME="${APP_NAME} v${VERSION}"

PYTHON_CMD="python3"

# Очистка
echo "🧹 Очистка предыдущей сборки..."
rm -rf "${BUILD_DIR}"
rm -f "${DMG_FILE}"

# Установка зависимостей
echo "🔍 Проверка зависимостей..."
if ! $PYTHON_CMD -c "import fitz" 2>/dev/null || ! $PYTHON_CMD -c "import pptx" 2>/dev/null; then
    echo "📦 Установка зависимостей..."
    pip3 install --quiet PyMuPDF python-pptx
fi
echo "✅ Зависимости готовы"

# Создание структуры .app
echo "📁 Создание структуры приложения..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Info.plist с правильными настройками для скрытия Python из меню
cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
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
    <key>LSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <false/>
    <key>LSBackgroundOnly</key>
    <false/>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>CFBundleDocumentTypes</key>
    <array/>
    <key>NSAppleScriptEnabled</key>
    <false/>
    <key>NSDesktopFolderUsageDescription</key>
    <string>Приложению требуется доступ к файлам PDF для конвертации</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>Приложению требуется доступ к файлам PDF для конвертации</string>
    <key>NSDownloadsFolderUsageDescription</key>
    <string>Приложению требуется доступ к файлам PDF для конвертации</string>
    <key>NSFileSystemUsageDescription</key>
    <string>Приложению требуется доступ к файлам для конвертации</string>
</dict>
</plist>
EOF

# Launcher - правильный способ запуска Python приложения как macOS app
cat > "${APP_BUNDLE}/Contents/MacOS/Launcher" << 'LAUNCHER'
#!/bin/bash
# Получаем путь к ресурсам внутри .app бандла
RESOURCES_DIR="$(cd "$(dirname "$0")/../Resources" && pwd)"

# Устанавливаем переменные окружения для правильного поведения приложения
export PYAPP_NAME="PDFToPPTXConverter"
export PYTHONNOUSERSITE=1
export TK_SILENCE_DEPRECATION=1
export PYTHONPATH="${RESOURCES_DIR}:${PYTHONPATH}"
export PYTHONIOENCODING=utf-8

# Переходим в домашнюю директорию чтобы избежать блокировки файлов
cd $HOME

# Запускаем приложение с правильной обработкой ошибок
exec python3 -u "${RESOURCES_DIR}/pdf_to_pptx_gui.py" "$@" 2>&1 | tee "${RESOURCES_DIR}/launcher.log"
LAUNCHER
chmod +x "${APP_BUNDLE}/Contents/MacOS/Launcher"

# Копирование файлов (ИСПОЛЬЗУЕМ АБСОЛЮТНЫЕ ПУТИ)
echo "📄 Копирование файлов..."
cp "${SCRIPT_DIR}/pdf_to_pptx_gui.py" "${APP_BUNDLE}/Contents/Resources/"
cp "${SCRIPT_DIR}/offline_installer.py" "${APP_BUNDLE}/Contents/Resources/"
cp "${SCRIPT_DIR}/requirements.txt" "${APP_BUNDLE}/Contents/Resources/"

# Создание иконки
echo "🎨 Создание иконки..."
export SCRIPT_DIR="${SCRIPT_DIR}"
$PYTHON_CMD << 'PYICON'
import struct, zlib, os, sys

def create_png(w, h):
    raw = b''
    for y in range(h):
        raw += b'\x00'
        for x in range(w):
            r, g, b = min(255, 70+y//4), min(255, 130+x//8), 180
            raw += bytes([r, g, b])
    def chunk(t, d):
        c = t + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)
    return sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')

script_dir = os.environ.get('SCRIPT_DIR', '.')
res_dir = os.path.join(script_dir, 'build_temp', 'PDFToPPTXConverter.app', 'Contents', 'Resources')
os.makedirs(res_dir, exist_ok=True)

elements = []
for typ, sz in [('ic07', 128), ('ic08', 256), ('ic09', 512)]:
    png = create_png(sz, sz)
    elements.append(typ.encode() + struct.pack('>I', 8+len(png)) + png)
    print(f"✅ Иконка {sz}x{sz}")

# 1024 из 512
elements.append(b'ic10' + struct.pack('>I', 8+len(png)) + png)
print("✅ Иконка 1024x1024")

icns = b'icns' + struct.pack('>I', 8) + b''.join(elements)
icns = b'icns' + struct.pack('>I', len(icns)) + icns[8:]

with open(os.path.join(res_dir, 'AppIcon.icns'), 'wb') as f:
    f.write(icns)
print("✅ AppIcon.icns создан")
PYICON

# Создание DMG
echo "💿 Создание DMG..."
DMG_CONTENTS="${BUILD_DIR}/dmg_contents"
mkdir -p "${DMG_CONTENTS}"
cp -r "${APP_BUNDLE}" "${DMG_CONTENTS}/"
ln -s /Applications "${DMG_CONTENTS}/Applications"

hdiutil create -volname "${VOLUME_NAME}" \
    -srcfolder "${DMG_CONTENTS}" \
    -ov -format UDZO "${DMG_FILE}"

rm -rf "${BUILD_DIR}"

echo ""
echo "✅ ГОТОВО!"
echo "📦 Файл: ${DMG_FILE}"
echo ""
echo "Установка:"
echo "1. Откройте ${DMG_FILE}"
echo "2. Перетащите ${APP_NAME}.app в Applications"
echo "3. Удаление: перетащите из Applications в Корзину"
