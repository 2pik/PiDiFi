import sys
import os
import logging
import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext
from datetime import datetime

# Настройка логирования
LOG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "converter.log")
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE, encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

logger.info("="*50)
logger.info("Запуск приложения PDF в PPTX Конвертер")
logger.info(f"Путь к лог-файлу: {LOG_FILE}")
logger.info(f"Версия Python: {sys.version}")
logger.info(f"Платформа: {sys.platform}")

# Проверка зависимостей перед запуском GUI
try:
    import fitz  # PyMuPDF
    logger.debug("PyMuPDF успешно импортирован")
    import pptx
    logger.debug("python-pptx успешно импортирован")
    from pptx.util import Inches
except ImportError as e:
    logger.error(f"Критическая ошибка импорта: {e}")
    print(f"Ошибка импорта: {e}")
    print("Установите зависимости: pip install pymupdf python-pptx")
    sys.exit(1)

class PDFToPPTXConverter:
    def __init__(self, root):
        self.root = root
        logger.info("Инициализация основного окна...")
        
        # Настройка окна ДО создания виджетов
        self.root.title("PDF в PPTX Конвертер")
        self.root.geometry("700x550")  # Увеличили высоту для лога
        self.root.resizable(False, False)
        
        # Исправление имени приложения в меню macOS
        if sys.platform == 'darwin':
            try:
                # Метод 1: Прямое изменение имени через Tcl/Tk
                self.root.tk.call('wish', 'title', 'PDF в PPTX Конвертер')
                logger.debug("Попытка изменения имени через wish title")
            except Exception as e:
                logger.warning(f"Не удалось изменить имя через wish: {e}")
            
            try:
                # Метод 2: Установка имени процесса (работает не всегда в GUI)
                from ctypes import cdll, byref, create_string_buffer
                libc = cdll.LoadLibrary('libc.dylib')
                buf = create_string_buffer(len("PDFToPPTXConverter") + 1)
                buf.value = b"PDFToPPTXConverter"
                libc.setproctitle(byref(buf))
                logger.debug("Попытка изменения имени процесса через setproctitle")
            except Exception as e:
                logger.warning(f"Не удалось изменить имя процесса: {e}")

        # Центрирование
        self.center_window()
        logger.debug("Окно отцентрировано")
        
        # Переменные
        self.pdf_path = tk.StringVar()
        self.pptx_path = tk.StringVar()
        
        # Создание интерфейса
        self.create_widgets()
        logger.info("Интерфейс создан")
        
        # Принудительная перерисовка сразу после создания
        self.root.update_idletasks()
        self.root.attributes('-topmost', True)
        self.root.after(200, lambda: self.root.attributes('-topmost', False))
        self.root.focus_force()
        logger.info("Окно показано на переднем плане")
        
        # Добавление первой записи в лог в интерфейсе
        self.add_log_entry("Приложение запущено. Ожидание действий пользователя...")

    def center_window(self):
        ws = self.root.winfo_screenwidth()
        hs = self.root.winfo_screenheight()
        x = (ws/2) - (600/2)
        y = (hs/2) - (450/2)
        self.root.geometry(f'+{int(x)}+{int(y)}')

    def create_widgets(self):
        # Главный контейнер с отступами
        main_frame = ttk.Frame(self.root, padding="15")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Заголовок
        header = ttk.Label(main_frame, text="Конвертер PDF в PowerPoint", font=("Helvetica", 16, "bold"))
        header.pack(pady=(0, 15))
        
        # Блок выбора PDF
        lbl_pdf = ttk.Label(main_frame, text="Исходный файл (PDF):", font=("Helvetica", 10))
        lbl_pdf.pack(anchor=tk.W, pady=(5, 2))
        
        frame_pdf = ttk.Frame(main_frame)
        frame_pdf.pack(fill=tk.X, pady=2)
        
        self.entry_pdf = ttk.Entry(frame_pdf, textvariable=self.pdf_path, width=40)
        self.entry_pdf.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 5))
        
        btn_browse_pdf = ttk.Button(frame_pdf, text="Обзор...", command=self.select_pdf)
        btn_browse_pdf.pack(side=tk.RIGHT)
        
        # Блок выбора PPTX
        lbl_pptx = ttk.Label(main_frame, text="Сохранить как (PPTX):", font=("Helvetica", 10))
        lbl_pptx.pack(anchor=tk.W, pady=(10, 2))
        
        frame_pptx = ttk.Frame(main_frame)
        frame_pptx.pack(fill=tk.X, pady=2)
        
        self.entry_pptx = ttk.Entry(frame_pptx, textvariable=self.pptx_path, width=40)
        self.entry_pptx.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 5))
        
        btn_browse_pptx = ttk.Button(frame_pptx, text="Обзор...", command=self.select_pptx)
        btn_browse_pptx.pack(side=tk.RIGHT)
        
        # Кнопка запуска
        self.btn_convert = ttk.Button(main_frame, text="НАЧАТЬ КОНВЕРТАЦИЮ", command=self.run_conversion)
        self.btn_convert.pack(pady=20, ipady=8, fill=tk.X)
        
        # Прогресс
        self.progress_bar = ttk.Progressbar(main_frame, mode='indeterminate')
        self.progress_bar.pack(fill=tk.X, pady=(10, 5))
        
        # Статус
        self.status_label = ttk.Label(main_frame, text="Ожидание...", relief=tk.SUNKEN, anchor=tk.CENTER, font=("Helvetica", 9))
        self.status_label.pack(fill=tk.X, pady=(0, 10))
        
        # Панель логов
        log_frame = ttk.LabelFrame(main_frame, text="Журнал событий (последние записи)", padding=5)
        log_frame.pack(fill=tk.BOTH, expand=True)
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=8, font=("Courier", 9), state='disabled', wrap=tk.WORD)
        self.log_text.pack(fill=tk.BOTH, expand=True)
        
        # Кнопка очистки логов
        btn_clear_log = ttk.Button(log_frame, text="Очистить журнал", command=self.clear_log)
        btn_clear_log.pack(anchor=tk.E, pady=(5, 0))

    def add_log_entry(self, message):
        """Добавляет запись в лог в интерфейсе"""
        self.log_text.config(state='normal')
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.log_text.insert(tk.END, f"[{timestamp}] {message}\n")
        self.log_text.see(tk.END)  # Прокрутка вниз
        self.log_text.config(state='disabled')
        
        # Также пишем в файл через logger
        logger.info(message)

    def clear_log(self):
        """Очищает журнал в интерфейсе"""
        self.log_text.config(state='normal')
        self.log_text.delete(1.0, tk.END)
        self.log_text.config(state='disabled')
        self.add_log_entry("Журнал очищен пользователем")

    def select_pdf(self):
        self.add_log_entry("Пользователь нажал кнопку выбора PDF файла")
        path = filedialog.askopenfilename(title="Выберите PDF файл", filetypes=[("PDF файлы", "*.pdf"), ("Все файлы", "*.*")])
        if path:
            self.pdf_path.set(path)
            self.add_log_entry(f"Выбран PDF файл: {path}")
            # Автозаполнение выхода
            if not self.pptx_path.get():
                base = os.path.splitext(path)[0]
                new_pptx = base + "_converted.pptx"
                self.pptx_path.set(new_pptx)
                self.add_log_entry(f"Автозаполнен путь для PPTX: {new_pptx}")
        else:
            self.add_log_entry("Выбор файла отменен")

    def select_pptx(self):
        self.add_log_entry("Пользователь нажал кнопку сохранения PPTX")
        path = filedialog.asksaveasfilename(title="Сохранить как PPTX", defaultextension=".pptx", filetypes=[("PowerPoint файлы", "*.pptx"), ("Все файлы", "*.*")])
        if path:
            self.pptx_path.set(path)
            self.add_log_entry(f"Указан путь для сохранения: {path}")
        else:
            self.add_log_entry("Сохранение отменено")

    def run_conversion(self):
        self.add_log_entry("Запуск процесса конвертации")
        pdf_file = self.pdf_path.get()
        pptx_file = self.pptx_path.get()
        
        if not pdf_file or not os.path.exists(pdf_file):
            msg = "Файл PDF не выбран или не существует!"
            self.add_log_entry(f"Ошибка: {msg}")
            messagebox.showerror("Ошибка", msg)
            return
        if not pptx_file:
            msg = "Не указан путь для сохранения PPTX!"
            self.add_log_entry(f"Ошибка: {msg}")
            messagebox.showerror("Ошибка", msg)
            return
            
        self.btn_convert.config(state='disabled')
        self.progress_bar.start()
        self.status_label.config(text="Идет конвертация...")
        self.add_log_entry("Начало обработки файла...")
        self.root.update()
        
        try:
            self.convert_logic(pdf_file, pptx_file)
            self.status_label.config(text="Готово! Файл сохранен.")
            self.add_log_entry(f"Конвертация успешно завершена! Результат: {pptx_file}")
            messagebox.showinfo("Успех", f"Конвертация завершена!\nФайл: {pptx_file}")
        except Exception as e:
            error_msg = str(e)
            self.add_log_entry(f"КРИТИЧЕСКАЯ ОШИБКА при конвертации: {error_msg}")
            self.status_label.config(text="Ошибка!")
            messagebox.showerror("Критическая ошибка", error_msg)
        finally:
            self.progress_bar.stop()
            self.btn_convert.config(state='normal')
            self.add_log_entry("Процесс конвертации завершен (успешно или с ошибкой)")

    def convert_logic(self, pdf_path, output_path):
        self.add_log_entry(f"Открытие PDF файла: {pdf_path}")
        doc = fitz.open(pdf_path)
        self.add_log_entry(f"PDF открыт. Количество страниц: {len(doc)}")
        
        self.add_log_entry("Создание новой презентации PowerPoint...")
        prs = pptx.Presentation()
        
        # Удаляем дефолтный слайд если есть
        if len(prs.slides) > 0:
            sp = prs.slides[0].shapes.element
            sp.getparent().remove(sp)
            self.add_log_entry("Удален стандартный слайд из шаблона")
            
        slide_width = prs.slide_width
        slide_height = prs.slide_height
        
        for i in range(len(doc)):
            self.add_log_entry(f"Обработка страницы {i+1} из {len(doc)}...")
            page = doc.load_page(i)
            mat = fitz.Matrix(2, 2)
            pix = page.get_pixmap(matrix=mat)
            
            tmp_img = f"temp_slide_{i}.png"
            pix.save(tmp_img)
            self.add_log_entry(f"  Страница {i+1}: изображение сохранено во временный файл")
            
            slide = prs.slides.add_slide(prs.slide_layouts[6])
            # Вставляем картинку на весь слайд
            slide.shapes.add_picture(tmp_img, 0, 0, width=slide_width, height=slide_height)
            self.add_log_entry(f"  Страница {i+1}: добавлена в презентацию")
            
            os.remove(tmp_img)
            
        doc.close()
        self.add_log_entry(f"Сохранение результата в: {output_path}")
        prs.save(output_path)
        self.add_log_entry("Файл успешно сохранен!")

if __name__ == "__main__":
    root = tk.Tk()
    
    # Настройки стиля
    style = ttk.Style()
    style.theme_use('clam')
    
    logger.info("Создание экземпляра приложения...")
    app = PDFToPPTXConverter(root)
    logger.info("Запуск главного цикла событий...")
    root.mainloop()
