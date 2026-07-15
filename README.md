# Custom WPS Office Builder

> Repackage the official WPS Office for Linux into a **lean, English-only, telemetry-free, offline-hardened** `.deb` &mdash; auto-update and cloud/online phone-home stripped out, local document editing fully intact. Ships **two builds**: one that keeps the modern web home page, one lean classic-UI build.

<p align="left">
  <a href="https://github.com/i-sifat/Custom-WPS-Office-builder/actions/workflows/build.yml"><img alt="Build" src="https://github.com/i-sifat/Custom-WPS-Office-builder/actions/workflows/build.yml/badge.svg"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Linux%20(.deb)-informational">
  <img alt="Arch" src="https://img.shields.io/badge/arch-amd64-blue">
  <img alt="Shell" src="https://img.shields.io/badge/made%20with-Bash-4EAA25?logo=gnubash&logoColor=white">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-green"></a>
</p>

---

## Why this exists

WPS Office is a genuinely good office suite for Linux, but the stock package ships with a lot of things I don't want on my machine: usage telemetry, a background auto-updater, cloud-account panels, and a pile of non-English locale assets.

This is a personal project that automates a clean-room rebuild of the package so I get **just the editors** &mdash; Writer, Spreadsheets, Presentation and PDF &mdash; in English, with the phone-home machinery removed and the online endpoints blocked. Everything is scripted and reproducible, so a fresh build is one command (or one click in CI) away.

## Two builds (install ONE)

Privacy is the same in both: telemetry/cloud add-ons are removed and the `/etc/hosts.wps-block` network blocklist is shipped **regardless of variant**. The only difference is whether the embedded browser (CEF) &mdash; which renders the web home page &mdash; is kept. The editing UI (ribbon/toolbar) is native and looks modern either way.

| Build | CEF / web home page | Size | Notes |
| --- | --- | --- | --- |
| **`wps-office-custom`** | **Kept** | Larger (~+190&nbsp;MB) | Modern web home page works; **no "core support library" popup**. |
| **`wps-office-custom-lite`** | **Removed** | Lean | Classic UI; web home/templates/account panels gone. The orphaned fusion loader is neutralized (empty `libkprometheus.so` stub + `wps-office-prometheus.desktop` dropped + a default `Office.conf` that disables the fusion/start page), so **no popup** either. |

> **Why keeping CEF doesn't leak:** CEF is only a renderer. With the Section D endpoints sinkholed it has nothing to phone home to, so telemetry/China blocking is unaffected by keeping it.

## What it does

```
  download.sh            clean.sh                 (repack)              (release)
 ┌──────────┐   ┌─────────────────┐   ┌────────────┐   ┌─────────┐
 │ fetch    │   │ strip locales  │   │ rebuild   │   │ publish │
 │ + extract│──▶│ telemetry/online│──▶│ both .debs│──▶│ release │
 │ the .deb │   │ + bundle fonts  │   │           │   │         │
 └──────────┘   └─────────────────┘   └────────────┘   └────────┘
```

| Stage | What happens |
| --- | --- |
| **Download** | Fetches the upstream WPS `.deb` and extracts it into `build/` (data tree + `DEBIAN/` control metadata). |
| **Clean** | Removes non-English locales, telemetry/push/update components and cloud/online add-ons; (lite) removes CEF and neutralizes the fusion loader; writes an `/etc/hosts` blocklist; bundles the repo's `fonts/`. Implements [`CLEANING_MAP.md`](CLEANING_MAP.md). |
| **Repack** | Rewrites the package name/version (`custom` / `custom-lite`) and rebuilds valid `.deb`s into `output/`. |
| **Release** | In CI, uploads both artifacts and (on a tag or manual trigger) publishes a GitHub Release. |

## Highlights

- **Two variants from one download** &mdash; `wps-office-custom` (keeps CEF / modern web home) and `wps-office-custom-lite` (no CEF / classic UI), controlled by `KEEP_CEF`.
- **English-only** &mdash; every `mui/<locale>` except `default` and `en_US` is dropped, along with non-English `.qm` / `.properties` / CEF `.pak` assets.
- **No telemetry / no auto-update** &mdash; feedback, cloud-push, message-push and analytics add-ons are removed in **both** builds.
- **Offline by default** &mdash; cloud/account/web add-ons removed; a `/etc/hosts.wps-block` fragment sinkholes known WPS/Kingsoft endpoints in **both** builds.
- **Bundled fonts** &mdash; the repo's `fonts/` are installed into `/usr/share/fonts/truetype/wps-office-custom/` in **both** builds; fontconfig's dpkg trigger refreshes the cache on install (no separate font package needed).
- **Editors preserved** &mdash; Writer, Spreadsheets, Presentation, PDF and English spellcheck dictionaries are never touched.
- **Safe by construction** &mdash; deletions are restricted to `build/`, a hard keep-list protects base auth libraries, and every run is idempotent.
- **Reproducible** &mdash; identical results locally or in GitHub Actions.

## Repository layout

```
.
├─ download.sh            # Download + extract the upstream .deb into build/
├─ clean.sh              # Executable 1:1 implementation of CLEANING_MAP.md (KEEP_CEF/BUNDLE_FONTS aware)
├─ CLEANING_MAP.md       # The spec: what gets removed/kept, and why
├─ fonts/                # TTF/OTF fonts bundled into both builds
├─ manifests/            # Reference listings of the extracted package tree
│  ├─ build-dirs.txt
│  ├─ build-manifest.txt
│  └─ build-sizes.txt
└─ .github/workflows/
   └─ build.yml          # CI: download → clean (x2 variants) → repack → release
```

`CLEANING_MAP.md` is the human-readable source of truth; `clean.sh` is its executable counterpart. Keep the two in sync when either changes.

## Quick start (local)

**Requirements:** a Debian/Ubuntu-based system (or container) with `dpkg-dev`, `binutils`, `wget`, `xz-utils` and `gcc` (gcc is used to build the empty `libkprometheus.so` stub for the lite build).

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends dpkg-dev binutils wget ca-certificates xz-utils gcc

chmod +x download.sh clean.sh

./download.sh                 # 1. download + extract into build/

# 2a. FULL build (keeps CEF, modern web home)
KEEP_CEF=1 ./clean.sh
dpkg-deb --build build output/wps-office-custom.deb

# 2b. LITE build (no CEF, classic UI) — re-extract a fresh tree first
./download.sh --extract
KEEP_CEF=0 ./clean.sh
dpkg-deb --build build output/wps-office-custom-lite.deb
```

> In CI, `build.yml` does all of the above automatically (control-file renaming, cross `Conflicts`/`Replaces`, integrity checks). See it for the exact repack steps.

Preview exactly what the cleaner would delete without removing anything:

```bash
DRY_RUN=1 ./clean.sh
```

Install the result (pick **one** build):

```bash
sudo apt install ./output/wps-office-custom_*_amd64.deb        # modern web home
# or
sudo apt install ./output/wps-office-custom-lite_*_amd64.deb   # lean / classic UI
```

### Useful flags

| Variable / flag | Effect |
| --- | --- |
| `KEEP_CEF=1 ./clean.sh` | Full build: keep the embedded browser + modern web home (default). |
| `KEEP_CEF=0 ./clean.sh` | Lite build: remove CEF, neutralize the fusion loader, ship classic UI. |
| `BUNDLE_FONTS=0 ./clean.sh` | Skip installing the repo's `fonts/` into the package. |
| `DRY_RUN=1 ./clean.sh` | Log every action, delete nothing. |
| `REMOVE_CJK_DATA=0 ./clean.sh` | Keep the Chinese word-segmentation data (removed by default). |
| `./download.sh --download` | Download the `.deb` only, skip extraction. |
| `./download.sh --extract` | Extract an already-downloaded `wps-office.deb`. |

> **Lite build &amp; the web-home toggle (verify-first):** the exact `Office.conf` keys that disable the fusion/start page vary across WPS releases. `clean.sh` ships a commonly-working default to `/etc/skel`; if a popup ever survives on an existing user profile, copy it into `~/.config/Kingsoft/Office.conf`. The `libkprometheus.so` stub + dropped launcher already prevent the popup regardless.

## Uninstall

To completely remove the (custom or stock) WPS Office install and every trace it leaves behind, run the steps below. Copy-paste the whole block — it is safe to run even if some paths don't exist.

```bash
# 1. Find the exact installed package name (custom build or upstream)
dpkg -l | grep -i wps

# 2. Purge the package AND its system config (covers all possible names)
sudo apt-get purge -y wps-office wps-office-custom wps-office-custom-lite 2>/dev/null \
  || sudo dpkg --purge wps-office wps-office-custom wps-office-custom-lite

# 3. Remove per-user config, state and cache (run as YOUR user, no sudo)
rm -rf ~/.config/Kingsoft ~/.local/share/Kingsoft \
       ~/.cache/Kingsoft  ~/.kingsoft \
       ~/.local/share/applications/wps-office-*.desktop

# 4. Remove any files this build placed under /opt or /etc
sudo rm -rf /opt/kingsoft/wps-office
sudo rm -f  /etc/hosts.wps-block

# 5. Drop dependencies that were pulled in only for WPS
sudo apt-get autoremove -y

# 6. Refresh the desktop/MIME databases so launchers disappear
sudo update-desktop-database 2>/dev/null || true
```

> **If you appended the Section D blocklist directly into `/etc/hosts`** (instead of using the standalone `/etc/hosts.wps-block` fragment), remove those lines too. **Review the match before deleting:**
>
> ```bash
> sudo cp /etc/hosts /etc/hosts.bak                 # backup first
> grep -nE 'wps\.(com|cn)|wpscdn\.cn|kdocs\.cn' /etc/hosts   # preview what will go
> sudo sed -i -E '/wps\.(com|cn)|wpscdn\.cn|kdocs\.cn/d' /etc/hosts
> ```

One-liner (package + user data only, no hosts cleanup):

```bash
sudo apt-get purge -y wps-office wps-office-custom wps-office-custom-lite; rm -rf ~/.config/Kingsoft ~/.cache/Kingsoft ~/.local/share/Kingsoft; sudo apt-get autoremove -y
```

## Build in CI

The [`build.yml`](.github/workflows/build.yml) workflow runs the whole pipeline on `ubuntu-latest`, producing **both** `.deb`s from a single upstream download:

- **Manual run** &mdash; *Actions → Build WPS Office (Custom) → Run workflow*. Toggle `release` to publish a GitHub Release with both `.deb`s.
- **Tag push** &mdash; pushing a tag like `v1.0.0` builds **and** releases under that tag automatically.

Every run also uploads both `.deb`s as downloadable build artifacts, even when no release is cut.

## What gets removed vs. kept

<table>
<tr><th>Removed</th><th>Kept</th></tr>
<tr>
<td>

- Non-English locales (`zh_CN`, `zh_TW`, `ja_JP`, &hellip;)
- Telemetry / feedback / analytics add-ons
- Cloud-push &amp; message-push SDKs
- Cloud / account / sharing add-ons
- Embedded Chromium (CEF) browser stack &mdash; **lite build only**

</td>
<td>

- Writer, Spreadsheets, Presentation, PDF
- `mui/default` &amp; `mui/en_US` UI
- English spellcheck dictionaries
- Base auth libraries (required to launch)
- Local templates &amp; blank documents
- Bundled `fonts/` (both builds)
- Embedded browser / modern web home &mdash; **full build only**

</td>
</tr>
</table>

See [`CLEANING_MAP.md`](CLEANING_MAP.md) for the exhaustive, path-by-path breakdown with safety notes.

## Reference manifests

The [`manifests/`](manifests/) folder captures the directory tree, file manifest and per-file sizes of an extracted package, so the cleaning logic can be audited against the real layout. They were generated from **`wps-office_11.1.0.11698.XA_amd64.deb`**. See [`manifests/README.md`](manifests/README.md) for details.

> **Note:** `download.sh` currently targets build **`11.1.0.11733.XA`**. The layout is stable across these point releases, so the map applies to both; regenerate the manifests if you want an exact match.

## Disclaimer

This is an independent, personal project and is **not affiliated with, endorsed by, or supported by Kingsoft / WPS**. WPS Office is the property of its respective owners; this repository ships **no** WPS binaries &mdash; it only downloads the official package at build time and repackages it locally for personal use. Review WPS Office's own license and terms before redistributing any build. Use at your own risk.

## License

The **scripts and tooling in this repository** are released under the [MIT License](LICENSE). This license covers only the build tooling here &mdash; **not** WPS Office itself.
