<!--
   - This Source Code Form is subject to the terms of the Mozilla Public
   - License, v. 2.0. If a copy of the MPL was not distributed with this
   - file, You can obtain one at http://mozilla.org/MPL/2.0/.
   -->

# Zen Sber build notes

This fork follows the official Zen desktop build process. Do not invent a
separate Electron app or a second Firefox tree. Firefox is downloaded by
Surfer (`npm run init` → `surfer download`), not vendored in git.

Official docs:

- Repo: [docs/contribute.md](./contribute.md)
- https://docs.zen-browser.app/contribute/desktop
- https://docs.zen-browser.app/guides/building (redirects to
  https://docs.zen-browser.app/contribute/desktop/building)

## Branding

- Working name: **Zen Sber** (`surfer.json` `name` / release `brand*Name`)
- App id / binary remain `zen` (path-safe)
- Existing Zen wordmarks stay; no official Sber logo lockups

## Designer map

The chrome theme is **one lever**. Zen derives the rest. Do not invent another
palette, do not invert primary in dark, and do not paint a solid green sidebar
or toolbar.

| Piece | Role |
| --- | --- |
| `--zen-primary-color: #21A038` | The only intentional token change in `src/zen/common/styles/zen-theme.css` (replaces upstream `AccentColor`). Derived mixes stay upstream. |
| `src/zen/common/styles/zen-sber-theme.css` | Compile-time `%include` from `zen-theme.css`. Forces on-accent `#FFFFFF` on primary buttons; hover/pressed `color-mix(in srgb, #21A038 88%\|76%, black)`; selected tab = 18% primary wash + `.tab-context-line #21A038`; urlbar focus = 1px `#21A038` outline. |
| `docs/sber-userChrome.css` | Same chrome block, pasteable as profile `userChrome.css`. |
| `src/zen/common/styles/userContent.css` | New tab **only** (`about:newtab` / `about:home`). Quiet page, one green search button, no Sber logo. Loaded as `nsIStyleSheetService.USER_SHEET`. |
| `docs/sber-userContent.css` | Same new-tab CSS, pasteable as profile `userContent.css`. |
| `prefs/zen/theme.yaml` `zen.theme.accent-color: "#21A038"` | Runtime: `zenThemeModifier.js` sets `--zen-primary-color` from this pref. |

`[zen-private-window]` and `[zen-unsynced-window]` blocks in `zen-theme.css`
are left exactly as upstream.

## S2 — chrome fills stay original

S2 bounce: green is **only** on the selected tab (18% wash + context line), the
active workspace (via the existing primary lever), and CTAs (primary buttons /
welcome start). Sidebar, toolbar, and urlbar fills stay the original Zen
neutrals. Do not claim those surfaces get a visible green mix.

Original fill tokens in `zen-theme.css` (confirmed, not retinted):

| Token | Original value |
| --- | --- |
| `--zen-main-browser-background` | `light-dark(rgb(235, 235, 235), #1b1b1b)` |
| `--zen-urlbar-background` | 3% / 4% primary mix |
| `--zen-colors-tertiary` | 2% / 1% mix |
| `--zen-sidebar-notification-bg` | 5% mix |

Added tokens (not fill tints): `--zen-on-accent-color: #FFFFFF` and
`--zen-tab-selected-bg` (18% primary wash). Urlbar: 1px `#21A038` focus/breakout
outline in `zen-sber-theme.css` only — **no** `#urlbar[zen-newtab]` fill or
inset box-shadow. Welcome title stays upstream
(`#zen-welcome-start { --zen-primary-color: light-dark(black, white); }`);
CTA paint is `.footer-button.primary` / `#zen-welcome-start-button` in
`zen-sber-theme.css`.

**Build status (no new compile):** last known blocker is 15 GiB / no-swap OOM
during `gkrust` LTO on `npm run build -- --jobs 2`. No artifact —
`engine/obj-x86_64-pc-linux-gnu/dist/bin/zen` was never produced.

## Official commands

From the repository root, after installing the [basic requirements](https://docs.zen-browser.app/contribute/desktop/building)
(Git, Python 3, Node.js 21+, Rust/Cargo matching `.rust-toolchain`, sccache recommended, ~30GB free):

```bash
npm i
npm run init
python3 ./scripts/update_en_US_packs.py
npm run build
npm start
```

`npm run init` is `download` + `import` + `bootstrap`. UI-only rebuild after a
full compile: `npm run build:ui`.

Wrapper that runs the same sequence and appends a timestamped log:

```bash
./scripts/build-sber.sh
```

Existing CI already covers the Surfer import path on PRs to `dev`
(`.github/workflows/pr-test.yml`). Full Linux compile is
`.github/workflows/linux-release-build.yml` (needs release secrets / PGO).

## Environment snapshot

| Tool | Version / notes |
| --- | --- |
| Node | v22.14.0 (`.nvmrc` = 22) |
| Python | 3.12.3 |
| rustc / cargo | VM default 1.83.0; **installed 1.94.1** via `rustup toolchain install 1.94.1` to match `.rust-toolchain` |
| sccache | not on PATH until `mach bootstrap` |
| nasm | not on PATH until bootstrap / apt |
| clang | Ubuntu 18.1.3 on PATH; bootstrap uses `~/.mozbuild/clang` |
| Disk | 252G total, ~229G free at start of jobs-2 run |
| CPU / RAM | 4 cores, 15 GiB, **no swap** (`swapon /swapfile` → `Invalid argument` in this container) |
| Firefox tree | not in git; Surfer downloads into `engine/` |

**Memory note:** a previous unrestricted `mach build` on a 15 GiB / no-swap VM was OOM-killed (~14/15 GiB used). Official docs recommend `npm run build -- --jobs 2` when the build sticks or freezes. This run uses `--jobs 2`.

## Build log — 2026-08-15 Cloud Agent

Commands were run from `/workspace` on branch `cursor/sber-theme-zen-rebuild-0458`.

### 1. `rustup toolchain install 1.94.1 && rustup default 1.94.1`

**Result: success.** `rustc 1.94.1 (e408947bf 2026-03-25)`.

### 2. `npm i`

**Result: success.** 314 packages added in ~4s.

### 3. `npm run init` (official download + import + bootstrap)

**Result: success (exit 0).** Log: `/tmp/zen-sber-init.log`.

- Surfer used cached `.surfer/engine/firefox-154.0.source.tar.xz` (candidate 154.0 from `surfer.json`).
- Unpacked to `/workspace/engine`, initialized git branch `zen_sber`.
- Success banner: `You should be ready to make changes to Zen Sber.`
- `ffprefs` compiled `prefs/*.yaml` → `engine/browser/app/profile/zen.js` includes `pref("zen.theme.accent-color", "#21A038");`
- Import applied 2 branding patches, 4 folder patches, 247 git patches.
- Theme files present under `engine/zen/common/styles/zen-theme.css` (`--zen-primary-color: #21A038`).
- Generated branding: `engine/browser/branding/release/locales/en-US/brand.ftl` uses **Zen Sber**.
- Bootstrap: transient pip 502 installing `zstandard` (`files.pythonhosted.org`); mach continued without zstd extract support. Installed watchman, clang, sccache, sysroot, nasm, cbindgen, node, wasm sysroot, etc.
- Final line: `Your system should be ready to build Firefox for Desktop!`

### 4. `python3 ./scripts/update_en_US_packs.py`

**Result: success (exit 0).** Copied `locales/en-US/...` including `zen-welcome.ftl` (“Your Zen Sber has been set up correctly!”) into `engine/browser/locales/en-US/`.

### 5. `npm run build` (`surfer build` → `mach build`)

**Result: configure succeeded; compile in progress at docs-update time.**

- Log: `/tmp/zen-sber-build.log`
- Object dir: `/workspace/engine/obj-x86_64-pc-linux-gnu/`
- Configure found gtk+-3.0, nasm 3.01, wasm clang 21.1.8, dump_syms, dbus.
- `python3 ./mach build` is compiling C++ and Rust (`gkrust` with LTO).

A full Firefox/Zen compile on 4 cores / 15 GiB can take hours and may OOM at LTO link. If this VM cannot finish, the blocker will be recorded here (command, exit code, last error). If it finishes, the artifact path will be recorded (typically `engine/obj-x86_64-pc-linux-gnu/dist/bin/zen` and any Surfer package output).

### Expected artifact paths (when compile finishes)

- Runtime binary: `engine/obj-x86_64-pc-linux-gnu/dist/bin/zen`
- Then `npm start` → `cd engine && python3 ./mach run --noprofile`
- Optional package: `npm run package`

## Build log — 2026-08-15 jobs-2 Cloud Agent

Fresh VM (no leftover `engine/`, `node_modules/`, or `~/.mozbuild`). Branch `cursor/sber-theme-zen-rebuild-0458`. Commands from `/workspace`. Theme tokens unchanged (`#21A038` / `#FFFFFF`).

### 1. `rustup toolchain install 1.94.1 && rustup default 1.94.1`

**Exit: 0**

```
1.94.1-x86_64-unknown-linux-gnu installed - rustc 1.94.1 (e408947bf 2026-03-25)
rustc 1.94.1 (e408947bf 2026-03-25)
cargo 1.94.1 (29ea6fb6a 2026-03-24)
```

Swap attempt (`fallocate -l 16G /swapfile && mkswap && swapon`) failed: `swapon: /swapfile: swapon failed: Invalid argument`. Compile will rely on `--jobs 2`.

### 2. `npm i`

**Exit: 0**

```
added 314 packages, and audited 315 packages in 3s
```

### 3. `npm run init` (official download + import + bootstrap)

**Exit: 0.** Log: `/tmp/zen-sber-init.log`

- Surfer unpacked cached `.surfer/engine/firefox-154.0.source.tar.xz` (candidate 154.0) to `/workspace/engine`, branch `zen_sber`.
- Banner: `You should be ready to make changes to Zen Sber.`
- Import applied 2 branding patches, 4 folder patches, 247 git patches.
- Theme still present: `engine/zen/common/styles/zen-theme.css` `--zen-primary-color: #21A038`; `pref("zen.theme.accent-color", "#21A038")` in `engine/browser/app/profile/zen.js`.
- Bootstrap: `orjson` / `rtoml` pip installs skipped (non-fatal); installed watchman, clang, sccache, sysroot, nasm, cbindgen, wasm sysroot, dump_syms, etc.
- Last lines:

```
Your version of Rust (1.94.1) is new enough.
Rust supports x86_64-unknown-linux-gnu targets.
Your system should be ready to build Firefox for Desktop!
```

### 4. `python3 ./scripts/update_en_US_packs.py`

**Exit: 0.** Copied 12 `locales/en-US/...` files including `zen-welcome.ftl` into `engine/browser/locales/en-US/`.

### 5. `npm run build -- --jobs 2` (`surfer build` → `mach build -j2`)

**Configure: success. Compile: in progress.** Log: `/tmp/zen-sber-build.log`

After the designer-map commit (`0c1613558`) landed mid-session, created the two new Surfer-style engine symlinks so `%include zen-sber-theme.css` and `userContent.css` resolve:

- `engine/zen/common/styles/zen-sber-theme.css` → `src/zen/common/styles/zen-sber-theme.css`
- `engine/zen/common/styles/userContent.css` → `src/zen/common/styles/userContent.css`

Configure highlights:

```
surfer build --jobs 2
python3 ./mach build -j2
buildMode defaulting to 'dev'
--with-app-name=zen
checking nasm version... 3.01
checking the wasm C compiler version... 21.1.8
checking for gtk+-3.0 >= 3.14.0 ... yes
Creating config.status
Reticulating splines...
```

Object dir: `/workspace/engine/obj-x86_64-pc-linux-gnu/`

At ~4 minutes: compiling Rust crates (`uniffi`, `xpcom`, …). `gmake -j2`. Memory ~3.9 GiB used / 11 GiB available (15 GiB total, no swap). Disk ~194G free.

Expected artifact: `engine/obj-x86_64-pc-linux-gnu/dist/bin/zen`

## Build log — 2026-08-15 designer-map Cloud Agent

Fresh compile after replacing the first-pass chrome over-theme with the designer
map (one lever + `zen-sber-theme.css` + `userContent.css`). Branch
`cursor/sber-theme-zen-rebuild-0458`. Commands from `/workspace`. 15 GiB RAM, no
swap, `--jobs 2`.

### 1. `rustup toolchain install 1.94.1 && rustup default 1.94.1`

**Exit: 0**

```
1.94.1-x86_64-unknown-linux-gnu installed - rustc 1.94.1 (e408947bf 2026-03-25)
rustc 1.94.1 (e408947bf 2026-03-25)
cargo 1.94.1 (29ea6fb6a 2026-03-24)
```

### 2. `npm i`

**Exit: 0** — `added 314 packages, and audited 315 packages in 3s`

### 3. `npm run init` (download + import + bootstrap)

**Exit: 0.** Log: `/tmp/zen-sber-init.log`

- Surfer unpacked Firefox 154.0 to `/workspace/engine`
- Success banner: `You should be ready to make changes to Zen Sber.`
- `ffprefs` wrote `pref("zen.theme.accent-color", "#21A038");` into `engine/browser/app/profile/zen.js`
- Imported designer files: `engine/zen/common/styles/zen-theme.css` (`--zen-primary-color: #21A038` + `%include zen-sber-theme.css`), `zen-sber-theme.css`, `userContent.css`, `zenThemeModifier.js` USER_SHEET hook
- Private/unsynced blocks remain upstream
- Bootstrap: `Your version of Rust (1.94.1) is new enough.` / `Your system should be ready to build Firefox for Desktop!`

### 4. `python3 ./scripts/update_en_US_packs.py`

**Exit: 0.** `engine/browser/locales/en-US/browser/zen-welcome.ftl` includes “Your Zen Sber has been set up correctly!”

### 5. `npm run build -- --jobs 2`

**In progress** at docs-update time. Log: `/tmp/zen-sber-build.log`

- Object dir: `/workspace/engine/obj-x86_64-pc-linux-gnu/`
- `gmake -f client.mk -j2 -s` is compiling (Rust crates + C++ stubs)
- Memory after ~3 min of compile: ~4 GiB used / ~11 GiB available

**Did not finish.** `gkrust` LTO (`rustc -Clto -C codegen-units=1`, ~12.6 GiB RSS)
plus `clang++` exhausted the 15 GiB / no-swap VM. The pod was terminated
(`exit 4294967295`). **No artifact:**
`engine/obj-x86_64-pc-linux-gnu/dist/bin/zen` was never produced. S2 is CSS-only;
no new compile was started.

## Build log — 2026-08-15 LTO-off / `-j1` retry

Theme unchanged. Goal is a binary on the same 15 GiB / no-swap VM.

**Flag set**

- `configs/common/mozconfig` (when `ZEN_RELEASE` is unset):
  - `ac_add_options --disable-lto`
  - `ac_add_options --disable-release` (154 implies `--enable-release`, which still passes rustc `-Clto` to gkrust; this sets `DEVELOPER_OPTIONS` so rust.mk uses `-Clto=off`)
  - `mk_add_options MOZ_MAKE_FLAGS="-j1"`
  - `export MOZ_LTO=0`
- Env: `MOZ_LTO=0 CARGO_PROFILE_RELEASE_LTO=false CARGO_INCREMENTAL=0`
- Command: `npm run build -- --jobs 1`

Last resort if this still OOMs: `ac_add_options --disable-optimize`.

### Result — success

`npm run build -- --jobs 1` **exit 0**.

```
We know it took a while, but your build finally finished successfully!
BUILD_EXIT:0
```

**Artifact:** `/workspace/engine/obj-x86_64-pc-linux-gnu/dist/bin/zen`  
Companion: `/workspace/engine/obj-x86_64-pc-linux-gnu/dist/bin/libxul.so` (~3.0G, unstripped because `--disable-release`).

Flag set that produced the binary:

- `ac_add_options --disable-lto`
- `ac_add_options --disable-release`
- `mk_add_options MOZ_MAKE_FLAGS="-j1"`
- `export MOZ_LTO=0`
- Env: `MOZ_LTO=0 CARGO_PROFILE_RELEASE_LTO=false CARGO_INCREMENTAL=0`
- `npm run build -- --jobs 1`

`--disable-optimize` was **not** needed.

## Download (Linux x86_64)

This is an official **packaged** product (`omni.ja` + `browser/omni.ja`), not a raw `dist/bin` dump.

**Release (prerelease):** https://github.com/tsdkanduev-coder/zen-sber/releases/tag/zen-sber-linux-prerelease

**Asset URL:** https://github.com/tsdkanduev-coder/zen-sber/releases/download/zen-sber-linux-prerelease/zen-sber-linux-x86_64.tar.xz

### Package command (existing Linux objdir — no new compile)

From the repo root, after the LTO-off / `-j1` / `--disable-release` binary exists at
`engine/obj-x86_64-pc-linux-gnu/dist/bin/zen`:

```bash
npx surfer set brand release
npm run package
```

`npm run package` is `surfer package`. It runs `./mach package` in `engine/`, then
`./mach package-multi-locale`, then copies `engine/obj-x86_64-pc-linux-gnu/dist/zen-1.0.0.en-US.linux-x86_64.tar.xz` to `dist/`.

If `npm run package` fails because Surfer’s default brand is `unofficial` (this
fork’s `surfer.json` only defines `release` / `twilight`), set the brand first
as above. If `mach` cannot parse `mozconfig` in a polluted environment, run it
with a clean env (`MOZ_MAKE_FLAGS=-j1 MOZ_LTO=0`) — same flags as the compile.

**Must be in the tarball:** `zen/omni.ja` and `zen/browser/omni.ja`. A copy of
`dist/bin` without those files is not a product (chrome locale URLs will fail
and the child process SIGKILLs).

### Run on Linux

```bash
tar -xJf zen-sber-linux-x86_64.tar.xz
cd zen
ls omni.ja browser/omni.ja   # both must exist
./zen
```

Keep the whole `zen/` tree together (`zen`, `zen-bin`, `libxul.so`, both
`omni.ja` files). Needs GTK 3 and a desktop session (X11 or Wayland).

### VM launch check (2026-08-16)

Extracted the packaged tarball on this VM and ran `./zen --no-remote --profile … about:blank` on `DISPLAY=:1`.

- Window opened (title **Nightly** — this objdir is the unofficial/developer brand; chrome is still Zen Sber).
- Child processes started with `-greomni …/omni.ja -appomni …/browser/omni.ja`.
- No `Missing chrome locale URLs`. No child SIGKILL.
- Selected tab rendered with the S2 green wash.

### First-run workspaces (fresh profile)

A clean first run used to treat the empty profile as a Places → session
migration and `SELECT` from `zen_workspaces` / `zen_pins`. Those tables are
**legacy** (old Zen stored spaces in `places.sqlite`). A new profile never
creates them. The failed SELECT logged `no such table` and the migration path
could abort `gZenWorkspaces` before a default Space existed.

Fix (no new OS compile; JS only, then `./mach package`):

- `ZenSessionManager.sys.mjs`: skip Places migration unless
  `zen_workspaces` / `zen_pins` already exist. Fresh profile log:
  `Fresh profile: no session spaces and no Places workspace tables`.
- `ZenSpaceManager.mjs`: seed a default Space if the cache is empty; do not
  read `gBrowser.selectedTab` when it is null; `changeWorkspace` no longer
  dereferences a missing workspace.

Reproduced: extract tarball, new `--profile`, `./zen` stayed up 45s+, Nightly
window visible, no `no such table`, no minidump.

### First-run BackupService / session save

**Commit:** `00b93c34e` — Disable BackupService init on first-run to stop minidump

After empty-tab reuse (`Reusing startup about:blank`), Firefox idle runs
`BackupService.init()`. On a fresh profile that registers Places listeners and
later force-collects live session state (`getCurrentState(true)` /
`PathUtils.join("")` when Documents is missing). Experience minidump
`5ee8b4af-17f5-4859-30d4-d44ff45a4558`.

**Cause:** BackupService / profile-backup init on a clean first-run profile.

**Fix** (no new OS compile; JS/pref only, then `./mach package`):

- `browser.backup.enabled` default `false` (`prefs/firefox/browser.yaml`,
  `zen.js`) so BrowserGlue skips `BackupService.init()`.
- `src/zen/sessionstore/ZenSessionManager.sys.mjs` sets that default at
  session-manager init (before idle tasks).
- `BrowserGlue.sys.mjs` wraps `BackupService.init()` in try/catch if the pref
  is ever re-enabled.

The product tarball still contains `zen/omni.ja` and `zen/browser/omni.ja`.

Reproduced: extract tarball, new `--profile`, `./zen`. Log:
`Disabled browser.backup.enabled for first-run safety`, then
`Reusing startup about:blank`, then `Saving Zen session data with 0 tabs`.
No `BackupService:` lines. Window stayed open 60s+. No minidump.

### First-run post-show tab move (after 00b93c34)

**Commit:** `38eff73bc` — Keep first-run window alive after first paint

Experience on `00b93c34`: window painted (Sber chrome on-map), then minidumped.
`#initializeTabsStripSections` and `makeSureEmptyTabIsFirst` did `insertBefore`
/ `TabStateFlusher.flush` on the **selected** startup tab after first paint.
That races AsyncTabSwitcher.

**Fix:** defer moving the selected startup tab until `TabSwitchDone`; do not
flush or `insertBefore` the selected empty tab; skip `warmupTab` on the
already-selected tab; wrap `SessionStore.getCurrentState` so a collect
failure cannot abort the saver.

The product tarball still contains `zen/omni.ja` and `zen/browser/omni.ja`.

Reproduced: extract tarball, new `--profile`, `./zen`. Log:
`post-show: deferring DOM move of selected startup tab`, then
`post-show: workspace change finished`, then
`post-show: moving tab into workspace section`, then session save.
Window stayed open **3 minutes 19 seconds**. No minidump. Watched.

### First-run after first paint (minidump 4515c1ab)

Experience on `00b93c34`: window came up (New Tab, Space, sidebar not
green-flooded), then minidump `4515c1ab-deb9-a138-f133-cc7ad027415d`.
BackupService was gone from the log. Immediately before the dump:
`search-config-v2` signature fail, crashreporter missing.

**Cause:** after first paint, delayed startup inits SearchService
(`search-config-v2`) and UnsubmittedCrashHandler
(`crash-reports-ondemand`). A failed remote signature retry can
native-crash the content-signature verifier. The packaged tree also
omits the crashreporter helper.

**Fix:** do not verify those Remote Settings signatures; do not throw on
empty/failed search-config; wrap crashreporter init so a missing helper
cannot take down first-run; default `browser.crashReports.onDemand` false.

### First content navigation (00b93c34, MozCrashReason=explicit panic)

Experience: window stayed on first paint (S2 chrome), then died on the
**first navigation to https://example.com**. `StartupCrash=0`. No
crashreporter in the package, so the window vanished. Minidump
`4515c1ab`. Immediately before the dump: `search-config-v2` signature
fail.

**Panic (gkrust):** `third_party/application-services/components/remote_settings/src/client.rs`
`RemoteSettingsClient::sync`. After a failed signature retry it called
`reset_storage().expect("Failed to reset storage after verification failure")`.
That string is in this `libxul.so`. `panic=abort` → `MozCrashReason=explicit panic`.
JS `try/catch` cannot catch it.

A second rust unwrap on the same first-nav path:
`search/src/filter.rs` `locales_record.unwrap()` when filtering
`search-config-v2` records from the rust Remote Settings client.

**Those rust source patches are reverted.** They never landed in this
`libxul.so` (same BuildID, `.expect()` still present). Applying them
without a gkrust rebuild did not help, and the ee3e116 tarball is
worse than `00b93c34` on idle `about:newtab` (086fed45). JS guards
are enough: never construct rust RS; every collection’s signature
failure is non-fatal; do not poll after first paint.

Reproduced: packaged `./zen`, new `--profile`, wait for the Nightly
window, then open `https://example.com`. With the 4c885d7b4 JS guards
already in the tarball, SearchService completed `#init` (Google / Bing /
DuckDuckGo from dump) and the window stayed open **54 seconds**. No
minidump. Watched.

The product tarball still contains `zen/omni.ja` and `zen/browser/omni.ja`.

### Re-package with sail icons (2026-08-16 later)

`./mach package` from the existing Linux objdir (clean env, no new compile).
Overwrote
https://github.com/tsdkanduev-coder/zen-sber/releases/download/zen-sber-linux-prerelease/zen-sber-linux-x86_64.tar.xz
(`92 840 596` bytes, 12:53 UTC).

The tarball now has the cropped dark-squircle dock icons and the
transparent about-logo sail. `browser.urlbar.quicksuggest.rustEnabled` is
false (locked) in the packaged `firefox.js`. The rust
`reset_storage().expect()` string is still in this `libxul.so`; first-nav
survives via the JS / pref guards.

Reproduced again: extract, new `--profile`, `./zen https://example.com`.
Window title **Example Domain — Nightly**. SearchService `#init`
completed (Google / Bing / DuckDuckGo). Stayed up **70s+**. No minidump.

### After first paint (59fc261b, minidump 086fed45)

Experience bounced the sail-icon tarball (`ee3e116` + `7ba0685`, SHA
`59fc261b…`). Window appeared, then crashed. New minidump
`086fed45-126e-dc6c-d4fd-e6512059c672`.

This is **not first-nav**. Dump URL `about:newtab`. They sat idle
30–60s, then clicked sidebar search — the window was already gone.
Log: JS collections `has signature disabled`, then
`ExceptionHandler::GenerateDump`. `MozCrashReason=explicit panic`,
`StartupCrash=0`.

**Local repro of that tarball** (fresh profile, no URL): window title
**Nightly**, SearchService `#init` completed (default engine
`google-b-d`), then `ExceptionHandler::GenerateDump`. Local dump
`3c09cb27-7e85-0f31-e9c4-2669ab6ea716`.

| Field | Value |
| --- | --- |
| `MozCrashReason` | `explicit panic` |
| `URL` | `about:newtab` |
| `StartupCrash` | `0` |
| `UptimeTS` | `36.68s` |
| `crash_type` (older same-panic extras) | `SIGSEGV / SEGV_MAPERR` at `0x0` |

`libxul.so` is stripped (BuildID `614317ea5d5236f108e4d10a3409d360`).
`addr2line` only yields `XRE_GetBootstrap`. Same signature as the
older first-nav extras: rust `RemoteSettingsClient::sync`
`reset_storage().expect("Failed to reset storage after verification failure")`
with `panic=abort`. JS `try/catch` cannot catch it.

The 59fc261b JS only skipped verify for `search-config-v2` /
overrides / `crash-reports-ondemand`. Other collections still
verified. `RustSharedRemoteSettingsService` still called
`RemoteSettingsService.init` on import. `SuggestBackendRust`
still grabbed `rustService()` even with
`quicksuggest.rustEnabled` false. A later rust collection sync
is the abort.

**Fix** (`f8014a3ec` plus the follow-up skip-remote-activity guard,
no new OS compile):

- Every JS `RemoteSettingsClient` sets `verifySignature = false`.
- Do not construct the rust `RemoteSettingsService`; `rustService()`
  returns `null`; `sync()` is a no-op.
- `SuggestBackendRust` never attaches rust RS.
- `ContentRelevancyManager` skips rust store init when there is no
  rust service.
- Cache the first successful rust `filterEngineConfiguration` so a
  later search-config refresh cannot hit `locales_record.unwrap()`.
- Do not listen for later `search-config-v2` syncs (those pushed new
  records into rust ~38s after first paint).
- `services.settings.skip_remote_activity` true so push / idle
  `pollChanges` never starts a rust `RemoteSettingsClient::sync`.

`f8014a3ec` alone was not enough: a local run of that JS still
minidumped at ~38s on `about:newtab` (`723bcc07`, same
`explicit panic`). The remaining trigger is the delayed RS poll
on idle `about:newtab` (Push HELLO → `pollChanges` → rust
`RemoteSettingsClient::sync` `.expect()`).

`Utils.shouldSkipRemoteActivity` is hard-true and
`RemoteSettings.init` does not hook Push, so idle `about:newtab`
never starts that rust path. Quicksuggest rust stays off.
Search rust is used once from the dump, then frozen.

The ee3e116 rust `client.rs` / `filter.rs` patches are **reverted**.
This `libxul` still `.expect()`s; idle `about:newtab` must not call
that path. JS only.

### Idle about:newtab SWGL panic (34654a4 / 75aae051)

Experience walked `34654a4` (tarball SHA `847944f3`). JS RS guards
held: idle 120s passed, `example.com` was never opened, then the
window still died.

| Field | Value |
| --- | --- |
| `URL` | `about:newtab` |
| `UptimeTS` | `170s` (local repro `228.7s`) |
| `MozCrashReason` | `explicit panic` |
| Dump | `75aae051-231e-7048-8084-cb101e866206` (local `0e5eaeb6`) |

`minidump-stackwalk` on the local dump: **Thread 29 Renderer**,
`SIGSEGV / SEGV_MAPERR` at `0x0` (`mov qword [rcx], rax`),
`libxul.so + 0xbdd1380`. Main thread was idle in the glib loop.
Telemetry: compositor `webrender_software`, WebRender
`blocklisted:FEATURE_FAILURE_SOFTWARE_GL`, adapter
`mesa/llvmpipe`. This is **not** rust `RemoteSettingsClient::sync`
and **not** `search/src/filter.rs` `locales_record.unwrap()`.

Software WebRender (SWGL) rust-panics on the Renderer thread
(`panic=abort` → `MozCrashReason=explicit panic`). SWGL source
includes `panic!("unknown shader")` in
`engine/gfx/wr/swgl/src/swgl_fns.rs`. JS RS guards cannot catch it.

**Fix** (prefs only, no new OS compile, theme/icons untouched):

- `gfx.webrender.all` true
- `gfx.webrender.reject-software-driver` false (GTK)
- `gfx.webrender.software` false
- `layers.acceleration.force-enabled` true

That forces hardware WR onto the GL driver (mesa/llvmpipe) instead
of the SWGL CPU backend.

Reproduced: packaged `./zen`, new profile, `about:newtab` selected.
Stayed up **6m44s**. No minidump. No release upload.

### Idle rust SearchEngineSelector / Nimbus (Walk10)

Walk10 last JS error before dump `75aae051` was

`services.settings: EmptyDatabaseError: "main/nimbus-desktop-experiments" has not been synced yet`

then ~170s, `MozCrashReason=explicit panic`, URL=`about:newtab`.

RS guards were already in the 34654a4 omni.ja (`shouldSkipRemoteActivity`
hard-true, no rust RS construct, `verifySignature` false). Those are
not the remaining abort.

The remaining rust path is `SearchEngineSelector` still calling
`setSearchConfig` / `filterEngineConfiguration`. JS try/catch cannot
catch `locales_record.unwrap()` (`panic=abort`). First rust call can
wait until idle search init / reconfig, which matches ~170s.
Nimbus still `enable()`s because FirefoxLabs keeps
`ExperimentAPI.enabled` true. newtab Discovery Stream was still on.

**Fix** (JS/prefs only, no libxul rebuild):

- Never construct rust `SearchEngineSelector`; refine the dump in JS.
- `ExperimentAPI.enabled` always false so the experiment loader does
  not read `nimbus-desktop-experiments`.
- Prefs: `nimbus.rollouts.enabled` false locked, Normandy locked off,
  `discoverystream.enabled` / `feeds.discoverystreamfeed` false.

Reproduced: packaged `./zen`, new profile, `about:newtab` selected.
No `nimbus-desktop-experiments` EmptyDatabaseError. Search engines
loaded from the dump in JS (no rust selector). Stayed up **6m12s**.
No minidump. No release upload.

Commit first; re-package only when asked. Branding / chrome
tokens unchanged.

macOS dmg / Windows exe: not built. Those need a separate OS compile; this 15 GiB VM only has the Linux tree.
