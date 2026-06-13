import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import fitz  # PyMuPDF
import os
import sys
import logging
from datetime import datetime
import threading

# Настройка логирования
LOG_FILE = "converter.log"
try:
    logging.basicConfig(
        filename=LOG_FILE,
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        encoding='utf-8'
    )
except Exception:
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
logger = logging.getLogger(__name__)

class PDFToPPTXConverter:
    def __init__(self, root):
        self.root = root
        self.root.title("PDF в PPTX Конвертер")
        self.root.geometry("600x500")
        
        self.input_path = tk.StringVar()
        self.output_path = tk.StringVar()
        self.is_converting = False

        self.create_widgets()
        self.log_message("Приложение запущено. Готов к работе.")
        
        self.root.after(100, self.finalize_ui)

    def finalize_ui(self):
        self.root.update_idletasks()
        self.root.lift()
        self.root.focus_force()

    def create_widgets(self):
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)

        ttk.Label(main_frame, text="Выберите PDF файл:").grid(row=0, column=0, sticky=tk.W, pady=5)
        ttk.Entry(main_frame, textvariable=self.input_path, width=50).grid(row=1, column=0, sticky=(tk.W, tk.E), pady=5)
        ttk.Button(main_frame, text="Обзор...", command=self.browse_input).grid(row=1, column=1, padx=5)

        ttk.Label(main_frame, text="Сохранить как PPTX:").grid(row=2, column=0, sticky=tk.W, pady=5)
        ttk.Entry(main_frame, textvariable=self.output_path, width=50).grid(row=3, column=0, sticky=(tk.W, tk.E), pady=5)
        ttk.Button(main_frame, text="Обзор...", command=self.browse_output).grid(row=3, column=1, padx=5)

        self.convert_btn = ttk.Button(main_frame, text="Конвертировать", command=self.start_conversion)
        self.convert_btn.grid(row=4, column=0, columnspan=2, pady=20, sticky=(tk.W, tk.E))

        self.progress = ttk.Progressbar(main_frame, mode='indeterminate')
        self.progress.grid(row=5, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=5)

        ttk.Label(main_frame, text="Журнал событий:").grid(row=6, column=0, sticky=tk.W, pady=(10, 0))
        
        log_frame = ttk.Frame(main_frame)
        log_frame.grid(row=7, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), pady=5)
        main_frame.rowconfigure(7, weight=1)
        log_frame.columnconfigure(0, weight=1)
        log_frame.rowconfigure(0, weight=1)

        self.log_text = tk.Text(
            log_frame, 
            height=10, 
            width=60, 
            wrap=tk.WORD, 
            state='disabled', 
            bg='#f0f0f0',
            font=('Courier', 9)
        )
        self.log_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        scrollbar = ttk.Scrollbar(log_frame, orient=tk.VERTICAL, command=self.log_text.yview)
        scrollbar.grid(row=0, column=1, sticky=(tk.N, tk.S))
        self.log_text.configure(yscrollcommand=scrollbar.set)

    def log_message(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        full_message = f"[{timestamp}] {message}"
        
        try:
            logger.info(message)
        except:
            pass
        
        try:
            self.log_text.config(state='normal')
            self.log_text.insert(tk.END, full_message + "\n")
            self.log_text.see(tk.END)
            self.log_text.config(state='disabled')
            self.log_text.update_idletasks()
        except Exception as e:
            print(f"Ошибка обновления лога: {e}")

    def browse_input(self):
        filename = filedialog.askopenfilename(title="Выберите PDF", filetypes=[("PDF files", "*.pdf")])
        if filename:
            self.input_path.set(filename)
            base_name = os.path.splitext(filename)[0]
            self.output_path.set(base_name + ".pptx")
            self.log_message(f"Выбран файл: {filename}")

    def browse_output(self):
        filename = filedialog.asksaveasfilename(title="Сохранить как", defaultextension=".pptx", filetypes=[("PPTX files", "*.pptx")])
        if filename:
            self.output_path.set(filename)
            self.log_message(f"Путь сохранения: {filename}")

    def start_conversion(self):
        if not self.input_path.get():
            messagebox.showerror("Ошибка", "Выберите входной PDF файл!")
            return
        
        if not self.output_path.get():
            messagebox.showerror("Ошибка", "Укажите путь для сохранения!")
            return

        if self.is_converting:
            return

        self.is_converting = True
        self.convert_btn.config(state='disabled')
        self.progress.start()
        self.log_message("Начало конвертации...")

        thread = threading.Thread(target=self.convert_pdf_to_pptx)
        thread.daemon = True
        thread.start()

    def convert_pdf_to_pptx(self):
        try:
            input_file = self.input_path.get()
            output_file = self.output_path.get()

            if not os.path.exists(input_file):
                raise FileNotFoundError(f"Файл не найден: {input_file}")

            self.log_message(f"Открытие PDF: {input_file}")
            doc = fitz.open(input_file)
            page_count = len(doc)
            self.log_message(f"Страниц найдено: {page_count}")

            import pptx
            
            prs = pptx.Presentation()
            
            for i, page in enumerate(doc):
                self.log_message(f"Обработка страницы {i+1}/{page_count}...")
                slide_layout = prs.slide_layouts[6]
                slide = prs.slides.add_slide(slide_layout)

            self.log_message("Сохранение презентации...")
            prs.save(output_file)
            
            self.log_message("Конвертация успешно завершена!")
            messagebox.showinfo("Успех", f"Файл сохранен:\n{output_file}")

        except ImportError:
            err_msg = "Библиотека python-pptx не найдена. Установите: pip install python-pptx"
            logger.error(err_msg)
            self.log_message("ОШИБКА: " + err_msg)
            messagebox.showerror("Ошибка", err_msg)
        except Exception as e:
            error_str = str(e)
            logger.error(f"Ошибка конвертации: {error_str}")
            self.log_message(f"ОШИБКА: {error_str}")
            messagebox.showerror("Ошибка", f"Произошла ошибка:\n{error_str}")
        
        finally:
            self.is_converting = False
            self.convert_btn.config(state='normal')
            self.progress.stop()
            self.log_message("Готов к новой задаче.")

if __name__ == "__main__":
    root = tk.Tk()
    app = PDFToPPTXConverter(root)
    root.mainloop()
