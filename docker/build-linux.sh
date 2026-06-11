#!/usr/bin/env bash
# Compile the Rust backend + Flutter Linux bundle and emit the AppImage.
# Runs INSIDE the linux/amd64 build container (see Dockerfile.linux-build).
# Repos are bind-mounted as siblings under /src; the artifact lands in /out.
#
# Single deliverable: BiblioGenius-Linux-x64.AppImage (self-contained, one file).
set -euo pipefail

RUST_SRC=/src/bibliogenius
APP_SRC=/src/bibliogenius-app
TARGET=x86_64-unknown-linux-gnu
APPIMAGE=/out/BiblioGenius-Linux-x64.AppImage
# App icon reused from the macOS asset catalogue (512x512 PNG, RGBA).
ICON_SRC="$APP_SRC/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png"

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

mkdir -p /out

# ---------------------------------------------------------------------------
# AppImage packaging
# ---------------------------------------------------------------------------
# Build an AppDir from the Flutter bundle and pack it with appimagetool. We keep
# the SAME runtime-dependency model as the tarball: the app links against the
# HOST's GTK/X11/glibc (built on Ubuntu 22.04 for broad compatibility), so we do
# NOT use linuxdeploy (which would bundle system libs). appimagetool merely wraps
# the existing bundle in a self-mounting single file.
echo "==> Building AppDir..."
APPDIR=build/linux/x64/release/BiblioGenius.AppDir
rm -rf "$APPDIR"
mkdir -p "$APPDIR"
# Copy the whole bundle flat into the AppDir root so the Flutter executable, its
# lib/ (engine + librust_lib_app.so), data/ (assets) and the injected
# backend/bibliogenius all sit side by side. Flutter resolves these relative to
# the real executable path (/proc/self/exe), which points inside the mounted
# AppImage at runtime, so the layout must be preserved verbatim.
cp -a "$BUNDLE/." "$APPDIR/"

# AppRun: resolve the AppDir from the script's own real path (the AppImage mounts
# at a random dir), then exec the Flutter app from there. Setting cwd + PATH +
# LD_LIBRARY_PATH makes lib/ and backend/bibliogenius resolvable however they are
# reached (rpath already points at $ORIGIN/lib; this is belt-and-suspenders).
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/lib:${LD_LIBRARY_PATH:-}"
export PATH="$HERE/backend:$HERE:$PATH"
cd "$HERE"
exec "$HERE/app" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# Desktop entry (validated by appimagetool via desktop-file-validate).
cat > "$APPDIR/bibliogenius.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=BiblioGenius
Comment=Personal library management
Exec=app
Icon=bibliogenius
Categories=Office;Utility;
Terminal=false
EOF

# Icon at AppDir root (must match the Icon= key) plus the .DirIcon thumbnail.
if [ ! -f "$ICON_SRC" ]; then
    echo "❌ App icon not found at $ICON_SRC" >&2
    exit 1
fi
cp "$ICON_SRC" "$APPDIR/bibliogenius.png"
cp "$ICON_SRC" "$APPDIR/.DirIcon"

echo "==> Validating desktop entry..."
desktop-file-validate "$APPDIR/bibliogenius.desktop"

echo "==> Packaging AppImage (mksquashfs + runtime, no exec)..."
# A type-2 AppImage = [runtime ELF][squashfs payload]. mksquashfs builds the
# payload from the AppDir; the runtime (with its AI\x02 magic at offset 8 and
# squashfuse) is concatenated in front. This is exactly what appimagetool does
# internally, minus executing a static-pie binary that the build emulation can't
# run. Default gzip compression keeps the widest squashfuse compatibility.
RUNTIME=/opt/appimage-runtime
SQUASHFS=/tmp/bibliogenius.squashfs
rm -f "$SQUASHFS"
mksquashfs "$APPDIR" "$SQUASHFS" -root-owned -noappend -no-progress
cat "$RUNTIME" "$SQUASHFS" > "$APPIMAGE"
chmod +x "$APPIMAGE"
rm -f "$SQUASHFS"

echo "==> Self-checking AppImage payload..."
# Read the payload straight out of the shipped file (offset = runtime size, known
# exactly here) and confirm the key pieces packed correctly. No exec, no FUSE.
RUNTIME_SIZE=$(stat -c%s "$RUNTIME")
LISTING=$(unsquashfs -l -o "$RUNTIME_SIZE" "$APPIMAGE")
for required in squashfs-root/AppRun squashfs-root/app \
                squashfs-root/backend/bibliogenius squashfs-root/bibliogenius.desktop; do
    if ! echo "$LISTING" | grep -qx "$required"; then
        echo "❌ AppImage payload is missing $required" >&2
        exit 1
    fi
done
echo "   ✅ payload intact (AppRun + app + backend + .desktop present)"

echo "==> Writing SHA256 checksum..."
( cd /out && sha256sum "$(basename "$APPIMAGE")" > "$(basename "$APPIMAGE").sha256" )

echo "✅ $APPIMAGE"
echo "✅ $APPIMAGE.sha256"
cat "$APPIMAGE.sha256"
