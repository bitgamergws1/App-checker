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

# 1. Download
echo "📥 Downloading App..."
if ! curl -L --progress-bar -o "$TEMP_DIR/app.zip" "$DOWNLOAD_URL"; then
    echo -e "${RED}❌ Download failed. Link check karo.${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 2. Verify ZIP
if ! unzip -tq "$TEMP_DIR/app.zip" &> /dev/null; then
    echo -e "${RED}❌ File corrupt hai. Dobara download karo.${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 3. Unzip Layer 1
echo "📦 Unzipping Layer 1..."
unzip -q -o "$TEMP_DIR/app.zip" -d "$TEMP_DIR/extracted"

# 🔥 4. DOUBLE UNZIP LOGIC (The Fix)
# Check agar andar ek aur zip file hai
NESTED_ZIP=$(find "$TEMP_DIR/extracted" -name "*.zip" | head -n 1)

if [ ! -z "$NESTED_ZIP" ]; then
    echo -e "${YELLOW}📦 Found nested ZIP: $(basename "$NESTED_ZIP")${NC}"
    echo "📦 Unzipping Layer 2..."
    unzip -q -o "$NESTED_ZIP" -d "$TEMP_DIR/extracted"
fi

# 5. Find .app (Recursively search ab)
APP_PATH=$(find "$TEMP_DIR/extracted" -name "*.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Zip file mein koi .app nahi mili!${NC}"
    echo -e "${YELLOW}💡 Contents:${NC}"
    ls -la "$TEMP_DIR/extracted"
    rm -rf "$TEMP_DIR"
    exit 1
fi

APP_NAME=$(basename "$APP_PATH")
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

# 8. Fix Permissions (Crucial for Mac)
echo "🔧 Fixing macOS Security..."
xattr -cr "$FINAL_PATH" 2>/dev/null
codesign --force --deep --sign - "$FINAL_PATH" &>/dev/null

# M1/M2 Fix
if [[ $(uname -m) == "arm64" ]]; then
    if file "$FINAL_PATH/Contents/MacOS/"* | grep -q "x86_64"; then
        if ! /usr/bin/pgrep oahd &>/dev/null; then
            echo -e "${YELLOW}⚠️  Note: Rosetta 2 might be required.${NC}"
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

# 11. Open App
read -p "Kya app abhi open karni hai? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "🚀 Opening..."
    open "$FINAL_PATH"
fi