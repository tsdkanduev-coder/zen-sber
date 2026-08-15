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
- Accent: `#21A038`, on-accent: `#FFFFFF`
- Existing Zen wordmarks stay; no official Sber logo lockups

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

## Environment snapshot (this Cloud Agent VM)

Recorded 2026-08-15:

| Tool | Version / notes |
| --- | --- |
| Node | v22.14.0 (`.nvmrc` = 22) |
| Python | 3.12.3 |
| rustc / cargo | started at 1.83.0; **installed 1.94.1** via `rustup toolchain install 1.94.1` to match `.rust-toolchain` |
| sccache | not on PATH initially; `mach bootstrap` installed `~/.mozbuild/sccache/sccache` |
| nasm | not on PATH initially; apt `nasm` 2.16.01 plus bootstrap `~/.mozbuild/nasm/nasm` 3.01 |
| clang | Ubuntu 18.1.3 on PATH; bootstrap uses `~/.mozbuild/clang` 21.1.8 |
| Disk | ~224GB free at start |
| CPU / RAM | 4 cores, 15 GiB, no swap |
| Firefox tree | not in git; Surfer unpacked `firefox-154.0` (candidate) into `engine/` |

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
