# Build Manifests

Reference listings extracted from an **already-unpacked** WPS Office `.deb`.
These files are documentation/data only — nothing in the build pipeline reads
them at runtime. They exist so `CLEANING_MAP.md` and `clean.sh` can be
cross-checked against the real package tree.

## Source package

| Field | Value |
| --- | --- |
| Package | `wps-office_11.1.0.11698.XA_amd64.deb` |
| Version | `11.1.0.11698.XA` |
| Architecture | `amd64` |
| Install root | `/opt/kingsoft/wps-office/` |
| Extracted with | `dpkg-deb -x` (data tree) + `dpkg-deb -e` (control metadata) |

The listings were produced by extracting the `.deb` into `build/` and walking
the resulting tree.

## Files

| File | What it is | Location |
| --- | --- | --- |
| `build-dirs.txt` | Every directory in the extracted tree (`find build -type d`). | `manifests/build-dirs.txt` |
| `build-manifest.txt` | Full file-by-file manifest of the extracted package (~287 KB). | repo root (pending move) |
| `build-sizes.txt` | Per-file sizes for the extracted package (~291 KB). | repo root (pending move) |

> `build-manifest.txt` and `build-sizes.txt` are large binaries-of-text and
> are still at the repo root. To finish grouping them here, run:
>
> ```bash
> git mv build-manifest.txt build-sizes.txt manifests/
> git commit -m "Move remaining manifests into manifests/"
> ```

## Note on version

These reference listings are from **11.1.0.11698.XA**. The active download in
`download.sh` currently targets **11.1.0.11733.XA**. The directory layout is
stable across these point releases, so the map/cleaning logic still applies —
but if you want the manifests to match the downloaded build exactly, regenerate
them from the 11733 package.
