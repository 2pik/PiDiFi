import sys
import os
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

# Проверка зависимостей перед запуском GUI
try:
    import fitz  # PyMuPDF
    import pptx
    from pptx.util import Inches
except ImportError as e:
    print(f"Ошибка импорта: {e}")
    print("Установите зависимости: pip install pymupdf python-pptx")
    sys.exit(1)

class PDFToPPTXConverter:
    def __init__(self, root):
        self.root = root
        
        # Настройка окна ДО создания виджетов
        self.root.title("PDF в PPTX Конвертер")
        self.root.geometry("600x450")
        self.root.resizable(False, False)
        
        # Попытка установить иконку и имя для macOS (безопасный метод)
        if sys.platform == 'darwin':
            try:
                # Убираем стандартное имя Tcl/Tk приложения, если возможно
                self.root.tk.call('tk', 'scaling', 2.0) 
            except:
                pass

        # Центрирование
        self.center_window()
        
        # Переменные
        self.pdf_path = tk.StringVar()
        self.pptx_path = tk.StringVar()
        
        # Создание интерфейса
        self.create_widgets()
        
        # Принудительная перерисовка сразу после создания
        self.root.update_idletasks()
        self.root.attributes('-topmost', True)
        self.root.after(200, lambda: self.root.attributes('-topmost', False))
        self.root.focus_force()

    def center_window(self):
        ws = self.root.winfo_screenwidth()
        hs = self.root.winfo_screenheight()
        x = (ws/2) - (600/2)
        y = (hs/2) - (450/2)
        self.root.geometry(f'+{int(x)}+{int(y)}')

    def create_widgets(self):
        # Главный контейнер с отступами
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Заголовок
        header = ttk.Label(main_frame, text="Конвертер PDF в PowerPoint", font=("Helvetica", 18, "bold"))
        header.pack(pady=(0, 25))
        
        # Блок выбора PDF
        lbl_pdf = ttk.Label(main_frame, text="Исходный файл (PDF):", font=("Helvetica", 11))
        lbl_pdf.pack(anchor=tk.W, pady=(5, 5))
        
        frame_pdf = ttk.Frame(main_frame)
        frame_pdf.pack(fill=tk.X, pady=5)
        
        self.entry_pdf = ttk.Entry(frame_pdf, textvariable=self.pdf_path, width=50)
        self.entry_pdf.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 10))
        
        btn_browse_pdf = ttk.Button(frame_pdf, text="Выбрать...", command=self.select_pdf)
        btn_browse_pdf.pack(side=tk.RIGHT)
        
        # Блок выбора PPTX
        lbl_pptx = ttk.Label(main_frame, text="Сохранить результат (PPTX):", font=("Helvetica", 11))
        lbl_pptx.pack(anchor=tk.W, pady=(15, 5))
        
        frame_pptx = ttk.Frame(main_frame)
        frame_pptx.pack(fill=tk.X, pady=5)
        
        self.entry_pptx = ttk.Entry(frame_pptx, textvariable=self.pptx_path, width=50)
        self.entry_pptx.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 10))
        
        btn_browse_pptx = ttk.Button(frame_pptx, text="Выбрать...", command=self.select_pptx)
        btn_browse_pptx.pack(side=tk.RIGHT)
        
        # Кнопка запуска
        self.btn_convert = ttk.Button(main_frame, text="НАЧАТЬ КОНВЕРТАЦИЮ", command=self.run_conversion)
        self.btn_convert.pack(pady=30, ipady=10, fill=tk.X)
        
        # Статус
        self.status_label = ttk.Label(main_frame, text="Ожидание запуска...", relief=tk.SUNKEN, anchor=tk.CENTER)
        self.status_label.pack(fill=tk.X, side=tk.BOTTOM, pady=(10, 0))
        
        # Прогресс
        self.progress_bar = ttk.Progressbar(main_frame, mode='indeterminate')
        self.progress_bar.pack(fill=tk.X, pady=(10, 0))

    def select_pdf(self):
        path = filedialog.askopenfilename(title="Выберите PDF файл", filetypes=[("PDF файлы", "*.pdf"), ("Все файлы", "*.*")])
        if path:
            self.pdf_path.set(path)
            # Автозаполнение выхода
            if not self.pptx_path.get():
                base = os.path.splitext(path)[0]
                self.pptx_path.set(base + "_converted.pptx")

    def select_pptx(self):
        path = filedialog.asksaveasfilename(title="Сохранить как PPTX", defaultextension=".pptx", filetypes=[("PowerPoint файлы", "*.pptx"), ("Все файлы", "*.*")])
        if path:
            self.pptx_path.set(path)

    def run_conversion(self):
        pdf_file = self.pdf_path.get()
        pptx_file = self.pptx_path.get()
        
        if not pdf_file or not os.path.exists(pdf_file):
            messagebox.showerror("Ошибка", "Файл PDF не выбран или не существует!")
            return
        if not pptx_file:
            messagebox.showerror("Ошибка", "Не указан путь для сохранения PPTX!")
            return
            
        self.btn_convert.config(state='disabled')
        self.progress_bar.start()
        self.status_label.config(text="Идет конвертация...")
        self.root.update()
        
        try:
            self.convert_logic(pdf_file, pptx_file)
            self.status_label.config(text="Готово! Файл сохранен.")
            messagebox.showinfo("Успех", f"Конвертация завершена!\nФайл: {pptx_file}")
        except Exception as e:
            self.status_label.config(text="Ошибка!")
            messagebox.showerror("Критическая ошибка", str(e))
        finally:
            self.progress_bar.stop()
            self.btn_convert.config(state='normal')

    def convert_logic(self, pdf_path, output_path):
        doc = fitz.open(pdf_path)
        prs = pptx.Presentation()
        
        # Удаляем дефолтный слайд если есть
        if len(prs.slides) > 0:
            sp = prs.slides[0].shapes.element
            sp.getparent().remove(sp)
            
        slide_width = prs.slide_width
        slide_height = prs.slide_height
        
        for i in range(len(doc)):
            page = doc.load_page(i)
            mat = fitz.Matrix(2, 2)
            pix = page.get_pixmap(matrix=mat)
            
            tmp_img = f"temp_slide_{i}.png"
            pix.save(tmp_img)
            
            slide = prs.slides.add_slide(prs.slide_layouts[6])
            # Вставляем картинку на весь слайд
            slide.shapes.add_picture(tmp_img, 0, 0, width=slide_width, height=slide_height)
            
            os.remove(tmp_img)
            
        doc.close()
        prs.save(output_path)

if __name__ == "__main__":
    root = tk.Tk()
    
    # Настройки стиля
    style = ttk.Style()
    style.theme_use('clam')
    
    app = PDFToPPTXConverter(root)
    root.mainloop()
