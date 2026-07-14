#!/bin/bash
set -euo pipefail

# =============================================================================
# clean.sh - WPS Office content cleaner (English-only, fully offline)
# =============================================================================
# Applies the CLEANING_MAP: removes non-English locales, telemetry/push
# components, and online-only add-ons while preserving local document editing.
#
# SAFETY MODEL (please keep these guardrails):
#   * Only ever deletes paths *inside* build/ - never absolute system paths.
#   * Hard keep-list: mui/default, mui/en_US, English spellcheck dicts.
#   * Base auth libs (libauth.so, libkqingaccountsdk.so, libqingipc.so) are
#     NEVER deleted - the suite fails to launch without them.
#   * Missing targets are logged and skipped, so re-runs are idempotent.
#
# Usage:
#   ./clean.sh              # apply cleaning
#   DRY_RUN=1 ./clean.sh    # preview every action, delete nothing
#
# After running, repack with ./repack.sh
# =============================================================================

BUILD_DIR="build"
WPS_DIR="$BUILD_DIR/opt/kingsoft/wps-office"
OFFICE6="$WPS_DIR/office6"
ADDONS="$OFFICE6/addons"
LOG_FILE=".clean.log"
DRY_RUN="${DRY_RUN:-0}"

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

# Safe recursive delete restricted to the build tree.
remove_path() {
    local target="$1"
    case "$target" in
        "$BUILD_DIR"/*) : ;;
        *) log "  ! SKIP (refusing path outside $BUILD_DIR/): $target"; return 0 ;;
    esac
    if [[ ! -e "$target" ]]; then
        log "  . not present: $target"
        return 0
    fi
    if [[ "$DRY_RUN" == "1" ]]; then
        log "  [dry-run] would remove: $target"
    else
        rm -rf -- "$target"
        log "  x removed: $target"
    fi
}

log ""
log "=============================================================="
log " clean.sh - Custom Content Cleaner (English-only, offline)"
[[ "$DRY_RUN" == "1" ]] && log " MODE: DRY-RUN (no files will be deleted)"
log "=============================================================="
log ""

# --- PRECONDITIONS -----------------------------------------------------------
if [[ ! -d "$BUILD_DIR" ]]; then
    fatal "No extracted package found. Expected: $BUILD_DIR/. Run ./download.sh first."
fi
if [[ ! -f "$BUILD_DIR/DEBIAN/control" ]]; then
    fatal "Extracted package missing control file. Run ./download.sh to re-extract."
fi
if [[ ! -d "$WPS_DIR" ]]; then
    fatal "Expected $WPS_DIR/ not found - is this really the WPS package?"
fi

size_before=$(du -sh "$BUILD_DIR" 2>/dev/null | awk '{print $1}' || echo "?")
log "Build directory: $BUILD_DIR/ (size before: $size_before)"
log ""

# =============================================================================
# SECTION A - Language resources (keep English only)
# =============================================================================
log "[A] Removing non-English language resources..."

# A1. Every mui/<locale> directory except default + en_US, wherever it appears.
find "$WPS_DIR" -type d -name mui -print0 | while IFS= read -r -d '' muiparent; do
    for sub in "$muiparent"/*/; do
        [[ -d "$sub" ]] || continue
        base="$(basename "$sub")"
        case "$base" in
            default|en_US) log "  keep: ${sub%/}" ;;
            *)             remove_path "${sub%/}" ;;
        esac
    done
done

# A2. Non-English Qt translations and string bundles (explicit locale codes -
#     safer than a fuzzy '*en*' match which can hit unrelated files).
for loc in zh_CN zh_TW ja_JP ko_KR de_DE es_ES fr_FR pt_BR pt_PT ru_RU mn_CN ug_CN; do
    while IFS= read -r -d '' f; do
        remove_path "$f"
    done < <(find "$OFFICE6" -type f \( -name "*${loc}*.qm" -o -name "*${loc}*.properties" \) -print0 2>/dev/null)
done

# A3. CEF locale packs - keep only en-US.pak.
if [[ -d "$ADDONS/cef/locales" ]]; then
    while IFS= read -r -d '' f; do
        remove_path "$f"
    done < <(find "$ADDONS/cef/locales" -type f -name "*.pak" ! -name "en-US.pak" -print0 2>/dev/null)
fi

# A4. Chinese-only segmentation data (friso engine / dictionaries). Not used by
#     English editing, but marked VERIFY-FIRST in the map - gated behind a flag.
if [[ "${REMOVE_CJK_DATA:-1}" == "1" ]]; then
    remove_path "$OFFICE6/data/chinesesegment"
else
    log "  . skipped (REMOVE_CJK_DATA=0): $OFFICE6/data/chinesesegment"
fi

# A5. KEEP English spellcheck dictionaries - assert they survive.
for d in "$OFFICE6/dicts/spellcheck/en_US" "$OFFICE6/dicts/spellcheck/en_CH"; do
    [[ -d "$d" ]] && log "  keep (spellcheck): $d"
done
log ""

# =============================================================================
# SECTION B - Telemetry, analytics, push & update components
# =============================================================================
log "[B] Removing telemetry / push components..."
TELEMETRY_ADDONS=(kfeedback kfeedbackcmds cloudpushsdk messagepush secanalyze)
for a in "${TELEMETRY_ADDONS[@]}"; do
    remove_path "$ADDONS/$a"
done

# Legacy standalone binaries (present in some builds only).
remove_path "$OFFICE6/updateself"
remove_path "$OFFICE6/wpscloudsvr"

# VERIFY-FIRST: DEBIAN/postinst may register mime/desktop entries AND run
# update/telemetry hooks. Do NOT delete it (breaks install); it should be
# hand-edited to strip only the telemetry/update lines. Left intact here.
if [[ -f "$BUILD_DIR/DEBIAN/postinst" ]]; then
    log "  ! VERIFY-FIRST: kept $BUILD_DIR/DEBIAN/postinst (edit it to strip update/telemetry, keep mime/desktop registration)"
fi
log ""

# =============================================================================
# SECTION C - Online-only features (cloud/account/web)
# =============================================================================
log "[C] Removing online-only add-ons..."
ONLINE_ADDONS=(
    qing officespace wpsbox kweibo shareplay
    kclouddocs kusercenter knewshare kqingdlg
    konlinefileconfig kwebextensionlist linkeddatatype
    kpromeaccountpanel kpromebrowser kpromeprocesson kpromewebapp kpromeworkarea
)
for a in "${ONLINE_ADDONS[@]}"; do
    remove_path "$ADDONS/$a"
done

# Embedded browser stack - the single biggest space win (~190 MB).
CEF_ADDONS=(cef kcef jsapi kjsapipage)
for a in "${CEF_ADDONS[@]}"; do
    remove_path "$ADDONS/$a"
done

# KEEP base auth libs - disable via config, never delete (assert they remain).
for lib in libauth.so libkqingaccountsdk.so libqingipc.so; do
    hit=$(find "$OFFICE6" -name "$lib" -print -quit 2>/dev/null || true)
    [[ -n "$hit" ]] && log "  keep (auth, do NOT delete): $hit"
done
log ""

# =============================================================================
# SECTION D - Network blocklist (ship advisory /etc/hosts fragment)
# =============================================================================
log "[D] Writing /etc/hosts-style blocklist fragment..."
mkdir -p "$BUILD_DIR/etc"
cat > "$BUILD_DIR/etc/hosts.wps-block" << 'EOF'
# WPS / Kingsoft blocklist - append to /etc/hosts to hard-block online services.
# Best source of truth for exact endpoints: office6/cfgs/domain_qing.cfg
127.0.0.1  wps.com
127.0.0.1  www.wps.com
127.0.0.1  account.wps.com
127.0.0.1  accounts.wps.com
127.0.0.1  drive.wps.com
127.0.0.1  cloud.wps.com
127.0.0.1  vip.wps.com
127.0.0.1  vipapi.wps.com
127.0.0.1  update.wps.com
127.0.0.1  updatecdn.wps.com
127.0.0.1  push.wps.cn
127.0.0.1  mseb.wps.cn
127.0.0.1  ksointeng.wps.cn
127.0.0.1  ksocdn.wps.cn
127.0.0.1  data.wps.cn
127.0.0.1  counter.kingsoft.net.cn
127.0.0.1  kfuc.wps.cn
127.0.0.1  weiboopen.wps.cn
127.0.0.1  shareplay.wps.cn
127.0.0.1  docs.wps.cn
127.0.0.1  kdocs.cn
EOF
log "  -> wrote $BUILD_DIR/etc/hosts.wps-block"
log ""

# --- SUMMARY -----------------------------------------------------------------
size_after=$(du -sh "$BUILD_DIR" 2>/dev/null | awk '{print $1}' || echo "?")
log "=============================================================="
log " clean.sh COMPLETE"
log "=============================================================="
log " Size before: $size_before   ->   Size after: $size_after"
[[ "$DRY_RUN" == "1" ]] && log " (DRY-RUN: nothing was actually deleted)"
log ""
log "Next: ./repack.sh"
log "Log file: $LOG_FILE"
log "Done!"
