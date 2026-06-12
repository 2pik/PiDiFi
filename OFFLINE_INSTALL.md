# Офлайн-установка PDFToPPTXConverter для macOS

## Вариант 1: Полная офлайн-установка (рекомендуется)

### Для разработчика (создание офлайн-пакета):

1. **Скачайте все зависимости** (требуется интернет один раз):
   ```bash
   ./bundle_deps.sh
   ```
   
2. **Передайте пользователю следующие файлы**:
   - Весь репозиторий проекта
   - Папку `offline_deps/` (содержит ~50-100 МБ wheel-файлов)

### Для пользователя (установка без интернета):

1. **Скопируйте все файлы** на компьютер без интернета:
   ```
   pdf_to_pptx_gui.py
   requirements.txt
   offline_installer.py
   bundle_deps.sh
   build_dmg.sh
   offline_deps/  ← папка с зависимостями
   ```

2. **Запустите офлайн-установщик**:
   ```bash
   python3 offline_installer.py
   ```

3. **Создайте DMG** (опционально):
   ```bash
   bash build_dmg.sh
   ```

4. **Установите приложение**:
   - Откройте созданный файл `PDFToPPTXConverter-v2.0.0.dmg`
   - Перетащите приложение в папку Applications

---

## Вариант 2: Установка с интернетом

Если есть интернет, просто выполните:

```bash
pip3 install -r requirements.txt
python3 pdf_to_pptx_gui.py
```

Или создайте DMG:

```bash
bash build_dmg.sh
```

---

## Структура офлайн-пакета

```
PDFToPPTXConverter-offline/
├── pdf_to_pptx_gui.py        # Основной скрипт
├── requirements.txt           # Список зависимостей
├── offline_installer.py       # Офлайн-установщик
├── bundle_deps.sh            # Скрипт загрузки зависимостей
├── build_dmg.sh              # Скрипт сборки DMG
├── offline_deps/             # Wheel-файлы зависимостей
│   ├── PyMuPDF-*.whl
│   ├── python_pptx-*.whl
│   ├── Pillow-*.whl
│   └── ...
└── OFFLINE_INSTALL.md        # Эта инструкция
```

---

## Поддерживаемые платформы

Офлайн-пакет включает зависимости для:
- ✅ macOS ARM64 (Apple Silicon: M1, M2, M3)
- ✅ macOS x86_64 (Intel Mac)

---

## Troubleshooting

### Ошибка "ModuleNotFoundError: No module named 'PIL'"

Решение:
```bash
python3 offline_installer.py
```

Или с интернетом:
```bash
pip3 install Pillow
```

### Ошибка при запуске приложения из DMG

1. Убедитесь, что папка `offline_deps` была включена в DMG
2. Проверьте права доступа: `chmod +x offline_installer.py`
3. Запустите терминал и выполните: `python3 offline_installer.py`

### Приложение не запускается после установки

Проверьте зависимости:
```bash
python3 -c "import fitz; import pptx; import PIL"
```

Если есть ошибка, переустановите:
```bash
python3 offline_installer.py
```

---

## Примечания

- Размер офлайн-пакета: ~100-150 МБ
- Время установки без интернета: 10-30 секунд
- Требуется Python 3.8 или выше
- Совместимо с macOS 10.15 (Catalina) и новее
