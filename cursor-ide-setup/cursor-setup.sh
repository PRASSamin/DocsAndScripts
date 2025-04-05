#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

if [ "$(id -u)" -eq 0 ]; then
    echo "Error: Do not run this script as root. Exiting..."
    exit 1
fi

# Define colors for output
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
NC="\e[0m"

# Define variables
CURSOR_VERSION_HISTORY_JSON_URL="https://raw.githubusercontent.com/oslook/cursor-ai-downloads/refs/heads/main/version-history.json"
CURSOR_APPIMAGE_URL="https://downloader.cursor.sh/linux/appImage/x64"
INSTALL_DIR="$HOME/Applications/cursor"
DESKTOP_FILE="$HOME/.local/share/applications/cursor.desktop"
BASHRC_FILE="$HOME/.bashrc"
APPIMAGE_TOOL="/usr/local/bin/appimagetool"

# Function to check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Fetch Version History
if [ ! -f "version-history.json" ]; then
    echo -e "${YELLOW}Fetching version history...${NC}"
    wget "$CURSOR_VERSION_HISTORY_JSON_URL" -O version-history.json
else
    echo -e "${GREEN}Version history already exists, skipping fetch.${NC}"
fi

# Extract latest version from JSON
LATEST_VERSION=$(jq -r '.versions[0].version' version-history.json)

# Detect system architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    DOWNLOAD_URL=$(jq -r ".versions[] | select(.version == \"$LATEST_VERSION\") | .platforms[\"linux-x64\"]" version-history.json)
elif [[ "$ARCH" == "aarch64" ]]; then
    DOWNLOAD_URL=$(jq -r ".versions[] | select(.version == \"$LATEST_VERSION\") | .platforms[\"linux-arm64\"]" version-history.json)
else
    echo -e "${RED}Unsupported architecture: $ARCH. Only x64 and arm64 are supported.${NC}"
    exit 1
fi

# Download the appropriate AppImage based on the architecture
if [ ! -f "cursor.AppImage" ]; then
    echo -e "${YELLOW}Downloading Cursor ${LATEST_VERSION} AppImage...${NC}"
    wget "$DOWNLOAD_URL" -O cursor.AppImage
    chmod +x cursor.AppImage
else
    echo -e "${GREEN}Cursor AppImage already exists, skipping download.${NC}"
fi

# Extract AppImage
if [ ! -d "squashfs-root" ]; then
    echo -e "${YELLOW}Extracting Cursor ${LATEST_VERSION} AppImage...${NC}"
    ./cursor.AppImage --appimage-extract
    rm cursor.AppImage
else
    echo -e "${GREEN}Cursor source already extracted, skipping extraction.${NC}"
fi

# Modify window behavior to remove double titlebar
echo -e "${YELLOW}Modifying window behavior...${NC}"
find squashfs-root/ -type f -name '*.js' \
  -exec grep -l ",minHeight" {} \; \
  -exec sed -i 's/,minHeight/,frame:false,minHeight/g' {} \;

echo -e "${GREEN}Modification complete!${NC}"

# Find highest resolution icon
ICON_PATH=$(find squashfs-root -type f -name "cursor.png" | sort -V | tail -n 1)
echo -e "${YELLOW}Using icon: ${ICON_PATH}${NC}"

# Check and install appimagetool
if [ ! -f "$APPIMAGE_TOOL" ]; then
    echo -e "${YELLOW}Downloading appimagetool...${NC}"
    wget "$APPIMAGE_TOOL_URL" -O appimagetool.AppImage
    chmod +x appimagetool.AppImage
    sudo mv appimagetool.AppImage "$APPIMAGE_TOOL"
else
    echo -e "${GREEN}appimagetool already installed, skipping.${NC}"
fi

# Build new AppImage
echo -e "${YELLOW}Building new Cursor ${LATEST_VERSION} AppImage...${NC}"
ARCH=$(uname -m) appimagetool squashfs-root cursor.AppImage
chmod +x cursor.AppImage
echo -e "${GREEN}Build complete!${NC}"

# Create installation directory
mkdir -p "$INSTALL_DIR"
mv cursor.AppImage "$INSTALL_DIR/"
mv "$ICON_PATH" "$INSTALL_DIR/cursor.png"

echo -e "${YELLOW}Creating desktop entry...${NC}"
# Create desktop entry if not exists
if [ ! -f "$DESKTOP_FILE" ]; then
    echo "[Desktop Entry]
Name=Cursor
Exec=$INSTALL_DIR/cursor.AppImage --no-sandbox %U
Terminal=false
Type=Application
Icon=$INSTALL_DIR/cursor.png
StartupWMClass=Cursor
Comment=Cursor is an AI-first coding environment.
MimeType=x-scheme-handler/cursor;
Categories=Utility;
Actions=Uninstall;" > "$DESKTOP_FILE"
else
    echo -e "${GREEN}Desktop entry already exists, updating...${NC}"
    sed -i "/Exec=/c\Exec=$INSTALL_DIR/cursor.AppImage --no-sandbox %U" "$DESKTOP_FILE"
    sed -i "/Icon=/c\Icon=$INSTALL_DIR/cursor.png" "$DESKTOP_FILE"
fi

# Add uninstall action to desktop entry
echo "[Desktop Action Uninstall]
Name=Uninstall Cursor
Exec=$INSTALL_DIR/uninstall.sh
" >> "$DESKTOP_FILE"

# Update desktop database
update-desktop-database "$HOME/.local/share/applications/"
echo -e "${GREEN}Desktop entry created/updated!${NC}"

# Create uninstall script
echo -e "${YELLOW}Creating uninstall script...${NC}"
cat <<EOL > "$INSTALL_DIR/uninstall.sh"
#!/bin/bash
set -e

echo "Removing Cursor installation..."
rm -rf "$INSTALL_DIR"
rm -f "$DESKTOP_FILE"
update-desktop-database "$HOME/.local/share/applications/"
if grep -q "cursor()" "$BASHRC_FILE"; then
    echo "Removing 'cursor' terminal shortcut from .bashrc..."
    sed -i '/cursor()/,/^}/d' "$BASHRC_FILE"
    echo "Shortcut removed. Please restart your terminal or run 'source $BASHRC_FILE' to apply changes."
fi
echo "Cursor successfully uninstalled!"
EOL
chmod +x "$INSTALL_DIR/uninstall.sh"
echo -e "${GREEN}Uninstall script created!${NC}"

# Add terminal shortcut
if ! grep -q "cursor()" "$BASHRC_FILE"; then
    echo -e "${YELLOW}Adding terminal shortcut...${NC}"
    echo "cursor() {
    setsid $INSTALL_DIR/cursor.AppImage \"\$@\" >/dev/null 2>&1
  }" >> "$BASHRC_FILE"
    source "$BASHRC_FILE"
    echo -e "${GREEN}Terminal shortcut added!${NC}"
else
    echo -e "${GREEN}Terminal shortcut already exists, skipping.${NC}"
fi

# Clean up
rm -rf squashfs-root version-history.json

echo -e "${GREEN}Cursor IDE ${LATEST_VERSION} installation completed! You can run it using 'cursor' command or from the application menu.${NC}"