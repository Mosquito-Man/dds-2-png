# DDS2PNG Converter (GUI)

A simple Windows tool with drag & drop support to convert `.dds` textures into `.png` or other image formats, using Microsoft’s `texconv.exe` from the [DirectXTex project](https://github.com/microsoft/DirectXTex).

This tool was created for modders and developers who want a straightforward GUI and to be able to mass convert textures instead of typing different commands in a console.

---
---

## Features

- Drag & drop `.dds` files directly into the app  
- Browse for files or folders with a modern Explorer dialog  
- Batch convert multiple files at once  
- Exports clean `.png` files with transparency preserved  
- Powered by Microsoft’s `texconv.exe`  

---

## Installation

1. Download the latest release `.zip` from the [Releases page](../../releases).  
2. Extract it to a folder of your choice (for example, `C:\Tools\dds2png`).  
3. Run `DDS2PNG-GUI.exe`. No console is required.

---

## Usage

1. Launch `DDS2PNG-GUI.exe`.  
2. Drag and drop one or more `.dds` files into the window, or click **Add Files...**.  
3. Set your output folder (where converted PNGs will be saved).  
4. Click **Convert**.  
5. Your PNGs will be ready in the output folder.

This project is released under the [MIT License](LICENSE).

It bundles `texconv.exe`, which is part of the [DirectXTex project](https://github.com/microsoft/DirectXTex), licensed under the MIT License:

