#!/bin/bash

set -e

# ─── Safety Check ───────────────────────────────────────────────
if [ "$(id -u)" -eq 0 ]; then
    echo "❌ Error: Do not run this script as root. Exiting..."
    exit 1
fi

# ─── Colors ──────────────────────────────────────────────────────
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
NC="\e[0m"

# ─── Requirements ───────────────────────────────────────────────
for cmd in wget jq grep sed; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}Error: '$cmd' is required but not installed.${NC}"
        exit 1
    fi
done

# ─── Variables ───────────────────────────────────────────────────
CURSOR_VERSION_HISTORY_JSON_URL="https://raw.githubusercontent.com/oslook/cursor-ai-downloads/refs/heads/main/version-history.json"
INSTALL_DIR="$HOME/cursor"
DESKTOP_FILE="$HOME/.local/share/applications/cursor.desktop"
BASHRC_FILE="$HOME/.bashrc"
TMP_DIR="$(mktemp -d)"
ARCH=$(uname -m)

# ─── Prepare Temp Dir ───────────────────────────────────────────
if [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
else
  mkdir -p "$TMP_DIR"
fi

# ─── Fetch Version Info ─────────────────────────────────────────
echo -e "${YELLOW}Fetching latest version info...${NC}"
wget -q "$CURSOR_VERSION_HISTORY_JSON_URL" -O "$TMP_DIR/version-history.json"
LATEST_VERSION=$(jq -r '.versions[0].version' "$TMP_DIR/version-history.json")

# ─── Check Installed Version ────────────────────────────────────
INSTALLED_VERSION=""
if [ -f "$DESKTOP_FILE" ]; then
    INSTALLED_VERSION=$(grep "^X-AppImage-Version=" "$DESKTOP_FILE" | cut -d'=' -f2)
fi

if [ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]; then
    echo -e "${GREEN}✅ Cursor is already up to date (v$LATEST_VERSION).${NC}"
    rm -rf "$TMP_DIR"
    exit 0
fi

# ─── Get Download URL ────────────────────────────────────────────
if [[ "$ARCH" == "x86_64" ]]; then
    PLATFORM="linux-x64"
elif [[ "$ARCH" == "aarch64" ]]; then
    PLATFORM="linux-arm64"
else
    echo -e "${RED}Unsupported architecture: $ARCH${NC}"
    rm -rf "$TMP_DIR"
    exit 1
fi

DOWNLOAD_URL=$(jq -r ".versions[] | select(.version == \"$LATEST_VERSION\") | .platforms[\"$PLATFORM\"]" "$TMP_DIR/version-history.json")

# ─── Download and Extract ───────────────────────────────────────
echo -e "${YELLOW}Downloading Cursor v$LATEST_VERSION...${NC}"
wget "$DOWNLOAD_URL" -O "$TMP_DIR/cursor.AppImage"
chmod +x "$TMP_DIR/cursor.AppImage"

echo -e "${YELLOW}Extracting AppImage...${NC}"
cd "$TMP_DIR"
./cursor.AppImage --appimage-extract > /dev/null

# ─── Modify Frame Style ─────────────────────────────────────────
# The double title bar issue was fixed starting from Cursor v0.48, so frame modification is no longer needed
# find squashfs-root/ -type f -name '*.js' \
#   -exec sed -i 's/,minHeight/,frame:false,minHeight/g' {} \;

# ─── Install ─────────────────────────────────────────────────────
echo -e "${YELLOW}Installing to $INSTALL_DIR...${NC}"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -r squashfs-root/usr/* "$INSTALL_DIR"

ICON_PATH=$(find "$INSTALL_DIR" -type f -name "cursor.png" | head -n 1)
cp "$ICON_PATH" "$INSTALL_DIR/cursor.png"

# ─── Create GUI Uninstaller if Zenity is available ─────────────
if command -v zenity &>/dev/null; then
    echo -e "${YELLOW}Zenity found! Adding GUI uninstaller...${NC}"
    cat > "$INSTALL_DIR/uninstall" <<'EOF'
#!/bin/bash

if ! zenity --question \
  --title="Uninstall Cursor" \
  --text="Are you sure you want to uninstall Cursor?\nThis will remove all files and settings." \
  --width=400; then
  exit 1
fi

(
  echo "5"
  echo "# 🔧 Starting uninstallation..."

  sleep 0.5

  # Remove desktop entry
  if rm -f "$HOME/.local/share/applications/cursor.desktop"; then
    echo "30"
    echo "# ✅ Removed desktop entry"
  else
    echo "30"
    echo "# ⚠️ Failed to remove desktop entry"
  fi

  # Remove installation directory
  if rm -rf "$HOME/cursor"; then
    echo "60"
    echo "# ✅ Removed installation directory"
  else
    echo "60"
    echo "# ⚠️ Failed to remove install directory"
  fi

  # Remove PATH entry from .bashrc
  if sed -i '/cursor\/bin/d' "$HOME/.bashrc"; then
    echo "90"
    echo "# ✅ Cleaned up .bashrc"
  else
    echo "90"
    echo "# ⚠️ Failed to update .bashrc"
  fi

  echo "100"
  echo "# 🎉 Uninstallation complete!"
  sleep 1

) | zenity --progress \
  --title="Uninstalling Cursor" \
  --text="Uninstalling..." \
  --percentage=0 \
  --width=500 \
  --height=150 \
  --window-icon="$HOME/cursor/cursor.png" \
  --ok-label="Close"
EOF

    chmod +x "$INSTALL_DIR/uninstall"
else
    echo -e "${YELLOW}Zenity not found. Skipping GUI uninstaller.${NC}"
fi

# ─── Create curcli Command ──────────────────────────────────────
echo -e "${YELLOW}Adding cursor cli...${NC}"

cat > "$INSTALL_DIR/bin/curcli" <<'EOF'
#!/bin/bash

# Colors
GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

function show_help() {
  echo -e "${GREEN}Cursor CLI Tool${NC}"
  echo "Usage: curcli [command]"
  echo ""
  echo "Commands:"
  echo "  help | --help | -h      Show this help message"
  echo "  uninstall               Uninstall Cursor IDE"
  echo "  update                  Update Cursor IDE"
}

function update_cursor() {
  echo -e "${GREEN}🔄 Updating Cursor IDE...${NC}"
  bash <(wget -qO- https://raw.githubusercontent.com/PRASSamin/DocsAndScripts/refs/heads/main/cursor-ide-setup/cursor-setup.sh)
}

function uninstall_cursor() {
  echo -e "${RED}⚠️ Uninstalling Cursor IDE...${NC}"
  "$HOME/cursor/uninstall" 2>/dev/null
}

case "$1" in
  uninstall)
    uninstall_cursor
    ;;
  --help | help | -h)
    show_help
    ;;
  update)
    update_cursor
    ;;
  *)
    if [ "$1" == "" ]; then
      show_help
      exit 0
    fi
    echo -e "${RED}Unknown command: $1${NC}"
    exit 1
    ;;
esac
EOF

chmod +x "$INSTALL_DIR/bin/curcli"

# ─── Desktop Entry ──────────────────────────────────────────────
echo -e "${YELLOW}Creating desktop entry...${NC}"
rm -f "$DESKTOP_FILE"
echo "[Desktop Entry]
Name=Cursor
Comment=The AI Code Editor.
GenericName=Text Editor
Exec=$INSTALL_DIR/bin/cursor
Icon=$INSTALL_DIR/cursor.png
Type=Application
StartupNotify=false
StartupWMClass=Cursor
Categories=TextEditor;Development;IDE;
MimeType=application/x-cursor-workspace;
Actions=new-empty-window;uninstall;
Keywords=cursor;

X-AppImage-Version=$LATEST_VERSION

[Desktop Action new-empty-window]
Name=New Empty Window
Name[de]=Neues leeres Fenster
Name[es]=Nueva ventana vacía
Name[fr]=Nouvelle fenêtre vide
Name[it]=Nuova finestra vuota
Name[ja]=新しい空のウィンドウ
Name[ko]=새 빈 창
Name[ru]=Новое пустое окно
Name[zh_CN]=新建空窗口
Name[zh_TW]=開新空視窗
Exec=$INSTALL_DIR/bin/cursor --new-window
Icon=$INSTALL_DIR/cursor.png

[Desktop Action uninstall]
Name=Uninstall
Exec=$INSTALL_DIR/uninstall
Icon=$INSTALL_DIR/cursor.png" > "$DESKTOP_FILE"

chmod 644 "$DESKTOP_FILE"

# ─── Add to PATH ───────────────────────────────────────────────
if ! grep -q "$INSTALL_DIR/bin" "$BASHRC_FILE"; then
    echo -e "${YELLOW}Adding Cursor bin to PATH...${NC}"
    echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\"" >> "$BASHRC_FILE"
else
    echo -e "${GREEN}🔁 Cursor bin already in PATH.${NC}"
fi

# ─── Clean Up ───────────────────────────────────────────────────
echo -e "${YELLOW}Cleaning up...${NC}"
rm -rf "$TMP_DIR"


# ─── Done! ──────────────────────────────────────────────────────
echo -e "${GREEN}🎉 Cursor IDE v$LATEST_VERSION installed successfully!"
echo -e "${GREEN}✨ Please restart your terminal or run: source ~/.bashrc${NC}"