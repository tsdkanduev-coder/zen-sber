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

macOS dmg / Windows exe: not built. Those need a separate OS compile; this 15 GiB VM only has the Linux tree.
