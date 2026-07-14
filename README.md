# Custom WPS Office Builder

> Repackage the official WPS Office for Linux into a **lean, English-only, fully offline** `.deb` &mdash; telemetry, auto-update and cloud/online components stripped out, local document editing fully intact.

<p align="left">
  <a href="https://github.com/i-sifat/Custom-WPS-Office-builder/actions/workflows/build.yml"><img alt="Build" src="https://github.com/i-sifat/Custom-WPS-Office-builder/actions/workflows/build.yml/badge.svg"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-Linux%20(.deb)-informational">
  <img alt="Arch" src="https://img.shields.io/badge/arch-amd64-blue">
  <img alt="Shell" src="https://img.shields.io/badge/made%20with-Bash-4EAA25?logo=gnubash&logoColor=white">
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-green"></a>
</p>

---

## Why this exists

WPS Office is a genuinely good office suite for Linux, but the stock package ships with a lot of things I don't want on my machine: usage telemetry, a background auto-updater, cloud-account panels, an embedded Chromium browser (~190&nbsp;MB), and a pile of non-English locale assets.

This is a personal project that automates a clean-room rebuild of the package so I get **just the editors** &mdash; Writer, Spreadsheets, Presentation and PDF &mdash; in English, with the phone-home machinery removed and the online endpoints blocked. Everything is scripted and reproducible, so a fresh build is one command (or one click in CI) away.

## What it does

```
  download.sh            clean.sh                 (repack)              (release)
 ┌──────────┐   ┌─────────────────┐   ┌────────────┐   ┌─────────┐
 │ fetch    │   │ strip locales  │   │ rebuild   │   │ publish │
 │ + extract│──▶│ telemetry/online│──▶│ the .deb  │──▶│ release │
 │ the .deb │   │ write blocklist │   │           │   │         │
 └──────────┘   └─────────────────┘   └────────────┘   └────────┘
```

| Stage | What happens |
| --- | --- |
| **Download** | Fetches the upstream WPS `.deb` and extracts it into `build/` (data tree + `DEBIAN/` control metadata). |
| **Clean** | Removes non-English locales, telemetry/push/update components and cloud/online add-ons; writes an `/etc/hosts` blocklist. Implements [`CLEANING_MAP.md`](CLEANING_MAP.md). |
| **Repack** | Rewrites the package name/version with a `-custom` / `+custom` suffix and rebuilds a valid `.deb` into `output/`. |
| **Release** | In CI, uploads the artifact and (on a tag or manual trigger) publishes a GitHub Release. |

## Highlights

- **English-only** &mdash; every `mui/<locale>` except `default` and `en_US` is dropped, along with non-English `.qm` / `.properties` / CEF `.pak` assets.
- **No telemetry / no auto-update** &mdash; feedback, cloud-push, message-push and analytics add-ons are removed.
- **Offline by default** &mdash; cloud/account/web add-ons and the embedded Chromium (CEF) stack are removed; a `/etc/hosts.wps-block` fragment sinkholes known WPS/Kingsoft endpoints.
- **Editors preserved** &mdash; Writer, Spreadsheets, Presentation, PDF and English spellcheck dictionaries are never touched.
- **Safe by construction** &mdash; deletions are restricted to `build/`, a hard keep-list protects base auth libraries, and every run is idempotent.
- **Reproducible** &mdash; identical results locally or in GitHub Actions.

## Repository layout

```
.
├─ download.sh            # Download + extract the upstream .deb into build/
├─ clean.sh              # Executable 1:1 implementation of CLEANING_MAP.md
├─ CLEANING_MAP.md       # The spec: what gets removed/kept, and why
├─ manifests/            # Reference listings of the extracted package tree
│  ├─ build-dirs.txt
│  ├─ build-manifest.txt
│  └─ build-sizes.txt
└─ .github/workflows/
   └─ build.yml          # CI: download → clean → repack → release
```

`CLEANING_MAP.md` is the human-readable source of truth; `clean.sh` is its executable counterpart. Keep the two in sync when either changes.

## Quick start (local)

**Requirements:** a Debian/Ubuntu-based system (or container) with `dpkg-dev`, `binutils`, `wget` and `xz-utils`.

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends dpkg-dev binutils wget ca-certificates xz-utils

chmod +x download.sh clean.sh

./download.sh          # 1. download + extract into build/
./clean.sh             # 2. strip to English-only / offline

# 3. repack (see build.yml for the exact steps, or run dpkg-deb --build build output/)
```

Preview exactly what the cleaner would delete without removing anything:

```bash
DRY_RUN=1 ./clean.sh
```

Install the result:

```bash
sudo apt install ./output/wps-office-custom_*_amd64.deb
```

### Useful flags

| Variable / flag | Effect |
| --- | --- |
| `DRY_RUN=1 ./clean.sh` | Log every action, delete nothing. |
| `REMOVE_CJK_DATA=0 ./clean.sh` | Keep the Chinese word-segmentation data (removed by default). |
| `./download.sh --download` | Download the `.deb` only, skip extraction. |
| `./download.sh --extract` | Extract an already-downloaded `wps-office.deb`. |

## Build in CI

The [`build.yml`](.github/workflows/build.yml) workflow runs the whole pipeline on `ubuntu-latest`:

- **Manual run** &mdash; *Actions → Build WPS Office (Custom) → Run workflow*. Toggle `release` to publish a GitHub Release with the built `.deb`.
- **Tag push** &mdash; pushing a tag like `v1.0.0` builds **and** releases under that tag automatically.

Every run also uploads the `.deb` as a downloadable build artifact, even when no release is cut.

## What gets removed vs. kept

<table>
<tr><th>Removed</th><th>Kept</th></tr>
<tr>
<td>

- Non-English locales (`zh_CN`, `zh_TW`, `ja_JP`, &hellip;)
- Telemetry / feedback / analytics add-ons
- Cloud-push &amp; message-push SDKs
- Cloud / account / sharing add-ons
- Embedded Chromium (CEF) browser stack

</td>
<td>

- Writer, Spreadsheets, Presentation, PDF
- `mui/default` &amp; `mui/en_US` UI
- English spellcheck dictionaries
- Base auth libraries (required to launch)
- Local templates &amp; blank documents

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
