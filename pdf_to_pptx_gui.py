#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PDF to PPTX Converter for macOS
Графический интерфейс в стиле Apple Human Interface Guidelines
"""

import customtkinter as ctk
from tkinter import filedialog, messagebox
import fitz  # PyMuPDF
from pptx import Presentation
from pptx.util import Inches
from PIL import Image
import os
import threading
import sys


class PDFToPPTXConverter(ctk.CTk):
    def __init__(self):
        super().__init__()
        
        # Настройки окна в стиле macOS
        self.title("PDF в PPTX Конвертер")
        self.geometry("600x500")
        self.resizable(False, False)
        
        # Цветовая схема в стиле Apple
        ctk.set_appearance_mode("system")  # Системная тема (светлая/темная)
        ctk.set_default_color_theme("blue")
        
        # Переменные
        self.pdf_path = None
        self.output_path = None
        self.is_converting = False
        
        # Создание интерфейса
        self.create_widgets()
    
    def create_widgets(self):
        """Создание элементов интерфейса"""
        
        # Заголовок
        self.title_label = ctk.CTkLabel(
            self, 
            text="Конвертация PDF в PowerPoint",
            font=ctk.CTkFont(size=24, weight="bold")
        )
        self.title_label.pack(pady=(30, 10))
        
        self.subtitle_label = ctk.CTkLabel(
            self,
            text="Быстрая локальная конвертация без облака",
            font=ctk.CTkFont(size=14),
            text_color="gray"
        )
        self.subtitle_label.pack(pady=(0, 30))
        
        # Фрейм для выбора файла
        self.file_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.file_frame.pack(pady=10, padx=40, fill="x")
        
        self.file_label = ctk.CTkLabel(
            self.file_frame,
            text="Файл PDF не выбран",
            font=ctk.CTkFont(size=14),
            width=400,
            anchor="w"
        )
        self.file_label.pack(side="left", pady=10)
        
        self.select_btn = ctk.CTkButton(
            self.file_frame,
            text="Выбрать PDF",
            command=self.select_pdf,
            width=120,
            height=40
        )
        self.select_btn.pack(side="right", pady=10, padx=(10, 0))
        
        # Фрейм для выходного файла
        self.output_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.output_frame.pack(pady=10, padx=40, fill="x")
        
        self.output_label = ctk.CTkLabel(
            self.output_frame,
            text="Выходной файл: по умолчанию рядом с PDF",
            font=ctk.CTkFont(size=14),
            width=400,
            anchor="w"
        )
        self.output_label.pack(side="left", pady=10)
        
        self.output_btn = ctk.CTkButton(
            self.output_frame,
            text="Изменить",
            command=self.select_output,
            width=120,
            height=40,
            state="disabled"
        )
        self.output_btn.pack(side="right", pady=10, padx=(10, 0))
        
        # Индикатор прогресса
        self.progress_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.progress_frame.pack(pady=20, padx=40, fill="x")
        
        self.progress_bar = ctk.CTkProgressBar(self.progress_frame, mode="determinate")
        self.progress_bar.pack(fill="x", pady=5)
        self.progress_bar.set(0)
        
        self.status_label = ctk.CTkLabel(
            self.progress_frame,
            text="Готов к работе",
            font=ctk.CTkFont(size=12),
            text_color="gray"
        )
        self.status_label.pack(pady=5)
        
        # Кнопка конвертации
        self.convert_btn = ctk.CTkButton(
            self,
            text="Конвертировать",
            command=self.start_conversion,
            width=200,
            height=50,
            font=ctk.CTkFont(size=16, weight="bold"),
            state="disabled"
        )
        self.convert_btn.pack(pady=30)
        
        # Информация о файле
        self.info_label = ctk.CTkLabel(
            self,
            text="",
            font=ctk.CTkFont(size=12),
            text_color="gray"
        )
        self.info_label.pack(pady=10)
    
    def select_pdf(self):
        """Выбор PDF файла"""
        file_path = filedialog.askopenfilename(
            title="Выберите PDF файл",
            filetypes=[("PDF файлы", "*.pdf"), ("Все файлы", "*.*")]
        )
        
        if file_path:
            self.pdf_path = file_path
            filename = os.path.basename(file_path)
            self.file_label.configure(text=f"📄 {filename}")
            self.output_btn.configure(state="normal")
            self.convert_btn.configure(state="normal")
            
            # Получение информации о файле
            try:
                doc = fitz.open(file_path)
                page_count = len(doc)
                doc.close()
                self.info_label.configure(text=f"Страниц: {page_count}")
                self.output_path = None
                self.output_label.configure(text="Выходной файл: по умолчанию рядом с PDF")
            except Exception as e:
                messagebox.showerror("Ошибка", f"Не удалось открыть PDF: {str(e)}")
                self.pdf_path = None
                self.convert_btn.configure(state="disabled")
    
    def select_output(self):
        """Выбор выходного файла"""
        if not self.pdf_path:
            return
        
        default_name = os.path.splitext(os.path.basename(self.pdf_path))[0] + ".pptx"
        file_path = filedialog.asksaveasfilename(
            title="Сохранить как PPTX",
            defaultextension=".pptx",
            initialfile=default_name,
            filetypes=[("PowerPoint файлы", "*.pptx"), ("Все файлы", "*.*")]
        )
        
        if file_path:
            self.output_path = file_path
            filename = os.path.basename(file_path)
            self.output_label.configure(text=f"💾 {filename}")
    
    def start_conversion(self):
        """Запуск конвертации в отдельном потоке"""
        if not self.pdf_path or self.is_converting:
            return
        
        self.is_converting = True
        self.convert_btn.configure(state="disabled", text="Конвертация...")
        self.select_btn.configure(state="disabled")
        self.output_btn.configure(state="disabled")
        
        # Запуск в отдельном потоке
        thread = threading.Thread(target=self.convert_pdf_to_pptx)
        thread.daemon = True
        thread.start()
    
    def convert_pdf_to_pptx(self):
        """Конвертация PDF в PPTX"""
        try:
            # Определение выходного пути
            if not self.output_path:
                base_name = os.path.splitext(self.pdf_path)[0]
                self.output_path = base_name + ".pptx"
            
            # Открытие PDF
            pdf_doc = fitz.open(self.pdf_path)
            total_pages = len(pdf_doc)
            
            # Создание презентации
            prs = Presentation()
            
            # Стандартный размер слайда (16:9)
            slide_width = Inches(13.333)
            slide_height = Inches(7.5)
            
            for i, page_num in enumerate(range(total_pages)):
                # Обновление прогресса
                progress = (i + 1) / total_pages
                self.after(0, self.update_progress, progress, f"Обработка страницы {i+1}/{total_pages}")
                
                # Рендеринг страницы PDF в изображение
                page = pdf_doc[page_num]
                mat = fitz.Matrix(2, 2)  # Увеличение разрешения в 2 раза
                pix = page.get_pixmap(matrix=mat)
                
                # Сохранение во временный файл
                temp_img = f"/tmp/pdf_page_{i}.png"
                pix.save(temp_img)
                
                # Создание слайда
                if i == 0:
                    slide_layout = prs.slide_layouts[6]  # Пустой слайд
                    slide = prs.slides.add_slide(slide_layout)
                else:
                    slide_layout = prs.slide_layouts[6]
                    slide = prs.slides.add_slide(slide_layout)
                
                # Добавление изображения на слайд
                slide.shapes.add_picture(temp_img, Inches(0), Inches(0), 
                                        width=slide_width, height=slide_height)
                
                # Удаление временного файла
                os.remove(temp_img)
            
            pdf_doc.close()
            
            # Сохранение презентации
            prs.save(self.output_path)
            
            # Успешное завершение
            self.after(0, self.conversion_complete, True)
            
        except Exception as e:
            self.after(0, self.conversion_complete, False, str(e))
    
    def update_progress(self, value, status_text):
        """Обновление индикатора прогресса"""
        self.progress_bar.set(value)
        self.status_label.configure(text=status_text)
    
    def conversion_complete(self, success, error_msg=None):
        """Завершение конвертации"""
        self.is_converting = False
        self.convert_btn.configure(state="normal", text="Конвертировать")
        self.select_btn.configure(state="normal")
        self.output_btn.configure(state="normal")
        
        if success:
            self.progress_bar.set(1.0)
            self.status_label.configure(text="✅ Конвертация завершена!")
            
            # Показать диалог успеха
            response = messagebox.askyesno(
                "Успех!",
                f"Файл сохранен:\n{self.output_path}\n\nОткрыть папку с файлом?"
            )
            
            if response:
                # Открытие папки с файлом
                os.system(f'open "{os.path.dirname(self.output_path)}"')
            
            # Сброс для новой конвертации
            self.after(1000, self.reset_form)
        else:
            self.status_label.configure(text="❌ Ошибка конвертации")
            messagebox.showerror("Ошибка", f"Не удалось конвертировать файл:\n{error_msg}")
            self.progress_bar.set(0)
    
    def reset_form(self):
        """Сброс формы для новой конвертации"""
        self.pdf_path = None
        self.output_path = None
        self.file_label.configure(text="Файл PDF не выбран")
        self.output_label.configure(text="Выходной файл: по умолчанию рядом с PDF")
        self.output_btn.configure(state="disabled")
        self.convert_btn.configure(state="disabled")
        self.info_label.configure(text="")
        self.progress_bar.set(0)
        self.status_label.configure(text="Готов к работе")


def main():
    app = PDFToPPTXConverter()
    app.mainloop()


if __name__ == "__main__":
    main()
