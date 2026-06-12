#!/bin/bash
# Скрипт удаления PDFToPPTXConverter для macOS

APP_NAME="PDFToPPTXConverter"
INSTALL_DIR="$HOME/Applications"
APP_BUNDLE="$INSTALL_DIR/${APP_NAME}.app"

echo "🗑️ Удаление ${APP_NAME}..."

if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Приложение не найдено в $APP_BUNDLE"
    exit 1
fi

rm -rf "$APP_BUNDLE"

echo ""
echo "✅ Приложение успешно удалено!"
echo ""
echo "Примечание: Зависимости Python (PyMuPDF, python-pptx, Pillow) не были удалены."
echo "Если хотите удалить их, выполните:"
echo "  pip3 uninstall PyMuPDF python-pptx Pillow"
