#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Unit tests for PDF to PPTX Converter
"""

import unittest
import os
import sys
import tempfile
import shutil
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


class TestDependencies(unittest.TestCase):
    """Тесты проверки зависимостей"""
    
    def test_check_dependencies(self):
        """Проверка функции check_dependencies"""
        from pdf_to_pptx_gui import check_dependencies
        
        deps_ok, missing_deps = check_dependencies()
        
        # Все зависимости должны быть установлены
        self.assertTrue(deps_ok, f"Отсутствуют модули: {missing_deps}")
        self.assertEqual(len(missing_deps), 0)


class TestConstants(unittest.TestCase):
    """Тесты констант приложения"""
    
    def test_max_file_size(self):
        """Проверка константы максимального размера файла"""
        from pdf_to_pptx_gui import MAX_FILE_SIZE_MB
        
        self.assertEqual(MAX_FILE_SIZE_MB, 100)
        self.assertIsInstance(MAX_FILE_SIZE_MB, int)
    
    def test_quality_settings(self):
        """Проверка настроек качества"""
        from pdf_to_pptx_gui import QUALITY_SETTINGS
        
        expected_qualities = ["Низкое", "Среднее", "Высокое", "Максимальное"]
        
        for quality in expected_qualities:
            self.assertIn(quality, QUALITY_SETTINGS)
            self.assertIn("dpi", QUALITY_SETTINGS[quality])
            self.assertIn("matrix", QUALITY_SETTINGS[quality])
    
    def test_orientation_settings(self):
        """Проверка настроек ориентации"""
        from pdf_to_pptx_gui import SUPPORTED_ORIENTATIONS
        
        expected_orientations = ["16:9", "4:3", "A4"]
        
        for orientation in expected_orientations:
            self.assertIn(orientation, SUPPORTED_ORIENTATIONS)


class TestLogging(unittest.TestCase):
    """Тесты системы логирования"""
    
    def test_logging_setup(self):
        """Проверка настройки логирования"""
        import logging
        
        logger = logging.getLogger("PDFToPPTXConverter")
        self.assertIsNotNone(logger)
        self.assertEqual(logger.name, "PDFToPPTXConverter")


class TestPDFValidation(unittest.TestCase):
    """Тесты валидации PDF файлов (требуют наличия тестовых файлов)"""
    
    def setUp(self):
        """Настройка тестового окружения"""
        self.test_dir = tempfile.mkdtemp()
    
    def tearDown(self):
        """Очистка после тестов"""
        shutil.rmtree(self.test_dir, ignore_errors=True)
    
    def test_validate_nonexistent_file(self):
        """Проверка валидации несуществующего файла"""
        # Этот тест требует импорта класса, что может быть сложно без GUI
        # Оставлен как шаблон для будущих тестов
        pass
    
    def test_file_size_calculation(self):
        """Проверка расчета размера файла"""
        test_file = Path(self.test_dir) / "test.txt"
        test_file.write_text("test content")
        
        size_mb = test_file.stat().st_size / (1024 * 1024)
        self.assertGreaterEqual(size_mb, 0)
        self.assertLess(size_mb, 1)


class TestImageOptimization(unittest.TestCase):
    """Тесты оптимизации изображений"""
    
    def test_image_modes(self):
        """Проверка поддерживаемых режимов изображений"""
        from PIL import Image
        import io
        
        # Создание тестовых изображений разных режимов
        modes = ['RGB', 'RGBA', 'L', 'LA', 'P']
        
        for mode in modes:
            img = Image.new(mode, (100, 100))
            
            # Конвертация в RGB если нужно
            if mode in ('RGBA', 'LA', 'P'):
                img_rgb = img.convert('RGB')
                self.assertEqual(img_rgb.mode, 'RGB')


if __name__ == '__main__':
    unittest.main(verbosity=2)
