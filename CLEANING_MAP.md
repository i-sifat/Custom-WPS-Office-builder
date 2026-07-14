**Package:** WPS Office for Linux (`.deb`), extracted under `build/`
**Install root:** `/opt/kingsoft/wps-office/` (Debian/Ubuntu layout assumed)
**Goal:** English-only, fully offline install — telemetry, auto-update, and online-only services removed or disabled — while preserving local document editing (WPS Writer / Spreadsheets / Presentation / PDF).
**Source repo:** `i-sifat/Custom-WPS-Office-builder`
> **Scope / confidence note.** This map is built from `build-manifest.txt`, `build-dirs.txt`, and `build-sizes.txt`. The manifest (~287 KB) is large and only partially visible in the shared attachments, so the file-by-file lists below are **exhaustive for every path I could confirm** and **pattern-complete** for the rest (e.g. "every `mui/zh_CN/*.qm` under `office6/addons/`"). Items I could not individually confirm are marked **Verify first**. The repo already contains `clean.sh` and `cleaner.sh`; this map should be cross-checked against them (happy to review those next).  
> **Golden rule applied throughout:** never delete `mui/default/` or `mui/en_US/` — those carry the English/base UI. WPS falls back to embedded English when a non-English `.qm` is missing, so removing `zh_CN` / `zh_TW` / `ja_JP` translations is non-destructive to English users.
* * *
## Section A — Language Resources
Removing non-English locale assets keeps English fully functional. Three asset classes are involved: Qt translations (`.qm`), web/i18n string bundles (`.properties`), and CEF UI locale packs (`.pak`).
### A.1 Qt translation files (`.qm`) — non-English
Pattern: `office6/addons/<addon>/mui/{zh_CN,zh_TW,ja_JP}/<addon>.qm`. Confirmed instances:

| Full path (under build/) | Lang | Type | Est. size | Safety |
| ---| ---| ---| ---| --- |
| opt/…/addons/docpermission/mui/zh\_CN/docpermission.qm | zh\_CN | file | 78K | Safe to delete |
| opt/…/addons/kappcenter/mui/zh\_CN/kappcenter.qm | zh\_CN | file | 24K | Safe to delete |
| opt/…/addons/kautofindcontents/mui/zh\_CN/kautofindcontents.qm | zh\_CN | file | 557B | Safe to delete |
| opt/…/addons/kbarcode/mui/ja\_JP/kbarcode.qm | ja\_JP | file | 252B | Safe to delete |
| opt/…/addons/kbarcode/mui/zh\_CN/kbarcode.qm | zh\_CN | file | 234B | Safe to delete |
| opt/…/addons/kbarcode/mui/zh\_TW/kbarcode.qm | zh\_TW | file | 228B | Safe to delete |
| opt/…/addons/kclouddocs/mui/zh\_CN/kclouddocs.qm | zh\_CN | file | 496B | Safe to delete |
| opt/…/addons/kclouddocs/mui/zh\_TW/kclouddocs.qm | zh\_TW | file | 248B | Safe to delete |
| opt/…/addons/kcloudfiledialog/mui/zh\_CN/kcloudfiledialog.qm | zh\_CN | file | 12K | Safe to delete |
| opt/…/addons/kfeedback/mui/zh\_CN/kfeedback.qm | zh\_CN | file | 1.7K | Safe to delete |
| opt/…/addons/khelp/mui/zh\_CN/khelp.qm | zh\_CN | file | 3.9K | Safe to delete |
| opt/…/addons/kjsapipage/mui/zh\_CN/kjsapipage.qm | zh\_CN | file | 93B | Safe to delete |
| opt/…/addons/knewdocs/mui/zh\_CN/knewdocs.qm | zh\_CN | file | 5.3K | Safe to delete |

**Directory-level removal (all non-English** **`mui`** **locale dirs).** The dir listing shows the same three locale codes repeated across most addons. Safe to delete every one of these directories wholesale:
*   `mui/zh_CN/` — under: docpermission, kappcenter, kautofindcontents, kbarcode, kclouddocs, kcloudfiledialog, kfeedback, khelp, kjsapipage, knewdocs, knewshare, koptioncenter, kphoneticsymbol, kpromeaccountpanel, kpromebrowser, kpromeprocesson, kpromewebapp, kpromeworkarea, kqingdlg, kqrcode, kscreengrab, kskincenter, ksoformatproof, kstartpage, kusercenter (+ any others in the full tree)
*   `mui/zh_TW/` — under: kbarcode, kclouddocs, koptioncenter, kpromeaccountpanel(?), kstartpage, kusercenter, kskincenter (+ others)
*   `mui/ja_JP/` — under: kbarcode, kscreengrab, kstartpage (+ others)
*   `shellext/mui/zh_CN/tr.xml` (kapplist) — 5.0K — **Safe to delete**

**Keep:** `mui/default/` and `mui/en_US/` everywhere (e.g. `addons/knewshare/mui/en_US/`).

**Verify first:** A handful of addons ship **only** a `zh_CN` `.qm` and no `default`/`en_US` (e.g. `kclouddocs`, `kcloudfiledialog`, `kqingdlg`). These addons are China/cloud-oriented and are also removal candidates in Section C — deleting their translations is safe, but confirm the addon itself is being removed rather than left half-localised.
### A.2 Web/i18n string bundles (`.properties`) — non-English
`office6/addons/kbarcode/mui/default/i18n/`:

| File | Lang | Size | Safety |
| ---| ---| ---| --- |
| strings\_ja-JP.properties | ja | 385B | Safe to delete |
| strings\_ja.properties | ja | 385B | Safe to delete |
| strings\_zh-CN.properties | zh | 284B | Safe to delete |
| strings\_zh.properties | zh | 284B | Safe to delete |
| strings\_zh-TW.properties | zh | 278B | Safe to delete |
| strings\_en-US.properties | en | 248B | KEEP |
| [strings.properties](http://strings.properties) (default) | base | 284B | KEEP |

Apply the same `strings_{zh*,ja*}.properties` deletion pattern to any other web-addon `i18n/` folder in the full tree (**Verify first** per folder — some use the base `strings.properties` as English).
### A.3 CEF UI locale packs (`.pak`)
`office6/addons/cef/locales/`:

| File | Lang | Size | Safety |
| ---| ---| ---| --- |
| zh-CN.pak | zh | 244K | Safe to delete |
| en-GB.pak | en (GB) | 238K | Safe to delete (optional; keep en-US) |
| en-US.pak | en | 240K | KEEP |

Only relevant if CEF is retained (see Section C.1). If CEF is removed entirely, the whole `locales/` folder goes with it.
### A.4 Language-adjacent data — Verify first
*   `office6/addons/kphoneticsymbol/` (pinyin) — Chinese phonetic input helper. **Verify first**: irrelevant to English editing, safe to remove, but confirm it is not wired into a shared spell/proofing path.
*   `office6/addons/ksoformatproof/` — format/proofing. **Verify first**: proofing may be language-tied; keep the addon, only drop its `mui/zh_CN`.
*   `khelp.data` / help HTML (`addons/khelp/mui/default/html/`) — help content; keep `default`, drop `zh_CN`.
> Not all languages may be fully enumerated above — the full manifest likely contains additional locale folders (and possibly a top-level `office6/mui/<lang>` tree and dictionaries) beyond the visible slice. Recommend a final sweep with: `find build -type d \( -name 'zh_CN' -o -name 'zh_TW' -o -name 'ja_JP' -o -name 'ko_KR' -o -name '*_CN' \)` and `find build -name '*.qm' ! -path '*/en_US/*'`.
* * *
## Section B — Telemetry, Analytics, Crash Reporting & Update Components

| Full path (under build/) | Purpose (likely) | Action | Possible side effects |
| ---| ---| ---| --- |
| opt/…/addons/kfeedback/libkfeedback.so | User feedback / usage reporting engine | Replace with dummy .so (or remove) | "Feedback" menu item dead; no core impact |
| opt/…/addons/kfeedbackcmds/libkfeedbackcmds.so | Feedback command hooks | Remove | Feedback commands unavailable |
| opt/…/addons/kfeedback/db/personal\_cn/{et,pdf,wpp,wps}.db | Feedback content DBs (CN) — ~12.8 MB total (4.4M+3.7M+3.0M+1.7M) | Remove | None; pure data payload |
| opt/…/addons/cloudpushsdk/libcloudpushsdk.so | Cloud push / notification SDK (phones home) | Replace with dummy .so | No push notifications; no core impact. Verify no hard dependency at startup |
| etc/xdg/autostart/\* | Background autostart entries (updater / daemon) | Remove | Stops background services launching at login — desired |
| etc/cron.d/\* | Scheduled jobs (likely update/telemetry check) | Remove | No scheduled callbacks — desired |
| etc/logrotate.d/\* | Rotation for WPS logs | Remove (optional) | Cosmetic; only matters if logs are disabled |
| DEBIAN/postinst (42K) | Post-install script — registers services, may enable update/telemetry, mime, symlinks | Verify first → edit | Must keep desktop/mime registration; strip only update/telemetry/cron setup. Do NOT blindly delete |
| DEBIAN/prerm (25K) / postrm / preinst | Maintainer scripts | Verify first | Needed for clean install/removal; audit for network calls |
| opt/…/addons/knetwork/libknetwork.so + rpclimit.cfg | Core network/RPC layer used by online addons | Verify first (keep, neutralise via blocklist) | Removing may break addons that dynamically link it; prefer the Section D network block over deletion |

**Notes**
*   **"Replace with dummy" vs "remove":** For `.so` files that other libraries may `dlopen`/link at startup, replacing with an empty/stub library (same filename) is safer than deleting — it avoids missing-symbol crashes while killing the behaviour. `kfeedback` and `cloudpushsdk` are prime dummy-replacement candidates.
*   **Auto-update:** No standalone updater binary is clearly visible in the shared slice. WPS Linux typically performs update/telemetry via `postinst` + autostart + the network layer rather than a dedicated daemon. **Verify first** by grepping the full manifest for `update`, `upgrade`, `daemon`, `push`, `report`, `stat`, `crash`.

* * *
## Section C — Online Features
These enable accounts, cloud, online templates/fonts, and web-powered panels. None are required for local document editing, but several share the CEF/network stack, so removal order matters.

| Full path (under build/) | Feature | Action | Affects offline editing? |
| ---| ---| ---| --- |
| opt/…/addons/cef/ ([libcef.so](http://libcef.so) 165M, \*.pak, icudtl.dat, swiftshader/…) | Chromium Embedded Framework — renders all in-app web panels | Verify first | Indirect: removing it disables start page, online templates, account panels. Core Writer/Sheets/Slides/PDF editing does NOT need CEF, but confirm before deleting ~180 MB |
| opt/…/addons/kcef/ (libjscefservice, libkbrowserclient, libkcefrender, libkcefwebview) | WPS↔CEF bridge / webview host | Remove (with CEF) | No — only web panels |
| opt/…/addons/jsapi/ (libjsapihttpserver, libjsapisubserver, libnativex) | Local JS-API HTTP bridge for web content | Remove / dummy | No — used by online panels |
| opt/…/addons/kclouddocs/ | Cloud documents | Remove | No |
| opt/…/addons/kcloudfiledialog/ | Cloud open/save dialog | Remove | Verify first — ensure local file dialog remains the default |
| opt/…/addons/kusercenter/ | Account / login / user center | Remove | No |
| opt/…/addons/knewshare/ | Cloud sharing / share folders | Remove | No |
| opt/…/addons/kqingdlg/ | "Qing" (Kingsoft cloud) dialogs | Remove | No |
| opt/…/addons/kskincenter/ | Online skin/theme download | Remove | No — bundled themes may also live here; Verify first before deleting whole dir |
| opt/…/addons/konlinefileconfig/ | Online file configuration | Remove | No |
| opt/…/addons/kappcenter/ + kapplist/ | App center / online tool list (papercheck, papertypeset, pdf2\* cloud engines) | Verify first | Some listed tools are local; deleting the whole applist removes local PDF/photo tools too. Prefer trimming online-only entries |
| opt/…/addons/kstartpage/ | Start page (online recommendations) | Remove / dummy | Verify first — start page is the launcher UI; removing may drop you straight into a blank workspace |
| opt/…/addons/kprome\* (kpromeaccountpanel, kpromebrowser, kpromeprocesson, kpromewebapp, kpromeworkarea) | "Prometheus" web-app / account / process-online suite | Remove | No — all web-powered |
| opt/…/addons/kqrcode/ | QR (often for mobile/cloud handoff) | Verify first | Likely no; may be used by local share-to-image |
| opt/…/addons/knewdocs/res/ (online template browser: CloudTab.svg, bg-neterror.png, loadingOutlines.gif) | Online template gallery | Trim online, keep local | Verify first — KEEP res/blanktemplate/\*.pptx (local blank docs); remove only the cloud-gallery web assets |
| opt/…/addons/kclouddocs/…/error-cefabort, error-page | Web error pages | Remove with kclouddocs | No |

**Recommended removal order (avoids crashes):** disable at the addon-registry/config level first → then remove the `kprome*`, `kclouddocs`, `kusercenter`, `knewshare`, `kqingdlg`, `konlinefileconfig` addons → then `kcef`/`jsapi` → **last**, decide on `cef/` (biggest space win, highest coupling). Keep `knetwork` in place but neutralise it via Section D.

* * *
## Section D — Network Blocklist (`/etc/hosts` style)
Redirect known WPS/Kingsoft endpoints to loopback to sever updates, telemetry, accounts, cloud, templates, fonts, CDN and licensing — without touching binaries. `/etc/hosts` does **not** support wildcards, so each subdomain is listed explicitly; for full coverage prefer a DNS sinkhole (dnsmasq/Pi-hole `address=/wps.cn/0.0.0.0`) or firewall egress rule on the parent domains.

```plain
# ---- WPS Office / Kingsoft blocklist (Verify first; english-only offline build) ----
# Accounts / login
0.0.0.0 account.wps.com
0.0.0.0 accounts.wps.cn
0.0.0.0 account.wps.cn
0.0.0.0 accountserver.wps.cn

# Telemetry / analytics / crash / feedback
0.0.0.0 data.wps.cn
0.0.0.0 dl.wps.cn
0.0.0.0 stat.wps.cn
0.0.0.0 log.wps.cn
0.0.0.0 crash.wps.cn
0.0.0.0 feedback.wps.cn

# Updates
0.0.0.0 update.wps.cn
0.0.0.0 updateservice.wps.cn
0.0.0.0 update.wps.com
0.0.0.0 versionupgrade.wps.cn

# Cloud storage / documents ("Qing" drive)
0.0.0.0 drive.wps.cn
0.0.0.0 qing.wps.cn
0.0.0.0 vip.wps.cn
0.0.0.0 open.wps.cn
0.0.0.0 clouddocs.wps.cn

# Templates (Docer) / online fonts / plugins
0.0.0.0 docer.wps.cn
0.0.0.0 docer.wpscdn.cn
0.0.0.0 font.wps.cn
0.0.0.0 fonts.wpscdn.cn
0.0.0.0 plugin.wps.cn
0.0.0.0 plugins.wps.cn

# Licensing / activation
0.0.0.0 license.wps.cn
0.0.0.0 activate.wps.cn

# API / gateways / push
0.0.0.0 api.wps.cn
0.0.0.0 gw.wps.cn
0.0.0.0 push.wps.cn
0.0.0.0 msg.wps.cn

# CDN
0.0.0.0 res.wpscdn.cn
0.0.0.0 res1.wpscdn.cn
0.0.0.0 img.wpscdn.cn
0.0.0.0 cdn.wps.cn

# International / misc Kingsoft
0.0.0.0 www.wps.com
0.0.0.0 wps.com
0.0.0.0 kingsoft.com
0.0.0.0 ksord.com
0.0.0.0 kso.cn
0.0.0.0 wpscloudsvr.com
```

> **Verify first (all of Section D).** These hosts are compiled from WPS/Kingsoft's known naming scheme and community block lists; the exact subdomains contacted by _this_ build should be confirmed by watching live DNS/traffic (e.g. `sudo tcpdump -n port 53`, or check strings in `libknetwork.so` / config files). Blocking the parent domains `wps.cn` / `wps.com` / `wpscdn.cn` at the DNS/firewall layer is the most robust option. Do not add `0.0.0.0 localhost`\-type entries and keep this block clearly delimited so it's easy to revert.
* * *
## Summary of expected space savings (from visible sizes)
*   Feedback DBs (`kfeedback/db/personal_cn/`): **~12.8 MB**
*   CEF stack (`cef/` incl. `libcef.so` 165M, `libGLESv2.so` 6.7M, `icudtl.dat` 11M, swiftshader 2.5M, paks): **~190 MB** (if CEF removed)
*   `kcef/` webview libs: **~4.2 MB**
*   Non-English `.qm` / `.pak` / `.properties`: **~0.5–1 MB** (small individually; larger once full tree swept)
*   `kfpccomb` / `docpermission` / cloud addons: several MB more depending on removal choices

**Biggest wins:** the CEF stack and feedback DBs. **Lowest risk:** non-English `.qm`/`.pak` deletions and the `/etc/hosts` block.
## Do-this-carefully list (behaviour-changing — decide before running)
1. **CEF removal** — large win but disables all in-app web UI; confirm start page/launcher still opens.
2. **`kstartpage`** **/** **`kapplist`** **/** **`knewdocs`** — mixed local+online; trim rather than nuke.
3. **`DEBIAN/postinst`** — edit, don't delete; keep mime/desktop registration, strip update/telemetry/cron.
4. **`knetwork`** — keep the lib, block the domains instead of deleting.

* * *
## Section A (expanded) — Language Resources
### A.5 Multi-language addons discovered in the full manifest
Two big addons ship a **wide** set of non-English locales (not just zh/ja). Delete every non-`default`/`en_US` locale dir under them.

**`officespace/mui/`** — locales present: `de_DE`, `es_ES`, `fr_FR`, `pt_BR`, `pt_PT`, `ru_RU`, `zh_CN`, `zh_TW` (+ `default`, `en_US`). Each holds `officespace.qm` and a `resource/{downloading,qing_plugins}.data`.

**`qing/mui/`** — locales present: `de_DE`, `es_ES`, `fr_FR`, `pt_BR`, `pt_PT`, `ru_RU`, `zh_CN`, `zh_TW` (+ `default`, `en_US`). Each holds `qingaccount.data` + `res/qingaccount/errPage.html`.

| Delete (non-English locale dirs) | Langs | Safety |
| ---| ---| --- |
| addons/officespace/mui/{de\_DE,es\_ES,fr\_FR,pt\_BR,pt\_PT,ru\_RU,zh\_CN,zh\_TW}/ | de,es,fr,pt,ru,zh | Safe (but see C: officespace itself is an online addon → likely removed wholesale) |
| addons/qing/mui/{de\_DE,es\_ES,fr\_FR,pt\_BR,pt\_PT,ru\_RU,zh\_CN,zh\_TW}/ | de,es,fr,pt,ru,zh | Safe (qing is the cloud-account addon → likely removed wholesale, see C) |

### A.6 Additional non-English `.qm` confirmed (delete; keep `en_US`/`default`)
`koptioncenter/mui/{zh_CN,zh_TW}/koptioncenter.qm` · `kphoneticsymbol/mui/zh_CN/kphoneticsymbol.qm` · `kpromeaccountpanel/mui/zh_CN/…qm` · `kpromebrowser/mui/zh_CN/…qm` · `kpromeprocesson/mui/zh_CN/…qm` · `kpromewebapp/mui/zh_CN/…qm` · `kpromeworkarea/mui/zh_CN/…qm` · `kqingdlg/mui/zh_CN/kqingdlg.qm` · `kqrcode/mui/zh_CN/kqrcode.qm` · `kscreengrab/mui/{ja_JP,zh_CN}/kscreengrab.qm` · `kskincenter/mui/zh_CN/kskincenter.qm` · `ksoformatproof/mui/zh_CN/ksoformatproof.qm` · `kstartpage/mui/{ja_JP,zh_CN,zh_TW}/kstartpage.qm` · `kusercenter/mui/zh_CN/kpromeusercenter.qm` · `pdfbatchcompression/mui/zh_CN/pdfbatchcompressionapp.qm` · `wpsbox/mui/zh_CN/wpsbox.qm` · `kweibo/mui/zh_CN/kweibo.qm` (keep `kweibo/mui/en_US/kweibo.qm` only if kweibo is kept — see C) · `wppcapturer/mui/zh_CN/common.qm` · `wppencoder/mui/zh_CN/common.qm` · `knewshare/mui/{zh_CN,zh_TW}/knewshare.qm`.
> **Keep the matching** **`en_US`** **`.qm`** for any addon you retain: `knewshare/mui/en_US`, `officespace/mui/en_US`, `qing/mui/en_US`, `kweibo/mui/en_US`, `wppcapturer/mui/en_US`, `wppencoder/mui/en_US`.
### A.7 Chinese language DATA (not UI) — **Verify first**
These are Chinese-language processing assets under `office6/data/`. They do **not** affect English editing, but some engines expect the files to exist:

| Path | What it is | Safety |
| ---| ---| --- |
| data/chinesesegment/ (friso engine + ~30 lex files, dict/, [LICENSE.md](http://LICENSE.md)) | Chinese word-segmentation dictionaries | Verify first — safe for English use, but confirm [libfriso.so](http://libfriso.so) doesn't hard-require them at load; if it does, keep the dir or replace with empty lex files |
| data/Pinyin.dic, data/PinyinTagger(.so), data/CharDic.dic, data/WordDic.dic, data/words\_bin.dat, data/unigram.dat, data/extend\_dict.dat | Chinese pinyin/word dictionaries | Verify first — Chinese-only features (pinyin sort, phonetic); removal usually safe but test sort/proofing |
| data/{location,person}\_{emit,roles,trans}.dat, firrule.dic, secrule.dic | NER / smart-recognition models (CN) | Verify first — likely tied to Chinese smart features |

### A.8 English dictionaries — **KEEP (do not delete)**
*   `dicts/spellcheck/en_US/` (main.aff, main.dic, dict.conf, README/Changelog) — **KEEP**
*   `dicts/spellcheck/en_CH/` (main.aff, main.dic, dict.conf) — **KEEP** (English variant)
### A.9 CEF locales (restated)
`addons/cef/locales/`: delete `zh-CN.pak`; keep `en-US.pak`; `en-GB.pak` optional.

* * *
## Section B (expanded) — Telemetry / Push / Update / Diagnostics
Newly confirmed components:

| Full path (under build/) | Purpose (likely) | Action | Side effects |
| ---| ---| ---| --- |
| addons/messagepush/libmessagepush.so | Message/notification push channel (phones home) | Replace with dummy .so | No in-app news/push; no core impact |
| addons/cloudpushsdk/libcloudpushsdk.so | Cloud push SDK | Replace with dummy .so | As above |
| addons/secanalyze/secanalyze.xml | "Security analyze" config — usage/diagnostic collection | Remove or blank | Verify first; likely no core impact |
| addons/kfeedback/\* (lib + db/personal\_cn/\*.db ~12.8 MB) + kfeedbackcmds | Feedback / usage reporting | Remove / dummy | Feedback UI dead |
| office6/libkprometheus.so + desktops/wps-office-prometheus.desktop | "Prometheus" web-app runtime + its launcher entry | Verify first | Removing the .desktop hides the Prometheus app; the lib may be referenced by kprome\* addons — dummy rather than delete unless all kprome\* go too |
| office6/libpaho-mqtt3as.so.1.3.9 | MQTT client lib — persistent push/telemetry transport | Verify first (keep file, block network) | Deleting may break a component that links it; neutralise via Section D instead |
| office6/libkdownload.so | Generic downloader (updates/templates/fonts) | Verify first | Used by multiple online features; block network rather than delete |
| office6/libKMailLib.so.71 + cfgs/smtp.xml | Mail/SMTP (feedback/share-by-email) | Verify first / remove smtp.xml contents | Email-share feature dead; no core impact |
| DEBIAN/postinst (42K), prerm (25K), preinst (3.4K), postrm (2.1K) | Maintainer scripts | Verify first → edit, don't delete | Keep mime/desktop registration & symlinks; strip any update/telemetry/cron/daemon setup. Audit all four for network calls (the oversized postinst/prerm are the priority) |

**Still not present in the manifest:** no standalone auto-updater binary or `etc/cron.d` / `etc/xdg/autostart` entries appear in the readable portion. Section B of page 1 listed those as _candidates_; treat them as **Verify first / may not exist** — confirm with `ls build/etc/cron.d build/etc/xdg/autostart` and by grepping `postinst` for `crontab`, `systemctl`, `update`.

* * *
## Section C (expanded) — Online Features
Major online subsystems revealed by the full manifest (all safe to remove for offline editing; remove the addon dir wholesale unless noted):

| Addon / path | Feature | Action | Affects offline editing? |
| ---| ---| ---| --- |
| addons/qing/ ([libqingbangong.so](http://libqingbangong.so), rpc.cfg, huge mui tree: cloud disk, login, wechat login, vip payment, trusted device, new-user guide) | Kingsoft "Qing" cloud account + cloud drive — the core online/account subsystem | Remove | No — pure cloud/account |
| addons/officespace/ ([libofficespace.so](http://libofficespace.so) + cloudlink\_cooperation, filedialog, qing\_plugins, usersecurecenter) | Cloud "office space" / collaboration surface | Remove | Verify first — ensure the local Open/Save dialog isn't routed through officespace's [filedialog.data](http://filedialog.data); keep local file dialog |
| addons/wpsbox/ ([libwpsbox.so](http://libwpsbox.so) + cloudsettings, filetransfer, sharefolder, syncfolder, teamevent, teammember, msgchannel, recommend, documentassistant) | WPS cloud box: sync, file transfer, team/share, recommendations | Remove | No |
| addons/kweibo/ ([libkweibo.so](http://libkweibo.so) + weibo/\*) | Weibo (Chinese social) sharing | Remove | No |
| addons/shareplay/libshareplay.so | SharePlay real-time online presentation sharing | Remove | No |
| addons/konlinefileconfig/ (lib + res: onlinefileconfig.xml, icon.rcc) | Online file-type config | Remove / Verify first | Verify first — confirm it's not consulted for local file associations |
| addons/kwebextensionlist/ (config.ini, kwebextensionlist.cfg, webshapenotices.txt) | Web extension/shape list (online content) | Remove | Verify first — "webshapes" may back some insertable shapes |
| addons/linkeddatatype/linkdata.json | Linked data types (online-backed cell types) | Remove | No |
| addons/kappcenter/, kapplist/, kappmgr/, kappentryobject/ | App center / tool list (mix of local PDF/photo tools + cloud engines like papercheck, papertypeset) | Verify first — trim, don't nuke | Some listed tools (pdf split/merge, photo tools) are local; deleting the whole applist removes them too |
| addons/kstartpage/ | Start page (online recommendations + local nav via res/kuip/officenav.kui) | Verify first | Start page is the launcher shell; prefer trimming its web/htmlep content over deleting the addon |
| addons/knewdocs/ (res/ online template gallery) | New-doc / online templates | Trim online; KEEP res/blanktemplate/\*.pptx | Verify first — local blank templates live here |
| addons/kprome\* (accountpanel, browser, processon, webapp, workarea) | "Prometheus" web-app suite | Remove (+ dummy [libkprometheus.so](http://libkprometheus.so) if all removed) | No |
| addons/kclouddocs/, kcloudfiledialog/, kusercenter/, knewshare/, kqingdlg/, kqrcode/ | Cloud docs, cloud dialog, account, sharing, cloud dialogs, QR handoff | Remove (kqrcode/konlinefileconfig: Verify first) | No (verify kcloudfiledialog doesn't replace local dialog) |
| addons/cef/ (~190 MB) + kcef/ + jsapi/ | Chromium Embedded Framework + bridge + JS-API HTTP server | Verify first (biggest win, highest coupling) | Removes ALL in-app web UI; core editing does not need it — confirm launcher/start page still opens first |

### C.1 Config files that point at online services (edit, don't delete blindly)
*   `office6/cfgs/domain_qing.cfg` — **cloud service domain map**; best single source for Section D endpoints. **Verify first / edit**: blanking it helps sever cloud, but a malformed file may error — prefer pointing entries at `127.0.0.1`.
*   `office6/cfgs/cacert.pem` — CA bundle used by `libcurl`/TLS. **KEEP** (removing breaks any HTTPS the app still needs, e.g. license checks you may leave intact).
*   `office6/cfgs/{ksoapp,setup,feature,product}.dat/.cfg`, `oem.ini`, `jside.cfg` — feature/product flags. **Verify first**: `feature.dat` / `oem.ini` may let you disable cloud/account features cleanly via config rather than file deletion (preferred).
*   `addons/qing/rpc.cfg`, `addons/knetwork/rpclimit.cfg` — RPC endpoint/limits. **Verify first**.
### C.2 Core libraries — **KEEP (required for local editing)**
`libetmain.so`, `libetapi.so`, `libexcelrw.so`, `libetxmlrw.so` (Spreadsheets) · `libpptreader.so`, `libpptwriter.so`, `libpptxrw.so`, `libplayer.so` (Presentation) · `libdocwriter.so`, `libhtml2.so`, `libhtmlpub.so` (Writer) · `libpdfmain.so`, `libqpdfpaint.so` (PDF) · `libkso.so`, `libksolite.so`, `libksoapi.so`, `libksmso.so` · all `libQt5*Kso.so.5.12.10` · `libicu*`, `libcrypto/ssl/nss*`, `libhunspell.so` (English spellcheck), `libmythes.so` (thesaurus). Do **not** remove these.
> **Caution — auth/account libs:** `libauth.so`, `libkqingaccountsdk.so`, `libqingipc.so` support login/account. They _look_ removable, but core binaries may link them at startup. **Verify first** — prefer disabling account UI (via config + removing the account addons) over deleting these base libs, to avoid a failed launch.
* * *
## Section D (expanded) — Network Blocklist
**Best source of truth in this package:** `office6/cfgs/domain_qing.cfg` — inspect it and add every host it lists. Until then, the page‑1 `/etc/hosts` block stands, plus these additions implied by the newly found subsystems (weibo, shareplay, mqtt push, mail):

```plain
# ---- Additions from full-manifest analysis (Verify against cfgs/domain_qing.cfg) ----
# Push / MQTT / messaging
0.0.0.0 push.wps.cn
0.0.0.0 mqtt.wps.cn
0.0.0.0 msg.wps.cn
0.0.0.0 minfo.wps.cn

# Weibo / social share
0.0.0.0 share.wps.cn
0.0.0.0 weibo.com
0.0.0.0 api.weibo.com

# SharePlay / collaboration / office space
0.0.0.0 shareplay.wps.cn
0.0.0.0 cooperation.wps.cn
0.0.0.0 group.wps.cn

# Qing cloud RPC / account SDK
0.0.0.0 qingrpc.wps.cn
0.0.0.0 kdocs.cn
0.0.0.0 www.kdocs.cn

# Templates / "docer" / recommend
0.0.0.0 recommend.wps.cn
0.0.0.0 newdocs.wps.cn
```

> Prefer a DNS sinkhole / egress firewall on the parent domains (`wps.cn`, `wps.com`, `wpscdn.cn`, `kdocs.cn`, `weibo.com`) over maintaining per-host lines. All entries remain **Verify first** — confirm against live DNS traffic and `domain_qing.cfg`.
* * *
## Updated space-savings highlights
*   `addons/cef/` ([libcef.so](http://libcef.so) 165M + GLESv2 6.7M + icudtl 11M + swiftshader 2.5M + paks): **~190 MB**
*   `addons/qing/` + `officespace/` + `wpsbox/` (large multi-locale web trees): **tens of MB**
*   `kfeedback/db/personal_cn/*.db`: **~12.8 MB**
*   `data/chinesesegment/` (friso lex set): **several MB** (Verify first)
*   Non-English `.qm`/locale dirs across ~25 addons + multi-locale `qing`/`officespace`: **several MB**
## Priority "Verify first before running" (behaviour-changing)
1. **CEF removal** — huge win, disables all web panels; confirm launcher opens.
2. **Base auth libs** (`libauth.so`, `libkqingaccountsdk.so`, `libqingipc.so`) — disable via config, don't delete, to avoid launch failure.
3. **`cfgs/feature.dat`** **/** **`oem.ini`** **/** **`domain_qing.cfg`** — prefer disabling cloud/account and rerouting domains via config over raw file deletion.
4. **`data/chinesesegment/`** **+ Chinese dicts** — safe for English, but test that segmentation/proofing libs still load.
5. **`kapplist`****/****`kstartpage`****/****`knewdocs`** — trim online entries; keep local tools & blank templates.
6. **`DEBIAN/postinst`** **&** **`prerm`** — edit to strip telemetry/update while preserving mime/desktop registration.
