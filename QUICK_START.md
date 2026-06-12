# 🚀 Быстрый старт для macOS

## Установка за 1 минуту (с интернетом)

```bash
# 1. Установите зависимости
pip3 install PyMuPDF python-pptx Pillow

# 2. Запустите приложение
python3 pdf_to_pptx_gui.py
```

---

## Создание DMG для удобной установки

```bash
# Создайте установочный DMG файл
bash build_dmg.sh

# Откройте созданный файл PDFToPPTXConverter-v2.0.0.dmg
# Перетащите приложение в Applications
```

---

## Офлайн-установка (без интернета)

### На компьютере с интернетом:
```bash
# Скачайте все зависимости
./bundle_deps.sh

# Скопируйте ВСЕ файлы проекта + папку offline_deps на флешку
```

### На компьютере без интернета:
```bash
# Запустите офлайн-установщик
python3 offline_installer.py

# Запустите приложение
python3 pdf_to_pptx_gui.py
```

---

## Проверка установки

```bash
# Проверьте, что все зависимости установлены
python3 -c "import fitz; import pptx; import PIL; print('✅ Всё работает!')"
```

---

## Решение проблем

| Ошибка | Решение |
|--------|---------|
| `ModuleNotFoundError: No module named 'PIL'` | `python3 offline_installer.py` |
| `Python 3 not found` | `brew install python3` |
| Приложение не запускается | См. [OFFLINE_INSTALL.md](OFFLINE_INSTALL.md) |

---

## Файлы проекта

- `pdf_to_pptx_gui.py` - основное приложение
- `build_dmg.sh` - сборка DMG
- `offline_installer.py` - офлайн-установка
- `bundle_deps.sh` - загрузка зависимостей
- `requirements.txt` - список пакетов

📖 Подробная документация: [README_RU.md](README_RU.md)
