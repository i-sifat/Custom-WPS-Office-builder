#!/bin/bash
set -euo pipefail

# =============================================================================
# clean.sh - Custom Content Cleaner
# =============================================================================
# This script is for removing unwanted files from the extracted package.
# The user will fill this in manually.
#
# The extracted package is in the build/ directory.
# After making changes, run ./repack.sh to create the final .deb.
#
# Examples of what you might want to remove:
#   - Non-English language files (i18n, locales, .qm files)
#   - Telemetry binaries (updateself, wpscloudsvr, etc.)
#   - Unwanted desktop entries
#   - Update checkers
#
# IMPORTANT: Do NOT delete the build/DEBIAN/ directory or its contents.
#            The control file in build/DEBIAN/control is needed for repacking.
# =============================================================================

BUILD_DIR="build"
LOG_FILE=".clean.log"

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
log "║  clean.sh - Custom Content Cleaner                                 ║"
log "╚══════════════════════════════════════════════════════════════════╝"
log ""

# Check if build directory exists
if [[ ! -d "$BUILD_DIR" ]]; then
    fatal "No extracted package found.\nExpected: $BUILD_DIR/\nRun ./download.sh first."
fi

if [[ ! -f "$BUILD_DIR/DEBIAN/control" ]]; then
    fatal "Extracted package missing control file.\nRun ./download.sh to re-extract."
fi

log "Build directory: $BUILD_DIR/"
log ""
log "╔══════════════════════════════════════════════════════════════════╗"
log "║  TODO: Add your custom cleaning logic below                       ║"
log "╚══════════════════════════════════════════════════════════════════╝"
log ""
log "Examples of commands you might add:"
log ""
log "  # Remove non-English locale directories"
log "  find build/ -type d -name 'i18n' -exec rm -rf {} + 2>/dev/null || true"
log ""
log "  # Remove specific locale folders (keep English)"
log "  find build/usr/share/locale -mindepth 1 -maxdepth 1 -type d ! -name 'en*' -exec rm -rf {} + 2>/dev/null || true"
log ""
log "  # Remove telemetry binaries"
log "  rm -f build/opt/kingsoft/wps-office/office6/updateself 2>/dev/null || true"
log "  rm -f build/opt/kingsoft/wps-office/office6/wpscloudsvr 2>/dev/null || true"
log ""
log "  # Remove .qm translation files (non-English)"
log "  find build/ -name '*.qm' -type f | while read f; do"
log "      [[ \$(basename \$f) =~ en ]] || rm -f \"\$f\""
log "  done"
log ""
log "After editing this file, run it with:"
log "  ./clean.sh"
log ""
log "Then repack with:"
log "  ./repack.sh"
log ""
log "Log file: $LOG_FILE"
log "Done! (no changes made - edit this script to add cleaning logic)"
