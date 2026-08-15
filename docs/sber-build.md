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

Recorded 2026-08-15 before the first official-build attempt:

| Tool | Version / notes |
| --- | --- |
| Node | v22.14.0 (`.nvmrc` = 22) |
| Python | 3.12.3 |
| rustc / cargo | 1.83.0 installed; **`.rust-toolchain` requires 1.94.1** |
| sccache | not installed |
| Disk | ~224GB free (enough for a 30GB Firefox build) |
| Firefox tree | not in git; created under `engine/` by Surfer |

## Build log

Commands below were run on this VM. Update this section when a step finishes
or fails.

### 2026-08-15 — first attempt

Status: **in progress / not yet run at docs-write time.** The PR lands the
theme first; the agent then runs the official sequence and amends this log
with the exact command, exit code, and blocker (or artifact path).

Expected first blockers if compile cannot finish here:

1. Rust 1.94.1 missing until `rustup` updates the toolchain
2. `npm run init` downloading the Firefox source (large, network)
3. Full `surfer build` / `mach` compile time and missing native deps
   (clang, nasm, gtk, etc.)
