# Usage

Custom WPS Office builder — produces an **English-only, fully offline** `.deb`
with telemetry and online services removed, per `CLEANING_MAP.md`.

## Quick start (one shot)

```bash
chmod +x *.sh
./build.sh              # download -> extract -> clean -> repack
# result: output/wps-office-custom_<version>_amd64.deb
```

Preview what cleaning would delete without touching anything:

```bash
DRY_RUN=1 ./build.sh
```

## Step-by-step (manual control)

```bash
chmod +x download.sh clean.sh cleaner.sh repack.sh

# 1. Download + extract to build/
./download.sh

# 2. Clean build/ (English-only, telemetry/online removed)
./clean.sh              # or: DRY_RUN=1 ./clean.sh to preview

# 3. Repack into output/*.deb
./repack.sh

# 4. Tidy the project when finished (keeps the original wps-office.deb)
./cleaner.sh
```

## `download.sh` modes

```bash
./download.sh              # download + extract (default)
./download.sh --download   # download the .deb only, no extract
./download.sh --extract    # extract an existing wps-office.deb only
./download.sh --help       # show help
```

## Notes

- The upstream download URL lives in **`download.sh`** (`WPS_URL`). WPS CDN
  links rot often — if a download 404s, update it there.
- `clean.sh` never deletes `mui/default`, `mui/en_US`, the English spellcheck
  dictionaries, or the base auth libs (`libauth.so`, `libkqingaccountsdk.so`,
  `libqingipc.so`). Those are required for the app to launch.
- `DEBIAN/postinst` is intentionally left in place — edit it by hand to strip
  update/telemetry hooks while keeping mime/desktop registration.
- Section D ships an advisory blocklist at `/etc/hosts.wps-block`; append it to
  `/etc/hosts` to hard-block WPS online endpoints.
