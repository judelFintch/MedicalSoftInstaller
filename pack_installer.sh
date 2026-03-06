#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n==> %s\n" "$1"; }

if ! command -v makeself >/dev/null 2>&1; then
  echo "makeself is required to build the .run installer." >&2
  echo "Install it with: sudo apt install -y makeself" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT_DIR/dist/build"
OUT_DIR="$ROOT_DIR/dist"
OUT_FILE="$OUT_DIR/medicalsoft-installer.run"

log "Preparing build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUT_DIR"

log "Copying installer files"
cp "$ROOT_DIR/install.sh" "$BUILD_DIR/"
cp "$ROOT_DIR/README.md" "$BUILD_DIR/"
cp "$ROOT_DIR/LICENSE" "$BUILD_DIR/" 2>/dev/null || true

log "Building self-extracting installer"
makeself --nox11 "$BUILD_DIR" "$OUT_FILE" "MedicalSoft Installer" ./install.sh

log "Done"
echo "Output: $OUT_FILE"
