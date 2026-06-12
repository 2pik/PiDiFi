# PDF to PPTX Converter for macOS

A native macOS application for converting PDF files to PowerPoint presentations with a graphical user interface.

![macOS](https://img.shields.io/badge/macOS-10.15+-silver?logo=apple)
![Python](https://img.shields.io/badge/Python-3.8+-blue?logo=python)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- ✅ **100% Local Processing** — all data is processed on your computer
- ✅ **No Cloud Services** — no files are uploaded to the internet
- ✅ **Native GUI** following Apple Human Interface Guidelines
- ✅ **Auto Theme** — light/dark mode based on system settings
- ✅ **Easy Installation** — download DMG and drag to Applications
- ✅ **Easy Uninstall** — drag to Trash or use uninstall script

## 📥 Download

Get the latest installer from **[GitHub Releases](https://github.com/YOUR_USERNAME/pdf-to-pptx-converter/releases)**

Or install from source:

```bash
git clone https://github.com/YOUR_USERNAME/pdf-to-pptx-converter.git
cd pdf-to-pptx-converter
./build_dmg.sh  # Create DMG installer
```

## System Requirements

- macOS 10.15 (Catalina) or later
- Python 3.8+ (for source installation)
- ~50 MB free disk space

## Installation

### Option 1: From DMG (Recommended)

1. Download `PDFToPPTXConverter-Installer.dmg`
2. Open the DMG file by double-clicking
3. Drag `PDFToPPTXConverter.app` to `Applications` folder
4. Launch the app from Applications

### Option 2: From Source

```bash
chmod +x install.sh
./install.sh
```

## Running the App

### Via Finder:
1. Open Finder
2. Go to `Applications`
3. Double-click `PDFToPPTXConverter.app`

### Via Terminal:
```bash
open ~/Applications/PDFToPPTXConverter.app
```

### ⚠️ First Launch
macOS may warn about an unidentified developer:
1. Go to **System Settings** → **Privacy & Security**
2. Click **Allow** next to the app blocking message

Or right-click the app → Open → Open

## Usage

1. Click **"Выбрать PDF"** and select your PDF file
2. (Optional) Click **"Изменить"** to choose output location
3. Click **"Конвертировать"**
4. Wait for the conversion to complete
5. The file will be saved and the folder will open automatically

## Uninstall

### Option 1: Via Finder
Simply drag `PDFToPPTXConverter.app` from Applications to Trash.

### Option 2: Via Script
```bash
./uninstall.sh
```

To fully remove Python dependencies (optional):
```bash
pip3 uninstall customtkinter PyMuPDF python-pptx Pillow
```

## Dependencies

The app automatically installs these packages on first launch:
- `customtkinter` — modern GUI framework
- `PyMuPDF` — PDF processing
- `python-pptx` — PowerPoint presentation creation
- `Pillow` — image processing

## How It Works

1. Opens PDF file using PyMuPDF
2. Renders each page as a high-quality image (2x scale)
3. Adds images to PowerPoint slides in 16:9 format
4. Saves result as .pptx file

## Security

- All files are processed **locally** on your computer
- No data is **transmitted** to the internet
- Temporary files are deleted immediately after processing
- Original PDF remains unchanged

## Format Support

- **Input**: PDF (any version)
- **Output**: PPTX (PowerPoint 2007+)
- **Slide Size**: 16:9 (widescreen standard)
- **Quality**: 2x resolution scaling for text clarity

## Project Structure

```
pdf-to-pptx-converter/
├── pdf_to_pptx_gui.py    # Main GUI application
├── install.sh            # Source installation script
├── uninstall.sh          # Uninstall script
├── build_dmg.sh          # DMG builder script
├── requirements.txt      # Dependencies list
└── README.md             # This file
```

## Building DMG for Distribution

To create a distributable DMG file:

```bash
chmod +x build_dmg.sh
./build_dmg.sh
```

This creates `PDFToPPTXConverter-Installer.dmg` which you can:
- Upload to GitHub Releases
- Distribute directly to users

## Publishing to GitHub Releases

To make the app downloadable for users:

1. Create a repository on GitHub
2. Push all project files:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/pdf-to-pptx-converter.git
   git push -u origin main
   ```

3. Build the DMG on Mac:
   ```bash
   ./build_dmg.sh
   ```

4. Create a Release on GitHub:
   - Go to repo → Releases → Create a new release
   - Tag version (e.g., v1.0.0)
   - Attach `PDFToPPTXConverter-Installer.dmg`
   - Publish release

Users can now download the installer from the Releases page!

## Troubleshooting

### App won't launch
Make sure Python 3 is installed:
```bash
python3 --version
```

### Dependency installation error
Try updating pip:
```bash
pip3 install --upgrade pip
```

### Conversion hangs on large files
Large PDFs may take several minutes. Progress bar shows status.

### macOS blocks the app
1. Right-click the app
2. Select "Open"
3. Confirm in the dialog

## License

MIT License — free to use and modify.

---

**Made with ❤️ for macOS users**
