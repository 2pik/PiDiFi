# 📖 Полное руководство по установке PDFToPPTXConverter

## 🔥 СРОЧНО: Исправление ошибки "ModuleNotFoundError: No module named 'PIL'"

Если вы видите эту ошибку при запуске `build_dmg.sh`, выполните одно из следующих решений:

---

## ✅ Решение 1: Быстрая установка (с интернетом)

```bash
# Установите все зависимости одной командой
pip3 install PyMuPDF python-pptx Pillow

# Затем запустите сборку DMG
bash build_dmg.sh
```

---

## ✅ Решение 2: Офлайн-установка (без интернета)

### Шаг 1: На компьютере с интернетом

```bash
# Скачайте все зависимости в локальную папку
chmod +x bundle_deps.sh
./bundle_deps.sh

# Проверьте, что папка offline_deps создана
ls -la offline_deps/

# Упакуйте всё для передачи
zip -r PDFToPPTXConverter-complete.zip \
    *.py *.sh *.md requirements.txt offline_deps/
```

### Шаг 2: Перенесите архив на компьютер без интернета

Скопируйте `PDFToPPTXConverter-complete.zip` на флешку или через локальную сеть.

### Шаг 3: На компьютере без интернета

```bash
# Распакуйте архив
unzip PDFToPPTXConverter-complete.zip
cd PDFToPPTXConverter-complete

# Установите зависимости из локальных файлов
python3 offline_installer.py

# Запустите приложение
python3 pdf_to_pptx_gui.py

# Или создайте DMG
bash build_dmg.sh
```

---

## 📦 Что входит в комплект

| Файл | Назначение |
|------|------------|
| `pdf_to_pptx_gui.py` | Основное приложение |
| `offline_installer.py` | Автономный установщик зависимостей |
| `bundle_deps.sh` | Скрипт загрузки wheel-файлов |
| `build_dmg.sh` | Сборка установочного DMG |
| `requirements.txt` | Список зависимостей |
| `offline_deps/` | **Wheel-файлы PyMuPDF, Pillow, python-pptx** |

---

## 🎯 Проверка установки

```bash
# Выполните команду для проверки всех зависимостей
python3 -c "import fitz; import pptx; import PIL; print('✅ Всё работает!')"
```

Если увидите `✅ Всё работает!` — можно запускать приложение.

---

## ❓ Частые проблемы

### Проблема: ModuleNotFoundError: No module named 'PIL'

**Решение:**
```bash
python3 offline_installer.py
```

Или с интернетом:
```bash
pip3 install Pillow
```

### Проблема: offline_deps не найдена

**Решение:** Сначала выполните `./bundle_deps.sh` на компьютере с интернетом.

### Проблема: Python 3 not found

**Решение:**
```bash
brew install python3
```

Или скачайте с [python.org](https://www.python.org/downloads/macos/)

### Проблема: hdiutil: command not found

**Решение:** `hdiutil` — это стандартная утилита macOS. Если её нет, возможно у вас не полноценная macOS. Попробуйте запустить приложение напрямую:
```bash
python3 pdf_to_pptx_gui.py
```

---

## 📞 Поддержка

- 📄 [QUICK_START.md](QUICK_START.md) — быстрый старт
- 📄 [OFFLINE_INSTALL.md](OFFLINE_INSTALL.md) — подробная офлайн-инструкция
- 📄 [README_RU.md](README_RU.md) — основная документация
- 📄 [SUMMARY.md](SUMMARY.md) — технический отчет

---

## ✨ Готово!

Теперь вы можете конвертировать PDF в PowerPoint без ошибок! 🎉
