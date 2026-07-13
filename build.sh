#!/bin/bash
set -e

# --- CONFIG ---
WPS_URL="https://wdl1.pcfg.cache.wpscdn.com/wpscdn/w/download/linux/11723/wps-office_11.1.0.11723.XA_amd64.deb"
# ^ Update this URL to the latest version from WPS official site
DEB_NAME="wps-office.deb"
BUILD_DIR="build"
OUTPUT_DIR="output"

# --- CLEANUP ---
rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR/DEBIAN" "$OUTPUT_DIR"

# --- DOWNLOAD ---
echo "[*] Downloading WPS Office..."
wget -q --show-progress "$WPS_URL" -O "$DEB_NAME"

# --- EXTRACT ---
echo "[*] Extracting .deb..."
dpkg-deb -x "$DEB_NAME" "$BUILD_DIR"
dpkg-deb -e "$DEB_NAME" "$BUILD_DIR/DEBIAN"

# --- REMOVE NON-ENGLISH LANGUAGES ---
echo "[*] Removing non-English language files..."
find "$BUILD_DIR" -type d -name "i18n" -exec rm -rf {} + 2>/dev/null || true
find "$BUILD_DIR" -path "*/mui/*" ! -path "*/mui/en_US/*" ! -path "*/mui/en-US/*" -type d -exec rm -rf {} + 2>/dev/null || true
find "$BUILD_DIR" -path "*/locales/*" ! -name "*en*" -type f -delete 2>/dev/null || true
find "$BUILD_DIR" -name "*.qm" ! -name "*en*" -delete 2>/dev/null || true

# --- REMOVE TELEMETRY / UPDATE CHECKS ---
echo "[*] Removing telemetry..."
# Remove update checker binary if it exists
rm -f "$BUILD_DIR/opt/kingsoft/wps-office/office6/updateself" 2>/dev/null || true
rm -f "$BUILD_DIR/opt/kingsoft/wps-office/office6/wpscloudsvr" 2>/dev/null || true
# Block telemetry domains via hosts (optional, applied at install)
mkdir -p "$BUILD_DIR/etc"
cat >> "$BUILD_DIR/etc/hosts.wps-block" << 'EOF'
# WPS Telemetry Blocklist
127.0.0.1  wps.com
127.0.0.1  www.wps.com
127.0.0.1  account.wps.com
127.0.0.1  drive.wps.com
127.0.0.1  cloud.wps.com
127.0.0.1  vip.wps.com
127.0.0.1  ksops.wps.com
EOF

# --- UPDATE PACKAGE METADATA ---
sed -i 's/Package: wps-office/Package: wps-office-custom/' "$BUILD_DIR/DEBIAN/control"
sed -i 's/Version: /Version: custom-/' "$BUILD_DIR/DEBIAN/control"
echo "Custom build: English-only, telemetry removed" >> "$BUILD_DIR/DEBIAN/control"

# --- REPACK ---
echo "[*] Repacking .deb..."
dpkg-deb --build "$BUILD_DIR" "$OUTPUT_DIR/wps-office-custom_amd64.deb"

echo "[✓] Done: $OUTPUT_DIR/wps-office-custom_amd64.deb"
ls -lh "$OUTPUT_DIR/"
