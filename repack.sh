#!/bin/bash
set -euo pipefail

# =============================================================================
# repack.sh - Repack extracted WPS Office package
# =============================================================================
# Checks if build/ directory exists (extracted package)
# Repacks with same version + "+custom" suffix
# =============================================================================

BUILD_DIR="build"
OUTPUT_DIR="output"
LOG_FILE=".repack.log"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

fatal() {
    log "FATAL: $1"
    log "See $LOG_FILE for details."
    exit 1
}

log ""
log "╔══════════════════════════════════════════════════════════════════╗"
log "║  repack.sh - WPS Office Package Repacker                           ║"
log "╚══════════════════════════════════════════════════════════════════╝"
log ""

# --- CHECK DEPENDENCIES ------------------------------------------------------
log "Checking dependencies..."
for cmd in dpkg-deb sed mkdir rm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        fatal "Missing required tool: $cmd\nInstall with: sudo apt-get install -y dpkg-dev coreutils"
    fi
done
log "  → All dependencies satisfied"
log ""

# --- CHECK IF EXTRACTED PACKAGE EXISTS ---------------------------------------
log "Checking for extracted package..."

if [[ ! -d "$BUILD_DIR" ]]; then
    fatal "No extracted package found.\nExpected directory: $BUILD_DIR/\nRun ./download.sh first to download and extract the .deb."
fi

if [[ ! -f "$BUILD_DIR/DEBIAN/control" ]]; then
    fatal "Extracted package missing control file.\nExpected: $BUILD_DIR/DEBIAN/control\nThe extraction may be incomplete or corrupted."
fi

log "  → Found extracted package: $BUILD_DIR/"
log "  → Control file: $BUILD_DIR/DEBIAN/control"
log ""

# --- READ ORIGINAL METADATA --------------------------------------------------
log "Reading original package metadata..."

local orig_version orig_package orig_arch
orig_version=$(grep "^Version:" "$BUILD_DIR/DEBIAN/control" | sed 's/^Version: //')
orig_package=$(grep "^Package:" "$BUILD_DIR/DEBIAN/control" | sed 's/^Package: //')
orig_arch=$(grep "^Architecture:" "$BUILD_DIR/DEBIAN/control" | sed 's/^Architecture: //')

if [[ -z "$orig_version" ]]; then
    fatal "Could not read Version from control file"
fi
if [[ -z "$orig_package" ]]; then
    fatal "Could not read Package name from control file"
fi

log "  → Original package: $orig_package"
log "  → Original version: $orig_version"
log "  → Architecture: ${orig_arch:-unknown}"
log ""

# --- UPDATE METADATA ---------------------------------------------------------
log "Updating package metadata..."

local new_version="${orig_version}+custom"
local new_package="${orig_package}-custom"

log "  → New package name: $new_package"
log "  → New version: $new_version"

# Update control file
sed -i "s/^Package: .*/Package: ${new_package}/" "$BUILD_DIR/DEBIAN/control"
sed -i "s/^Version: .*/Version: ${new_version}/" "$BUILD_DIR/DEBIAN/control"

# Verify updates
if ! grep -q "^Package: ${new_package}$" "$BUILD_DIR/DEBIAN/control"; then
    fatal "Failed to update package name in control file"
fi
if ! grep -q "^Version: ${new_version}$" "$BUILD_DIR/DEBIAN/control"; then
    fatal "Failed to update version in control file"
fi

log "  → Control file updated successfully"
log ""

# --- REPACK ------------------------------------------------------------------
log "╔══════════════════════════════════════════════════════════════════╗"
log "║  Repacking .deb package                                            ║"
log "╚══════════════════════════════════════════════════════════════════╝"

# Clean and create output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

local output_deb="$OUTPUT_DIR/${new_package}_${new_version}_${orig_arch:-amd64}.deb"
log "  → Output file: $output_deb"
log "  → Building..."

if ! dpkg-deb --build "$BUILD_DIR" "$output_deb"; then
    fatal "dpkg-deb build failed"
fi

# Verify output exists
if [[ ! -f "$output_deb" ]]; then
    fatal "Build reported success but output file not found"
fi

local output_size
output_size=$(stat -c%s "$output_deb" 2>/dev/null || stat -f%z "$output_deb" 2>/dev/null)
log "  → Build successful!"
log "  → Size: $(numfmt --to=iec "$output_size" 2>/dev/null || echo "${output_size} bytes")"

# Verify package integrity
log "  → Verifying package integrity..."
if ! dpkg-deb -I "$output_deb" >/dev/null 2>&1; then
    rm -f "$output_deb"
    fatal "Built package failed integrity check"
fi

# Show package info
log "  → Package info:"
dpkg-deb -I "$output_deb" | grep -E "(Package|Version|Architecture|Size|Description)" | sed 's/^/    /'
log ""

log "╔══════════════════════════════════════════════════════════════════╗"
log "║  repack.sh COMPLETE                                                ║"
log "╚══════════════════════════════════════════════════════════════════╝"
log ""
log "Output: $output_deb"
log "Log file: $LOG_FILE"
log "Done!"
