#!/bin/bash
# Скрипт полного удаления PDF в PPTX Converter для macOS

echo "🗑️  Удаление PDF в PPTX Converter..."

# Проверка на macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ Ошибка: Этот скрипт предназначен только для macOS"
    exit 1
fi

APP_DIR="$HOME/Applications/PDFToPPTXConverter.app"

# Проверка существования приложения
if [ ! -d "$APP_DIR" ]; then
    echo "⚠️  Приложение не найдено в $APP_DIR"
    echo "   Возможно, оно уже удалено или никогда не было установлено."
    exit 0
fi

# Подтверждение удаления
echo ""
read -p "Вы уверены, что хотите удалить приложение? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Удаление отменено"
    exit 0
fi

# Удаление приложения
rm -rf "$APP_DIR"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Приложение успешно удалено!"
    echo ""
    echo "📝 Примечание:"
    echo "   • Зависимости Python (customtkinter, PyMuPDF и др.) остались в системе"
    echo "   • Для их удаления выполните: pip3 uninstall customtkinter PyMuPDF python-pptx Pillow"
    echo "   • Конвертированные файлы (.pptx) не были удалены"
else
    echo ""
    echo "❌ Произошла ошибка при удалении"
    exit 1
fi
