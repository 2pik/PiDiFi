#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PDF to PPTX Converter for macOS
Графический интерфейс в стиле Apple Human Interface Guidelines
Использует только стандартные библиотеки macOS
"""

import sys
import os
import threading
import io

# Проверка зависимостей перед запуском
def check_dependencies():
    missing = []
    
    try:
        import fitz
    except ImportError:
        missing.append("PyMuPDF")
    
    try:
        from pptx import Presentation
    except ImportError:
        missing.append("python-pptx")
    
    try:
        from PIL import Image
    except ImportError:
        missing.append("Pillow")
    
    if missing:
        return False, missing
    return True, []

# Проверяем зависимости сразу
deps_ok, missing_deps = check_dependencies()
if not deps_ok:
    print("=" * 50)
    print("ОШИБКА: Отсутствуют необходимые модули!")
    print("=" * 50)
    print(f"Не найдено: {', '.join(missing_deps)}")
    print("\nУстановите их командой:")
    print(f"pip3 install {' '.join(missing_deps)}")
    print("=" * 50)
    sys.exit(1)

# Импортируем проверенные модули
import fitz  # PyMuPDF
from pptx import Presentation
from pptx.util import Inches
from PIL import Image

try:
    import tkinter as tk
    from tkinter import ttk, filedialog, messagebox
except ImportError:
    print("Ошибка: tkinter недоступен. Используйте системный Python на macOS.")
    sys.exit(1)


class PDFToPPTXConverter:
    def __init__(self, root):
        self.root = root
        self.root.title("PDF в PPTX Конвертер")
        self.root.geometry("550x450")
        self.root.resizable(False, False)
        
        # Настройка стиля под macOS
        self.style = ttk.Style()
        self.style.theme_use('aqua')
        
        self.pdf_path = None
        self.is_converting = False
        
        self.create_widgets()
    
    def create_widgets(self):
        # Основной контейнер с отступами
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        
        # Заголовок
        title_label = ttk.Label(
            main_frame, 
            text="Конвертер PDF в PowerPoint",
            font=("SF Pro Display", 18, "bold") if sys.platform == "darwin" else ("Helvetica", 18, "bold")
        )
        title_label.grid(row=0, column=0, pady=(0, 20), sticky=tk.W)
        
        # Описание
        desc_label = ttk.Label(
            main_frame,
            text="Выберите PDF файл для конвертации в формат PPTX.\nВсе данные обрабатываются локально на вашем компьютере.",
            font=("SF Pro Text", 11) if sys.platform == "darwin" else ("Helvetica", 11),
            foreground="gray60"
        )
        desc_label.grid(row=1, column=0, pady=(0, 20), sticky=tk.W)
        
        # Фрейм выбора файла
        file_frame = ttk.LabelFrame(main_frame, text="Исходный файл", padding="15")
        file_frame.grid(row=2, column=0, pady=(0, 15), sticky=(tk.W, tk.E))
        file_frame.columnconfigure(0, weight=1)
        
        self.file_path_var = tk.StringVar(value="Файл не выбран")
        file_label = ttk.Label(file_frame, textvariable=self.file_path_var, wraplength=350)
        file_label.grid(row=0, column=0, sticky=tk.W, padx=(0, 10))
        
        self.browse_btn = ttk.Button(file_frame, text="Выбрать...", command=self.browse_file)
        self.browse_btn.grid(row=0, column=1, padx=5)
        
        # Фрейм настроек
        settings_frame = ttk.LabelFrame(main_frame, text="Настройки", padding="15")
        settings_frame.grid(row=3, column=0, pady=(0, 15), sticky=(tk.W, tk.E))
        settings_frame.columnconfigure(1, weight=1)
        
        ttk.Label(settings_frame, text="Имя файла:").grid(row=0, column=0, sticky=tk.W, pady=5)
        self.output_name_var = tk.StringVar(value="presentation.pptx")
        self.output_entry = ttk.Entry(settings_frame, textvariable=self.output_name_var, width=40)
        self.output_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=10, pady=5)
        
        # Кнопка конвертации
        self.convert_btn = ttk.Button(
            main_frame, 
            text="Конвертировать", 
            command=self.start_conversion,
            style="Accent.TButton" if hasattr(self.style, "Accent.TButton") else "TButton"
        )
        self.convert_btn.grid(row=4, column=0, pady=10, sticky=(tk.W, tk.E))
        
        # Прогресс бар
        self.progress_var = tk.DoubleVar()
        self.progress_bar = ttk.Progressbar(
            main_frame, 
            variable=self.progress_var, 
            maximum=100,
            mode='determinate'
        )
        self.progress_bar.grid(row=5, column=0, pady=(10, 5), sticky=(tk.W, tk.E))
        
        # Статус
        self.status_var = tk.StringVar(value="Готов к работе")
        status_label = ttk.Label(main_frame, textvariable=self.status_var, font=("SF Pro Text", 10) if sys.platform == "darwin" else ("Helvetica", 10))
        status_label.grid(row=6, column=0, sticky=tk.W)
        
        # Инфо о локальной обработке
        info_label = ttk.Label(
            main_frame,
            text="✓ Работает оффлайн  ✓ Без облака  ✓ Безопасно",
            font=("SF Pro Text", 9),
            foreground="green4"
        )
        info_label.grid(row=7, column=0, pady=(15, 0), sticky=tk.W)
    
    def browse_file(self):
        filename = filedialog.askopenfilename(
            title="Выберите PDF файл",
            filetypes=[("PDF файлы", "*.pdf"), ("Все файлы", "*.*")]
        )
        if filename:
            self.pdf_path = filename
            filename_display = os.path.basename(filename)
            if len(filename_display) > 50:
                filename_display = filename_display[:47] + "..."
            self.file_path_var.set(filename_display)
            
            # Автозаполнение имени выходного файла
            base_name = os.path.splitext(os.path.basename(filename))[0]
            self.output_name_var.set(f"{base_name}.pptx")
    
    def start_conversion(self):
        if self.is_converting:
            return
            
        if not self.pdf_path:
            messagebox.showwarning("Внимание", "Пожалуйста, выберите PDF файл.")
            return
        
        # Диалог сохранения
        save_path = filedialog.asksaveasfilename(
            title="Сохранить как",
            defaultextension=".pptx",
            initialfile=self.output_name_var.get(),
            filetypes=[("PowerPoint файлы", "*.pptx"), ("Все файлы", "*.*")]
        )
        
        if not save_path:
            return
        
        self.is_converting = True
        self.convert_btn.config(state="disabled", text="Конвертация...")
        self.progress_var.set(0)
        self.status_var.set("Обработка...")
        
        # Запуск в отдельном потоке
        thread = threading.Thread(target=self.convert_process, args=(save_path,))
        thread.daemon = True
        thread.start()
    
    def convert_process(self, save_path):
        try:
            # Открытие PDF документа
            pdf_doc = fitz.open(self.pdf_path)
            total_pages = len(pdf_doc)
            
            # Создание презентации
            prs = Presentation()
            
            # Удаляем пустой слайд по умолчанию
            if len(prs.slides) > 0:
                blank_slide = prs.slides[0]
                prs.slides._sldIdLst.remove(blank_slide._element)
            
            for page_num in range(total_pages):
                # Загрузка страницы
                page = pdf_doc.load_page(page_num)
                
                # Рендеринг страницы в изображение (2x масштаб для качества)
                matrix = fitz.Matrix(2.0, 2.0)
                pixmap = page.get_pixmap(matrix=matrix)
                
                # Конвертация в PIL Image
                img_data = pixmap.tobytes("png")
                img = Image.open(io.BytesIO(img_data))
                
                # Создание нового слайда
                slide = prs.slides.add_slide(prs.slide_layouts[6])  # Blank layout
                
                # Сохранение изображения в буфер
                img_buffer = io.BytesIO()
                img.save(img_buffer, format="PNG")
                img_buffer.seek(0)
                
                # Расчет размеров для центрирования
                slide_width = prs.slide_width
                slide_height = prs.slide_height
                
                # Конвертация размеров изображения в точки (1 дюйм = 72 точки)
                img_width_pts = img.width * 72 / img.dpi[0] if img.dpi[0] > 0 else img.width
                img_height_pts = img.height * 72 / img.dpi[1] if img.dpi[1] > 0 else img.height
                
                # Масштабирование чтобы влезло в слайд с полями
                margin = Inches(0.5)
                max_width = slide_width - (2 * margin)
                max_height = slide_height - (2 * margin)
                
                scale = min(max_width / img_width_pts, max_height / img_height_pts, 1.0)
                
                final_width = img_width_pts * scale
                final_height = img_height_pts * scale
                
                left = (slide_width - final_width) / 2
                top = (slide_height - final_height) / 2
                
                # Добавление изображения на слайд
                slide.shapes.add_picture(img_buffer, left, top, width=final_width, height=final_height)
                
                # Обновление прогресса
                progress = ((page_num + 1) / total_pages) * 100
                self.root.after(0, lambda p=progress, n=page_num+1, t=total_pages: self.update_progress(p, n, t))
            
            pdf_doc.close()
            
            # Сохранение презентации
            prs.save(save_path)
            
            # Успешное завершение
            self.root.after(0, lambda: self.conversion_complete(save_path))
            
        except Exception as e:
            error_msg = str(e)
            self.root.after(0, lambda: self.conversion_error(error_msg))
    
    def update_progress(self, progress, current, total):
        self.progress_var.set(progress)
        self.status_var.set(f"Страница {current} из {total}")
    
    def conversion_complete(self, save_path):
        self.is_converting = False
        self.convert_btn.config(state="normal", text="Конвертировать")
        self.progress_var.set(100)
        self.status_var.set("Готово!")
        
        messagebox.showinfo(
            "Успешно!",
            f"Файл успешно сконвертирован!\n\n{save_path}\n\nТеперь вы можете открыть его в PowerPoint или Keynote."
        )
    
    def conversion_error(self, error):
        self.is_converting = False
        self.convert_btn.config(state="normal", text="Конвертировать")
        self.progress_var.set(0)
        self.status_var.set("Ошибка")
        
        messagebox.showerror(
            "Ошибка конвертации",
            f"Произошла ошибка при конвертации:\n\n{error}\n\nПроверьте, что файл PDF не поврежден."
        )


def main():
    root = tk.Tk()
    
    # Настройка иконки приложения (если есть)
    try:
        if sys.platform == "darwin":
            root.tk.call('wm', 'iconphoto', root._w, tk.PhotoImage())
    except:
        pass
    
    app = PDFToPPTXConverter(root)
    root.mainloop()


if __name__ == "__main__":
    main()
