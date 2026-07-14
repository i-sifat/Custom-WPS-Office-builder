#!/bin/bash
set -euo pipefail

# =============================================================================
# download.sh - WPS Office Downloader & Extractor
# =============================================================================
# Usage:
#   ./download.sh              # Download + Extract (default)
#   ./download.sh --download   # Download only
#   ./download.sh --extract    # Extract existing .deb only
# =============================================================================

WPS_URL="https://wdl1.pcfg.cache.wpscdn.com/wpsdl/wpsoffice/download/linux/11733/wps-office_11.1.0.11733.XA_amd64.deb"
DEB_NAME="wps-office.deb"
BUILD_DIR="build"
LOG_FILE=".download.log"
MIN_DEB_SIZE=100000000   # sanity floor (~100 MB); real package is ~300 MB

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

usage() {
    cat << 'EOF'
Usage: ./download.sh [OPTION]

Options:
  (none)       Download and extract the .deb package (default)
  --download   Download the .deb package only
  --extract    Extract the existing .deb package only
  --help       Show this help message

Examples:
  ./download.sh              # Download + extract
  ./download.sh --download   # Download only
  ./download.sh --extract    # Extract existing wps-office.deb
EOF
    exit 0
}

# --- PARSE ARGUMENTS ---------------------------------------------------------
MODE="both"

if [[ $# -gt 0 ]]; then
    case "$1" in
        --download) MODE="download" ;;
        --extract)  MODE="extract" ;;
        --help|-h)  usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
fi

log ""
log "=============================================================="
log " download.sh - WPS Office Downloader & Extractor"
log " Mode: $MODE"
log "=============================================================="
log ""

# --- CHECK DEPENDENCIES ------------------------------------------------------
log "Checking dependencies..."
for cmd in wget dpkg-deb sed mkdir rm; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        fatal "Missing required tool: $cmd. Install with: sudo apt-get install -y wget dpkg-dev coreutils"
    fi
done
log "  -> All dependencies satisfied"
log ""

# --- DOWNLOAD STEP -----------------------------------------------------------
if [[ "$MODE" == "download" || "$MODE" == "both" ]]; then
    log "=============================================================="
    log " STEP: Downloading WPS Office .deb"
    log "=============================================================="

    # Reuse an existing, valid download if present
    if [[ -f "$DEB_NAME" ]]; then
        log "  -> Found existing: $DEB_NAME"
        log "  -> Verifying integrity..."
        if dpkg-deb -I "$DEB_NAME" >/dev/null 2>&1; then
            log "  -> Existing .deb is valid"
            if [[ "$MODE" == "download" ]]; then
                log ""
                log "Download complete. File: $DEB_NAME"
                log "Done!"
                exit 0
            fi
        else
            log "  -> Existing .deb is corrupt, deleting..."
            rm -f "$DEB_NAME"
        fi
    fi

    if [[ ! -f "$DEB_NAME" ]]; then
        log "  -> Downloading from: $WPS_URL"
        if ! wget --continue --show-progress "$WPS_URL" -O "$DEB_NAME" 2>&1 | tee -a "$LOG_FILE"; then
            rm -f "$DEB_NAME"
            fatal "Download failed. Check URL and network connection."
        fi
    fi

    if [[ ! -f "$DEB_NAME" ]]; then
        fatal "Download completed but file not found."
    fi

    # Note: plain `local` is only valid inside a function, so use a normal var here.
    file_size=$(stat -c%s "$DEB_NAME" 2>/dev/null || stat -f%z "$DEB_NAME" 2>/dev/null || echo 0)
    if [[ "$file_size" -lt "$MIN_DEB_SIZE" ]]; then
        rm -f "$DEB_NAME"
        fatal "Downloaded file is too small (${file_size} bytes). Expected ~300MB. Deleted."
    fi

    if ! dpkg-deb -I "$DEB_NAME" >/dev/null 2>&1; then
        rm -f "$DEB_NAME"
        fatal "Downloaded file is not a valid .deb package. Deleted."
    fi

    log "  -> Download verified: $(ls -lh "$DEB_NAME" | awk '{print $5}')"
    log ""

    if [[ "$MODE" == "download" ]]; then
        log "Download complete. File: $DEB_NAME"
        log "Done!"
        exit 0
    fi
fi

# --- EXTRACT STEP ------------------------------------------------------------
if [[ "$MODE" == "extract" || "$MODE" == "both" ]]; then
    log "=============================================================="
    log " STEP: Extracting .deb package"
    log "=============================================================="

    if [[ ! -f "$DEB_NAME" ]]; then
        fatal "No .deb file found: $DEB_NAME. Run with --download first, or place the .deb in this folder."
    fi

    log "  -> Verifying .deb integrity..."
    if ! dpkg-deb -I "$DEB_NAME" >/dev/null 2>&1; then
        fatal "$DEB_NAME is not a valid .deb package."
    fi

    if [[ -d "$BUILD_DIR" ]]; then
        log "  -> Removing previous build directory..."
        rm -rf "$BUILD_DIR"
    fi

    mkdir -p "$BUILD_DIR/DEBIAN"

    log "  -> Extracting data files to $BUILD_DIR/..."
    if ! dpkg-deb -x "$DEB_NAME" "$BUILD_DIR"; then
        rm -rf "$BUILD_DIR"
        fatal "Failed to extract data files from .deb"
    fi

    log "  -> Extracting control metadata to $BUILD_DIR/DEBIAN/..."
    if ! dpkg-deb -e "$DEB_NAME" "$BUILD_DIR/DEBIAN"; then
        rm -rf "$BUILD_DIR"
        fatal "Failed to extract control metadata from .deb"
    fi

    if [[ ! -f "$BUILD_DIR/DEBIAN/control" ]]; then
        rm -rf "$BUILD_DIR"
        fatal "Control file missing after extraction"
    fi

    log "  -> Extraction complete"
    log "  -> Build directory: $BUILD_DIR/"
    log "  -> Control file: $BUILD_DIR/DEBIAN/control"
    log ""
fi

log "=============================================================="
log " download.sh COMPLETE"
log "=============================================================="
log ""
log "Log file: $LOG_FILE"
log "Done!"
