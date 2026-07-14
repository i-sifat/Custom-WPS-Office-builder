#!/bin/bash
set -euo pipefail

# =============================================================================
# cleaner.sh - Project Folder Cleaner
# =============================================================================
# Cleans the project folder of all build artifacts EXCEPT the original .deb.
# Preserves: wps-office.deb (the original downloaded file)
# Removes:   build/, output/, log files, state files, temp files
# =============================================================================

BUILD_DIR="build"
OUTPUT_DIR="output"
DEB_NAME="wps-office.deb"
LOG_FILE=".cleaner.log"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

log ""
log "=============================================================="
log " cleaner.sh - Project Folder Cleaner"
log "=============================================================="
log ""

# --- SCAN FOR LEFTOVERS ------------------------------------------------------
# Note: `local` is only valid inside a function. These variables live at
# script scope, so `local` here aborted the whole script under `set -u`.
log "Scanning for leftover files and directories..."
log ""

found_anything=false

if [[ -d "$BUILD_DIR" ]]; then
    log "  -> Found extracted package: $BUILD_DIR/"
    found_anything=true
fi

if [[ -d "$OUTPUT_DIR" ]]; then
    log "  -> Found output directory: $OUTPUT_DIR/"
    found_anything=true
fi

log_files=$(find . -maxdepth 1 -name ".*.log" -type f 2>/dev/null || true)
if [[ -n "$log_files" ]]; then
    log "  -> Found log files:"
    echo "$log_files" | sed 's/^/      /' | tee -a "$LOG_FILE"
    found_anything=true
fi

if [[ -f ".build_state" ]]; then
    log "  -> Found state file: .build_state"
    found_anything=true
fi

if [[ -f "$DEB_NAME" ]]; then
    log "  -> Found original .deb: $DEB_NAME ($(ls -lh "$DEB_NAME" | awk '{print $5}'))"
    log "    (This will be preserved)"
else
    log "  -> No original .deb found"
fi

log ""

# --- CLEANUP -----------------------------------------------------------------
if [[ "$found_anything" == false ]]; then
    log "No leftover files or directories found."
    log "Project folder is already clean."
    log ""
    log "Log file: $LOG_FILE"
    log "Done!"
    exit 0
fi

log "Cleaning up..."
log ""

if [[ -d "$BUILD_DIR" ]]; then
    log "  -> Removing $BUILD_DIR/..."
    rm -rf "$BUILD_DIR"
    log "    Removed."
fi

if [[ -d "$OUTPUT_DIR" ]]; then
    log "  -> Removing $OUTPUT_DIR/..."
    rm -rf "$OUTPUT_DIR"
    log "    Removed."
fi

# Remove log files (except our own)
find . -maxdepth 1 -name ".*.log" -type f | while read -r f; do
    if [[ "$(basename "$f")" != "$LOG_FILE" ]]; then
        log "  -> Removing $f..."
        rm -f "$f"
        log "    Removed."
    fi
done

if [[ -f ".build_state" ]]; then
    log "  -> Removing .build_state..."
    rm -f ".build_state"
    log "    Removed."
fi

# Remove any other temporary files
for pattern in "*.tmp" "*.bak" "*.swp"; do
    find . -maxdepth 1 -name "$pattern" -type f -delete 2>/dev/null || true
done

log ""
log "=============================================================="
log " cleaner.sh COMPLETE"
log "=============================================================="
log ""
log "Preserved: $DEB_NAME (original download)"
log "Removed: build artifacts, log files, state files"
log ""
log "Log file: $LOG_FILE"
log "Done!"
