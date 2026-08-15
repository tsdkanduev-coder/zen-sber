#!/usr/bin/env bash
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Official Zen Sber build wrapper.
# Same steps as https://docs.zen-browser.app/contribute/desktop/building
# Do not clone an extra Firefox tree; Surfer downloads it into engine/.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

LOG="${SBER_BUILD_LOG:-$ROOT/docs/sber-build-run.log}"
mkdir -p "$(dirname "$LOG")"

log() {
  printf '%s\n' "$*" | tee -a "$LOG"
}

run_step() {
  local title="$1"
  shift
  log ""
  log "=== ${title} ==="
  log "\$ $*"
  log "started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if "$@"; then
    log "ok: ${title} ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
  else
    local code=$?
    log "FAILED: ${title} exit=${code} ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
    log "cwd: ${ROOT}"
    exit "$code"
  fi
}

log "Zen Sber official build — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "root: ${ROOT}"
log "node: $(node -v 2>/dev/null || echo missing)"
log "python: $(python3 --version 2>/dev/null || echo missing)"
log "rustc: $(rustc --version 2>/dev/null || echo missing)"
log "required rust: $(cat "${ROOT}/.rust-toolchain" 2>/dev/null || echo unknown)"

if command -v rustup >/dev/null 2>&1; then
  run_step "rustup toolchain (from .rust-toolchain)" rustup show
else
  log "note: rustup not found; install Rust 1.94.1 before a full compile"
fi

if ! command -v sccache >/dev/null 2>&1; then
  log "note: sccache not installed (recommended by official docs, not required)"
fi

run_step "npm i" npm i
run_step "npm run init (download + import + bootstrap)" npm run init
run_step "update en-US language packs" python3 ./scripts/update_en_US_packs.py
run_step "npm run build" npm run build

log ""
log "Build finished. Next: npm start"
log "Look for artifacts under engine/obj-*/dist/ and any Surfer package output."
