#!/bin/bash
set -euo pipefail

# =============================================================================
# build.sh - One-shot orchestrator for the custom WPS Office build
# =============================================================================
# Chains the single-purpose helper scripts in order:
#   1. download.sh  -> download + extract the .deb into build/
#   2. clean.sh     -> strip non-English/telemetry/online per CLEANING_MAP
#   3. repack.sh    -> rebuild output/<pkg>_<ver>_<arch>.deb
#
# The download URL now lives in ONE place (download.sh) instead of being
# duplicated here, so there is no second copy to drift out of date.
#
# Usage:
#   ./build.sh              # full pipeline
#   DRY_RUN=1 ./build.sh    # clean.sh previews deletions (still downloads/repacks)
# =============================================================================

# Always run from the repo root, regardless of where the script is invoked.
cd "$(dirname "$0")"

LOG_FILE=".build.log"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

fatal() {
    log "FATAL: $1"
    exit 1
}

log ""
log "=============================================================="
log " build.sh - Custom WPS Office builder (English-only, offline)"
log "=============================================================="
log ""

# Make sure the helper scripts exist and are executable.
for s in download.sh clean.sh repack.sh; do
    [[ -f "$s" ]] || fatal "Missing required helper script: $s"
done
chmod +x download.sh clean.sh repack.sh cleaner.sh 2>/dev/null || true

log "Step 1/3: download + extract  (./download.sh)"
./download.sh
log ""

log "Step 2/3: clean               (./clean.sh)"
./clean.sh
log ""

log "Step 3/3: repack              (./repack.sh)"
./repack.sh
log ""

log "=============================================================="
log " build.sh COMPLETE"
log "=============================================================="
if compgen -G "output/*.deb" > /dev/null; then
    log "Artifact(s):"
    ls -lh output/*.deb | sed 's/^/  /' | tee -a "$LOG_FILE"
else
    fatal "No .deb produced in output/ - check .download.log / .clean.log / .repack.log"
fi
log "Done!"
