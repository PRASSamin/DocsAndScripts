# Proper Installation of Cursor AppImage on Linux (Fedora)

This guide covers downloading, modifying, and permanently installing Cursor as an AppImage on Fedora, including resolving issues like double title bars and adding terminal launch support.

---

## 1. Download Cursor AppImage

You can download the Cursor AppImage using `wget` or from the official website:

```sh
wget https://downloader.cursor.sh/linux/appImage/x64 -O ./cursor.AppImage
chmod +x ./cursor.AppImage
```

Or visit: [https://www.cursor.com/](https://www.cursor.com/)

---

## 2. Extract the AppImage

Extract the AppImage to access its source files:

```sh
./cursor.AppImage --appimage-extract
rm ./cursor.AppImage  # Remove the original AppImage file
```

---

## 3. Modify Cursor to Fix Double Title Bar Issue

Find and replace the window configuration settings:

```sh
find squashfs-root/ -type f -name '*.js' \
  -exec grep -l ,minHeight {} \; \
  -exec sed -i 's/,minHeight/,frame:false,minHeight/g' {} \;
```

**`Alternatively`**, manually edit the main file:

```sh
nano squashfs-root/resource/app/out/main.js
```

**`or`**

```sh
nano squashfs-root/resource/app/out/vs/code/electron-main/main.js
```

Replace occurrences of:

```js
,minHeight
```

with:

```js
,frame:false,minHeight
```

---

## 4. Store the Icon File

Save the Cursor icon for later use:

```sh
cp squashfs-root/cursor.png /path/to/cursor.png  # Change path as needed
```

---

## 5. Download AppImage Tool

Download and make the AppImage tool executable:

```sh
wget https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-x86_64.AppImage
chmod +x ./appimagetool-x86_64.AppImage
```

Move it to `/usr/local/bin` for global use:

```sh
sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
```

---

## 6. Rebuild Cursor AppImage

Run:

```sh
ARCH=$(uname -m) appimagetool squashfs-root cursor.AppImage
```

Make the new AppImage executable:

```sh
chmod +x cursor.AppImage
```

---

## 7. Install AppImage Launcher (Optional, for Auto Installation)

Download AppImage Launcher:

```sh
wget https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm
```

Or get the latest version from: [https://github.com/TheAssassin/AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher)

Install it using `dnf`:

```sh
sudo dnf install ./appimagelauncher*.rpm -y
```

Run the `cursor.AppImage` file after installation. This will automatically install the AppImage.

---

## 8. Manually Install Cursor AppImage

Create a permanent installation directory:

```sh
mkdir -p ~/Applications/cursor
cd ~/Applications/cursor
```

Copy the modified Cursor AppImage and icon:

```sh
cp /path/to/cursor.AppImage ./cursor.AppImage
cp /path/to/cursor.png ./cursor.png  # Change path as needed
```

Create a desktop entry:

```sh
sudo nano ~/.local/share/applications/cursor.desktop
```

Paste the following:

```ini
[Desktop Entry]
Name=Cursor
Exec=/home/username/Applications/cursor/cursor.AppImage --no-sandbox %U
Terminal=false
Type=Application
Icon=cursor
StartupWMClass=Cursor
Comment=Cursor is an AI-first coding environment.
MimeType=x-scheme-handler/cursor;
Categories=Utility;
```

Save and close the file, then update the desktop database:

```sh
update-desktop-database ~/.local/share/applications/
```

---

## 9. Enable Terminal Shortcut to Launch Cursor

To open Cursor from the terminal using `cursor .` or `cursor [path]`, add the following function to your `.bashrc` file:

```sh
sudo nano ~/.bashrc
```

Append this at the bottom:

```sh
cursor() {
    setsid /home/username/Applications/cursor.AppImage "$@" >/dev/null 2>&1
}
```

Save and refresh the terminal:

```sh
source ~/.bashrc
```

Now you can run Cursor from the terminal with:

```sh
cursor .
```

or

```sh
cursor [specific path]
```

---

## Conclusion

Following these steps, you have successfully installed, modified, and set up Cursor as a permanent AppImage on Fedora with a fixed UI issue and a terminal shortcut for easy access.
