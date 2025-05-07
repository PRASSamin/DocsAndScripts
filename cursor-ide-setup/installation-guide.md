# Proper Installation of Cursor AppImage on Linux (Fedora)

This guide covers downloading, modifying, and permanently installing **Cursor** as an AppImage on Fedora, including resolving issues like double title bars and adding terminal launch support.

---

## 1. Download Cursor AppImage

You can download the Cursor AppImage either via the command line or from the official website:

### **Using the Terminal:**

```sh
CURSOR_DOWNLOAD_URL=$(wget -qO- https://raw.githubusercontent.com/oslook/cursor-ai-downloads/refs/heads/main/version-history.json | jq -r --arg arch "$(uname -m)" '.versions[0].platforms[if $arch == "x86_64" then "linux-x64" elif $arch == "aarch64" then "linux-arm64" else error("Unsupported architecture: \($arch)") end]')
wget "$CURSOR_DOWNLOAD_URL" -O ./cursor.AppImage
chmod +x ./cursor.AppImage
```

Alternatively, you can download the AppImage from [Cursor’s official website](https://www.cursor.com/).

---

## 2. Extract the AppImage

To extract the AppImage and access its source files, run:

```sh
./cursor.AppImage --appimage-extract
rm ./cursor.AppImage  # Remove the original AppImage file
```

---

## 3. Modify Cursor to Fix Double Title Bar Issue

Locate and modify the window configuration to remove the double title bar. This involves finding the necessary files and making changes:

```sh
find squashfs-root/ -type f -name '*.js' \
  -exec grep -l ,minHeight {} \; \
  -exec sed -i 's/,minHeight/,frame:false,minHeight/g' {} \;
```

**Alternatively**, you can manually edit the main file:

```sh
nano squashfs-root/resource/app/out/main.js
```

or

```sh
nano squashfs-root/resource/app/out/vs/code/electron-main/main.js
```

Look for and replace:

```js
,minHeight
```

with:

```js
,frame:false,minHeight
```

---

## 4. Prepare Cursor Icon

To ensure the icon is correctly included, copy the Cursor icon:

```sh
cp $(find "$INSTALL_DIR" -type f -name "cursor.png" | head -n 1) squashfs-root/usr/cursor.png
```

---

## 5. Prepare Installation Directory

Create a permanent installation directory where the app will reside:

```sh
mkdir ~/cursor
```

---

## 6. Move Files to Permanent Installation Directory

Copy the extracted files to the permanent directory:

```sh
cp -r squashfs-root/usr/* ~/cursor
```

---

## 7. Create Desktop Entry

For easy access, create a desktop entry:

```sh
sudo nano ~/.local/share/applications/cursor.desktop
```

Paste the following content:

```ini
[Desktop Entry]
Name=Cursor
Comment=The AI Code Editor.
GenericName=Text Editor
Exec=~/cursor/bin/cursor
Icon=~/cursor/cursor.png
Type=Application
StartupNotify=false
StartupWMClass=Cursor
Categories=TextEditor;Development;IDE;
MimeType=application/x-cursor-workspace;
Actions=new-empty-window;
Keywords=cursor;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=$INSTALL_DIR/bin/cursor --new-window
Icon=$INSTALL_DIR/cursor.png
```

Save and close the file. Then update the desktop database:

```sh
update-desktop-database ~/.local/share/applications/
```

---

## 9. Enable Terminal Shortcut to Launch Cursor

To launch Cursor from the terminal using `cursor .` or `cursor [path]`, add the following function to your `.bashrc` file:

```sh
sudo nano ~/.bashrc
```

Append this line at the bottom:

```sh
export PATH="$HOME/cursor/bin:$PATH"
```

Save the file and refresh your terminal:

```sh
source ~/.bashrc
```

You can now run Cursor directly from the terminal with:

```sh
cursor .
```

or

```sh
cursor [specific path]
```

---

## Conclusion

Following these steps, you've successfully:

* Downloaded and installed Cursor AppImage on Fedora
* Fixed the double title bar issue
* Set up a terminal shortcut for quick access

You now have a fully functional Cursor editor, installed permanently on your system. Enjoy coding with Cursor! 😄

---