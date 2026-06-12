# Makefile для PDFToPPTXConverter
# Вдохновлен лучшими практиками umputun

.PHONY: all clean test lint install build help deps check

PYTHON ?= python3
PIP ?= pip3
APP_NAME = PDFToPPTXConverter
VERSION = 2.0.0

all: help

help:
@echo "PDFToPPTXConverter - Makefile цели:"
@echo "  make deps     - Установить зависимости"
@echo "  make check    - Проверить зависимости"
@echo "  make test     - Запустить тесты"
@echo "  make lint     - Запустить линтер (flake8)"
@echo "  make build    - Создать DMG образ"
@echo "  make install  - Установить приложение локально"
@echo "  make clean    - Очистить временные файлы"

deps:
@$(PIP) install -r requirements.txt

check:
@$(PYTHON) -c "import fitz" || (echo "PyMuPDF не найден" && exit 1)
@$(PYTHON) -c "from pptx import Presentation" || (echo "python-pptx не найден" && exit 1)
@$(PYTHON) -c "from PIL import Image" || (echo "Pillow не найден" && exit 1)
@echo "Все зависимости установлены"

test:
@$(PYTHON) -m pytest test_pdf_converter.py -v || $(PYTHON) test_pdf_converter.py

lint:
@flake8 pdf_to_pptx_gui.py --max-line-length=120 --ignore=E501,W503 || true

build: check
@./build_dmg.sh

install: check
@./install.sh

clean:
@rm -rf build/ __pycache__/ *.pyc *.pyo *.log logs/ *.dmg
@find . -name ".DS_Store" -delete
