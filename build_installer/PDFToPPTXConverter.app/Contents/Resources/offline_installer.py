#!/usr/bin/env python3
"""
Офлайн-установщик зависимостей для PDFToPPTXConverter
Использует локальные wheel-файлы из папки offline_deps
"""

import subprocess
import sys
import os
from pathlib import Path

def get_script_dir():
    """Получить директорию скрипта"""
    return Path(__file__).parent.resolve()

def check_dependencies():
    """Проверить установленные зависимости"""
    required = {
        'fitz': 'PyMuPDF',
        'pptx': 'python-pptx',
        'PIL': 'Pillow'
    }
    
    missing = []
    for module, package in required.items():
        try:
            __import__(module)
            print(f"✅ {package} уже установлен")
        except ImportError:
            missing.append(package)
            print(f"❌ {package} отсутствует")
    
    return missing

def install_from_local_wheels(deps_dir):
    """Установить пакеты из локальных wheel файлов"""
    if not deps_dir.exists():
        print(f"❌ Директория {deps_dir} не найдена")
        return False
    
    wheel_files = list(deps_dir.glob("*.whl"))
    if not wheel_files:
        print(f"❌ Wheel файлы не найдены в {deps_dir}")
        return False
    
    print(f"📦 Найдено {len(wheel_files)} wheel файлов")
    
    # Устанавливаем каждый wheel файл
    for wheel in wheel_files:
        print(f"⬇️  Установка {wheel.name}...")
        result = subprocess.run([
            sys.executable, "-m", "pip", "install", 
            "--force-reinstall",
            "--no-index",
            "--find-links", str(deps_dir),
            str(wheel)
        ], capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"⚠️  Предупреждение при установке {wheel.name}: {result.stderr}")
    
    return True

def main():
    script_dir = get_script_dir()
    deps_dir = script_dir / "offline_deps"
    
    print("=" * 60)
    print("🚀 Офлайн-установщик PDFToPPTXConverter")
    print("=" * 60)
    print()
    
    # Проверяем текущие зависимости
    print("🔍 Проверка текущих зависимостей...")
    missing = check_dependencies()
    print()
    
    if not missing:
        print("✅ Все зависимости уже установлены!")
        print()
        print("Вы можете запустить приложение:")
        print(f"  python3 {script_dir}/pdf_to_pptx_gui.py")
        return 0
    
    # Пытаемся установить из локальных файлов
    print("📦 Попытка установки из локальных wheel файлов...")
    if install_from_local_wheels(deps_dir):
        print()
        print("✅ Установка завершена!")
        print()
        print("Проверка установленных зависимостей...")
        remaining = check_dependencies()
        
        if remaining:
            print()
            print("⚠️  Некоторые зависимости не удалось установить:")
            for dep in remaining:
                print(f"   - {dep}")
            print()
            print("Попробуйте запустить с интернетом:")
            print(f"  pip3 install -r {script_dir}/requirements.txt")
            return 1
        else:
            print()
            print("🎉 Все зависимости успешно установлены!")
            print()
            print("Теперь вы можете запустить приложение:")
            print(f"  python3 {script_dir}/pdf_to_pptx_gui.py")
            print()
            print("Или создать DMG:")
            print(f"  bash {script_dir}/build_dmg.sh")
            return 0
    else:
        print()
        print("❌ Не удалось установить зависимости из локальных файлов")
        print()
        print("Для установки требуется интернет:")
        print(f"  pip3 install -r {script_dir}/requirements.txt")
        return 1

if __name__ == "__main__":
    sys.exit(main())
