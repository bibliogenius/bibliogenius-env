#!/usr/bin/env bash
# Compile the Rust backend + Flutter Linux bundle and emit the release tarball.
# Runs INSIDE the linux/amd64 build container (see Dockerfile.linux-build).
# Repos are bind-mounted as siblings under /src; the tarball lands in /out.
set -euo pipefail

RUST_SRC=/src/bibliogenius
APP_SRC=/src/bibliogenius-app
TARGET=x86_64-unknown-linux-gnu
TARBALL=/out/BiblioGenius-Linux-x64.tar.gz

echo "==> Building Rust backend ($TARGET)..."
cargo build --release --manifest-path "$RUST_SRC/Cargo.toml" \
    --target "$TARGET" --bin bibliogenius

echo "==> Building Flutter Linux release..."
cd "$APP_SRC"
# .env ships as a PUBLIC Flutter asset (pubspec: assets: - .env). Bundle the
# committed .env.example, never the developer's local .env (which may enable
# SHOW_DEV_TOOLS or point at dev hosts). .env.example is release-safe: in
# kReleaseMode the app defaults HUB_URL to the prod hub and keeps dev tools off
# when the keys are absent (see ApiService.hubUrl). The host .env is restored
# afterwards so the mounted dev checkout is left untouched.
RELEASE_ENV=".env.example"
if [ ! -f "$RELEASE_ENV" ]; then
    echo "❌ $APP_SRC/$RELEASE_ENV is missing — required for a public release build." >&2
    exit 1
fi
restore_host_env() {
    if [ -f "$APP_SRC/.env.host-bak" ]; then
        mv -f "$APP_SRC/.env.host-bak" "$APP_SRC/.env"
    else
        rm -f "$APP_SRC/.env"
    fi
}
# Self-heal: if a previous run was hard-killed (SIGKILL) before restoring, its
# backup is still the real dev .env — recover it before taking a new snapshot,
# so we never overwrite the backup with the swapped-in release config.
[ -f .env.host-bak ] && mv -f .env.host-bak .env
# Restore on any exit, incl. Ctrl-C / `docker stop` (SIGTERM). Only SIGKILL can
# bypass this, and then .env.host-bak remains for manual recovery.
trap restore_host_env EXIT INT TERM
[ -f .env ] && cp .env .env.host-bak
cp "$RELEASE_ENV" .env

flutter pub get
flutter build linux --release

echo "==> Injecting backend binary into bundle..."
BUNDLE="build/linux/x64/release/bundle"
mkdir -p "$BUNDLE/backend"
cp "$RUST_SRC/target/$TARGET/release/bibliogenius" "$BUNDLE/backend/bibliogenius"
chmod +x "$BUNDLE/backend/bibliogenius"

echo "==> Creating tarball..."
mkdir -p /out
tar -C build/linux/x64/release -czf "$TARBALL" bundle

echo "✅ $TARBALL"
