# 📦 Офлайн-установка PDFToPPTXConverter

## Быстрый старт для пользователя macOS

### Сценарий 1: У вас есть интернет ✅

```bash
# 1. Клонируйте репозиторий
git clone <URL_репозитория>
cd PDFToPPTXConverter

# 2. Установите зависимости
pip3 install -r requirements.txt

# 3. Запустите приложение
python3 pdf_to_pptx_gui.py

# Или создайте DMG для удобной установки
bash build_dmg.sh
```

---

### Сценарий 2: Установка БЕЗ интернета 🚫🌐

#### Шаг 1: Подготовка (на компьютере с интернетом)

1. Скачайте весь репозиторий как ZIP или через git
2. Выполните команду для загрузки зависимостей:
   ```bash
   chmod +x bundle_deps.sh
   ./bundle_deps.sh
   ```
3. Скопируйте **ВСЕ файлы** включая папку `offline_deps/` на флешку

#### Шаг 2: Установка (на компьютере без интернета)

1. Скопируйте все файлы с флешки в любую папку
2. Откройте Терминал и перейдите в эту папку
3. Запустите офлайн-установщик:
   ```bash
   python3 offline_installer.py
   ```
4. После установки запустите приложение:
   ```bash
   python3 pdf_to_pptx_gui.py
   ```

Или создайте DMG:
```bash
bash build_dmg.sh
```

---

## Что входит в офлайн-пакет?

| Файл | Назначение |
|------|------------|
| `pdf_to_pptx_gui.py` | Основное приложение |
| `offline_installer.py` | Автономный установщик зависимостей |
| `bundle_deps.sh` | Скрипт загрузки wheel-файлов |
| `build_dmg.sh` | Сборка установочного DMG |
| `requirements.txt` | Список зависимостей |
| `offline_deps/` | **Wheel-файлы PyMuPDF, Pillow, python-pptx** |
| `OFFLINE_INSTALL.md` | Подробная инструкция |

---

## Решение проблем

### ❌ ModuleNotFoundError: No module named 'PIL'

```bash
python3 offline_installer.py
```

### ❌ Приложение не запускается из DMG

Убедитесь, что при сборке DMG папка `offline_deps/` была в той же директории.

### ❌ Python не найден

Установите Python с [python.org](https://python.org) или через Homebrew:
```bash
brew install python3
```

---

## Для разработчиков

Чтобы подготовить офлайн-пакет для распространения:

```bash
# 1. Загрузите все зависимости
./bundle_deps.sh

# 2. Проверьте содержимое
ls -la offline_deps/

# 3. Упакуйте для передачи
zip -r PDFToPPTXConverter-offline.zip \
    *.py *.sh *.md requirements.txt offline_deps/
```

Размер итогового пакета: ~100-150 МБ

---

## Поддержка

- macOS 10.15+ (Catalina и новее)
- Apple Silicon (M1/M2/M3) и Intel Mac
- Python 3.8+
