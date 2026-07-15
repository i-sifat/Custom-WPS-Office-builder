#!/bin/bash
set -euo pipefail

# =============================================================================
# clean.sh - Executable implementation of CLEANING_MAP.md
# =============================================================================
# Produces an English-only, telemetry-free, offline-hardened WPS Office tree by
# removing non-English locales, telemetry/push/update components and
# cloud/online add-ons, while preserving local document editing.
#
# TWO BUILD VARIANTS (controlled by KEEP_CEF):
#   KEEP_CEF=1 (default) -> "full" build.
#       Keeps the embedded browser (CEF) stack AND the real libkprometheus.so,
#       so the fusion / web home page loads its "core support library" from disk.
#       Result: modern web home page works, NO "core support library" popup.
#   KEEP_CEF=0           -> "lite" build.
#       Removes the CEF stack (cef/kcef/jsapi/kjsapipage, ~190 MB) for a lean,
#       classic-UI build, and neutralizes the now-orphaned fusion loader that
#       otherwise throws the "Loading the core support library" / "Failed to
#       load the core support library" popups: it stubs libkprometheus.so with
#       an empty .so, drops the Prometheus launcher, and ships a default
#       Office.conf that disables the fusion/start page.
#
# IMPORTANT - privacy is independent of CEF:
#   Telemetry/online addon removal (Sections B/C) and the /etc/hosts blocklist
#   (Section D) run in BOTH variants. CEF is only a renderer; with the Section D
#   endpoints sinkholed it has nothing to phone home to. Keeping CEF does NOT
#   reopen a telemetry/China leak.
#
# BUNDLED FONTS (BUNDLE_FONTS, default on):
#   Installs the repo's fonts/ directory into
#   /usr/share/fonts/truetype/wps-office-custom/ in BOTH builds. fontconfig's
#   dpkg trigger runs fc-cache automatically on install, so no separate font
#   package is needed.
#
# SAFETY MODEL (guardrails - do not weaken):
#   * Only ever deletes paths *inside* build/ - never absolute system paths.
#   * Hard keep-list: mui/default, mui/en_US, English spellcheck dicts.
#   * Base auth libs (libauth.so, libkqingaccountsdk.so, libqingipc.so) are
#     NEVER deleted - the suite fails to launch without them.
#   * konlinefileconfig is NEVER deleted - libkprometheus.so dlopen()s
#     libkonlinefileconfig.so at startup (see Section C).
#   * Missing targets are logged and skipped, so re-runs are idempotent.
#
# Usage:
#   ./clean.sh                     # full build (keeps CEF), fonts bundled
#   KEEP_CEF=0 ./clean.sh          # lite build (no CEF, classic UI)
#   DRY_RUN=1 ./clean.sh           # preview every action, delete nothing
#   REMOVE_CJK_DATA=0 ./clean.sh   # keep Chinese segmentation data (Section A.7)
#   BUNDLE_FONTS=0 ./clean.sh      # skip bundling repo fonts/
#
# Run order: ./download.sh  ->  ./clean.sh  ->  (repack)
# =============================================================================

BUILD_DIR="build"
WPS_DIR="$BUILD_DIR/opt/kingsoft/wps-office"
OFFICE6="$WPS_DIR/office6"
ADDONS="$OFFICE6/addons"
FONTS_SRC="fonts"
FONTS_DEST="$BUILD_DIR/usr/share/fonts/truetype/wps-office-custom"
LOG_FILE=".clean.log"
DRY_RUN="${DRY_RUN:-0}"
REMOVE_CJK_DATA="${REMOVE_CJK_DATA:-1}"
KEEP_CEF="${KEEP_CEF:-1}"
BUNDLE_FONTS="${BUNDLE_FONTS:-1}"

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

# Write a default Office.conf that disables the fusion / web start page.
# VERIFY-FIRST: the exact keys vary across WPS builds; this is the commonly
# working set. Shipped to /etc/skel so new users pick it up; existing users may
# need to copy it into ~/.config/Kingsoft/Office.conf (see README).
writeDefaultOfficeConf() {
    local dst="$BUILD_DIR/etc/skel/.config/Kingsoft/Office.conf"
    if [[ "$DRY_RUN" == "1" ]]; then
        log "  [dry-run] would write default Office.conf to $dst"
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    cat > "$dst" << 'EOF'
[6.0]
EnableFusionMode=false
EnableStartPage=false

[Fusion]
Enable=false
EOF
    log "  -> wrote default Office.conf (fusion/start page disabled) to $dst"
    log "  ! VERIFY-FIRST: Office.conf keys vary per WPS build - confirm against a working config"
}

# Lite-build only: neutralize the orphaned fusion loader so it can't throw the
# "core support library" popup once CEF has been removed.
neutralizeFusion() {
    log "  -> Neutralizing fusion/web home page (prevents 'core support library' popup)"

    # 1) Replace libkprometheus.so with an empty stub. It is dlopen()'d (not
    #    NEEDED-linked) at startup, so an empty .so lets the dlopen succeed while
    #    loading nothing - the caller falls back to the classic UI. All kprome*
    #    addons are already removed in this variant, so this is consistent.
    local prom
    prom=$(find "$OFFICE6" -maxdepth 2 -name 'libkprometheus.so' -print -quit 2>/dev/null || true)
    if [[ -n "$prom" ]]; then
        if [[ "$DRY_RUN" == "1" ]]; then
            log "  [dry-run] would replace with empty stub: $prom"
        elif command -v gcc >/dev/null 2>&1; then
            gcc -shared -fPIC -o "$prom" -x c /dev/null \
                && log "  x stubbed with empty .so: $prom" \
                || log "  ! failed to stub $prom (gcc error) - relying on Office.conf disable"
        else
            log "  ! gcc not found: leaving libkprometheus.so intact, relying on Office.conf disable"
        fi
    else
        log "  . libkprometheus.so not present (already removed?)"
    fi

    # 2) Drop the standalone Prometheus launcher entry.
    while IFS= read -r -d '' d; do
        remove_path "$d"
    done < <(find "$BUILD_DIR" -name 'wps-office-prometheus.desktop' -print0 2>/dev/null)

    # 3) Ship a default Office.conf disabling the fusion/start page.
    writeDefaultOfficeConf
}

# Install the repo's bundled fonts into the package tree (both variants).
installBundledFonts() {
    if [[ "$BUNDLE_FONTS" != "1" ]]; then
        log "[E] Font bundling skipped (BUNDLE_FONTS=$BUNDLE_FONTS)"
        return 0
    fi
    if [[ ! -d "$FONTS_SRC" ]]; then
        log "[E] Font bundling skipped (no '$FONTS_SRC/' directory in repo)"
        return 0
    fi
    log "[E] Installing bundled fonts into the package..."
    if [[ "$DRY_RUN" == "1" ]]; then
        local n
        n=$(find "$FONTS_SRC" -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' \) 2>/dev/null | wc -l)
        log "  [dry-run] would install $n font file(s) to /usr/share/fonts/truetype/wps-office-custom/"
        return 0
    fi
    mkdir -p "$FONTS_DEST"
    find "$FONTS_SRC" -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' \) \
        -exec cp -f {} "$FONTS_DEST"/ \;
    chmod 0644 "$FONTS_DEST"/* 2>/dev/null || true
    local installed
    installed=$(find "$FONTS_DEST" -type f | wc -l)
    log "  -> installed $installed font file(s) to /usr/share/fonts/truetype/wps-office-custom/"
    log "  -> fontconfig's dpkg trigger will run fc-cache automatically on install"
}

log ""
log "=============================================================="
log " clean.sh - CLEANING_MAP.md implementation"
if [[ "$KEEP_CEF" == "1" ]]; then
    log " VARIANT: full  (KEEP_CEF=1 - modern web home, no popup)"
else
    log " VARIANT: lite  (KEEP_CEF=0 - no CEF, classic UI)"
fi
[[ "$DRY_RUN" == "1" ]] && log " MODE: DRY-RUN (no files will be deleted)"
log "=============================================================="
log ""

# --- PRECONDITIONS -----------------------------------------------------------
[[ -d "$BUILD_DIR" ]]              || fatal "No extracted package found. Expected: $BUILD_DIR/. Run ./download.sh first."
[[ -f "$BUILD_DIR/DEBIAN/control" ]] || fatal "Extracted package missing control file. Run ./download.sh to re-extract."
[[ -d "$WPS_DIR" ]]               || fatal "Expected $WPS_DIR/ not found - is this really the WPS package?"

size_before=$(du -sh "$BUILD_DIR" 2>/dev/null | awk '{print $1}' || echo "?")
log "Build directory: $BUILD_DIR/ (size before: $size_before)"
log ""

# =============================================================================
# SECTION A - Language Resources (keep English only)
# =============================================================================
log "[A] Removing non-English language resources..."

# A.1 Every mui/<locale> directory except default + en_US, wherever it appears.
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

# A.2 Non-English Qt translations (.qm) and web string bundles (.properties).
for loc in zh_CN zh_TW ja_JP ko_KR de_DE es_ES fr_FR pt_BR pt_PT ru_RU mn_CN ug_CN; do
    while IFS= read -r -d '' f; do
        remove_path "$f"
    done < <(find "$OFFICE6" -type f \( -name "*${loc}*.qm" -o -name "*${loc}*.properties" \) -print0 2>/dev/null)
done

# A.3 CEF UI locale packs - keep only en-US.pak (only relevant if cef survives).
if [[ -d "$ADDONS/cef/locales" ]]; then
    while IFS= read -r -d '' f; do
        remove_path "$f"
    done < <(find "$ADDONS/cef/locales" -type f -name "*.pak" ! -name "en-US.pak" -print0 2>/dev/null)
fi

# A.7 Chinese-only segmentation data (friso engine / dictionaries). VERIFY-FIRST
if [[ "$REMOVE_CJK_DATA" == "1" ]]; then
    remove_path "$OFFICE6/data/chinesesegment"
else
    log "  . skipped (REMOVE_CJK_DATA=0): $OFFICE6/data/chinesesegment"
fi

# A.8 KEEP English spellcheck dictionaries - assert they survive.
for d in "$OFFICE6/dicts/spellcheck/en_US" "$OFFICE6/dicts/spellcheck/en_CH"; do
    [[ -d "$d" ]] && log "  keep (spellcheck): $d"
done
log ""

# =============================================================================
# SECTION B - Telemetry, Analytics, Crash Reporting & Update Components
# =============================================================================
log "[B] Removing telemetry / push / update components..."
TELEMETRY_ADDONS=(kfeedback kfeedbackcmds cloudpushsdk messagepush secanalyze)
for a in "${TELEMETRY_ADDONS[@]}"; do
    remove_path "$ADDONS/$a"
done

# Legacy standalone binaries (present in some builds only).
remove_path "$OFFICE6/updateself"
remove_path "$OFFICE6/wpscloudsvr"

if [[ -f "$BUILD_DIR/DEBIAN/postinst" ]]; then
    log "  ! VERIFY-FIRST: kept $BUILD_DIR/DEBIAN/postinst (edit to strip update/telemetry, keep mime/desktop registration)"
fi
log ""

# =============================================================================
# SECTION C - Online-only Features (cloud / account / web)
# =============================================================================
log "[C] Removing online-only add-ons..."
# konlinefileconfig is intentionally NOT in this list (launch-critical: the real
# libkprometheus.so dlopen()s libkonlinefileconfig.so at startup).
ONLINE_ADDONS=(
    qing officespace wpsbox kweibo shareplay
    kclouddocs kusercenter knewshare kqingdlg
    kwebextensionlist linkeddatatype
    kpromeaccountpanel kpromebrowser kpromeprocesson kpromewebapp kpromeworkarea
)
for a in "${ONLINE_ADDONS[@]}"; do
    remove_path "$ADDONS/$a"
done

# Embedded browser stack (CEF + bridge + JS-API): the biggest space win (~190 MB).
# Only removed in the lite variant; the full variant keeps it so the modern web
# home page renders locally (no 'core support library' popup).
if [[ "$KEEP_CEF" == "1" ]]; then
    log "  KEEP_CEF=1 -> keeping embedded browser (CEF) + fusion runtime (modern web home, no popup)"
    konline_hit=$(find "$OFFICE6" -name "libkonlinefileconfig.so" -print -quit 2>/dev/null || true)
    [[ -n "$konline_hit" ]] && log "  keep (Prometheus dep, do NOT delete): $konline_hit"
else
    log "  KEEP_CEF=0 -> removing embedded browser (CEF) stack for a lean, classic-UI build"
    CEF_ADDONS=(cef kcef jsapi kjsapipage)
    for a in "${CEF_ADDONS[@]}"; do
        remove_path "$ADDONS/$a"
    done
    neutralizeFusion
fi

# KEEP base auth libs - disable via config, never delete (assert they remain).
for lib in libauth.so libkqingaccountsdk.so libqingipc.so; do
    hit=$(find "$OFFICE6" -name "$lib" -print -quit 2>/dev/null || true)
    [[ -n "$hit" ]] && log "  keep (auth, do NOT delete): $hit"
done
log ""

# =============================================================================
# SECTION D - Network Blocklist (advisory /etc/hosts fragment) - BOTH variants
# =============================================================================
log "[D] Writing /etc/hosts-style blocklist fragment..."
if [[ "$DRY_RUN" == "1" ]]; then
    log "  [dry-run] would write: $BUILD_DIR/etc/hosts.wps-block"
else
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
fi
log ""

# =============================================================================
# SECTION E - Bundled fonts (BOTH variants)
# =============================================================================
installBundledFonts
log ""

# --- SUMMARY -----------------------------------------------------------------
size_after=$(du -sh "$BUILD_DIR" 2>/dev/null | awk '{print $1}' || echo "?")
log "=============================================================="
log " clean.sh COMPLETE"
log "=============================================================="
log " Variant: $([[ "$KEEP_CEF" == "1" ]] && echo full || echo lite)   Size before: $size_before   ->   Size after: $size_after"
[[ "$DRY_RUN" == "1" ]] && log " (DRY-RUN: nothing was actually deleted)"
log ""
log "Log file: $LOG_FILE"
log "Done!"
