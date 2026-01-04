#!/bin/bash
# --- CONFIGURATION ---
DOWNLOAD_URL="https://github.com/bitgamergws1/App-checker/releases/download/SBI-TV-DOWNLOADS_MAC-OS/SBI-TV-macOS.zip"
TEMP_DIR=$(mktemp -d)
INSTALL_DIR="$HOME/Applications"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting SBI TV Installer...${NC}\n"

# Seedha download pe jao, validation ki zaroorat nahi

# 2. Download with progress
echo "📥 Downloading App..."
if ! curl -L --progress-bar -o "$TEMP_DIR/app.zip" "$DOWNLOAD_URL"; then
    echo -e "${RED}❌ Download failed. Link check karo.${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# ... baaki script same rahega

# 3. Verify ZIP
if ! unzip -tq "$TEMP_DIR/app.zip" &> /dev/null; then
    echo -e "${RED}❌ File corrupt hai. Dobara download karo.${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 4. Unzip
echo "📦 Unzipping..."
unzip -q -o "$TEMP_DIR/app.zip" -d "$TEMP_DIR/extracted"

# 5. Find .app (with better error message)
APP_PATH=$(find "$TEMP_DIR/extracted" -name "*.app" -type d | head -n 1)
APP_NAME=$(basename "$APP_PATH")

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Zip file mein koi .app nahi mili!${NC}"
    echo -e "${YELLOW}💡 Zip file ke contents:${NC}"
    ls -la "$TEMP_DIR/extracted"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo -e "✅ Found: ${GREEN}$APP_NAME${NC}"

# 6. Remove old version
if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
    echo "🗑️  Removing old version..."
    rm -rf "$INSTALL_DIR/$APP_NAME"
fi

# 7. Install
echo "📂 Installing..."
mkdir -p "$INSTALL_DIR"
mv "$APP_PATH" "$INSTALL_DIR/"
FINAL_PATH="$INSTALL_DIR/$APP_NAME"

# 8. 🔥 THE MAGIC FIX (Improved)
echo "🔧 Fixing macOS Security..."
xattr -cr "$FINAL_PATH" 2>/dev/null
codesign --force --deep --sign - "$FINAL_PATH" &>/dev/null

# M1/M2 specific fix (agar ARM architecture hai)
if [[ $(uname -m) == "arm64" ]]; then
    echo "🍎 Detected Apple Silicon - applying additional fixes..."
    # Rosetta 2 check (agar x86 app hai)
    if file "$FINAL_PATH/Contents/MacOS/"* | grep -q "x86_64"; then
        if ! /usr/bin/pgrep oahd &>/dev/null; then
            echo -e "${YELLOW}⚠️  Warning: Rosetta 2 zaroori hai. Install karne ke liye:${NC}"
            echo "   softwareupdate --install-rosetta --agree-to-license"
        fi
    fi
fi

# 9. Cleanup
rm -rf "$TEMP_DIR"

# 10. Success
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Installation Complete!${NC}"
echo -e "${GREEN}📍 Location: $INSTALL_DIR/$APP_NAME${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 11. Optional: Open app
read -p "Kya app abhi open karni hai? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "🚀 Opening..."
    open "$FINAL_PATH"

fi

