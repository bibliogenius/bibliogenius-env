#!/bin/bash
set -e

MODE="${1:-serve}"

# Resolve what to launch. Two layouts are supported:
#   1. Extracted Flutter bundle: /app/app + lib/ + data/ (legacy bundle test).
#   2. A packaged AppImage mounted under /app (e.g. the dist/ dir).
#
# For the AppImage we prefer native execution (APPIMAGE_EXTRACT_AND_RUN avoids
# the FUSE requirement). On a real x86_64 Linux host that just works. Under
# Docker's amd64 emulation on Apple Silicon, the static-pie type-2 runtime cannot
# be exec'd ("Exec format error"), so we fall back to extracting the AppImage's
# squashfs payload with unsquashfs and running its AppRun directly. Both paths run
# the bytes from the actual shipped .AppImage.
if [ -f /app/app ]; then
  APP_TARGET=/app/app
else
  APPIMAGE="$(ls /app/*.AppImage 2>/dev/null | head -n1 || true)"
  if [ -n "$APPIMAGE" ]; then
    chmod +x "$APPIMAGE" 2>/dev/null || true
    export TMPDIR=/tmp
    if APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGE" --appimage-offset >/dev/null 2>&1; then
      echo "ℹ️  Launching AppImage natively: $APPIMAGE (extract-and-run, no FUSE)"
      export APPIMAGE_EXTRACT_AND_RUN=1
      APP_TARGET="$APPIMAGE"
    else
      echo "ℹ️  Native AppImage exec unavailable (emulation); extracting payload..."
      # The squashfs payload begins right after the runtime ELF, i.e. at the end
      # of its section-header table. Compute that from the 64-bit ELF header
      # (e_shoff @0x28 8B, e_shentsize @0x3A 2B, e_shnum @0x3C 2B, all LE) exactly
      # as `--appimage-offset` does. A plain "hsqs" magic search is NOT safe: the
      # bytes appear inside the runtime ELF too, before the real payload.
      le() { off=0 mul=1; for b in $(od -An -tu1 -j "$2" -N "$3" "$1"); do off=$((off+b*mul)); mul=$((mul*256)); done; echo "$off"; }
      shoff=$(le "$APPIMAGE" 40 8)
      ent=$(le "$APPIMAGE" 58 2)
      num=$(le "$APPIMAGE" 60 2)
      OFFSET=$((shoff + ent*num))
      if [ "$(dd if="$APPIMAGE" bs=1 skip="$OFFSET" count=4 2>/dev/null)" != "hsqs" ]; then
        echo "❌ Computed payload offset $OFFSET is not a squashfs superblock"
        exit 1
      fi
      rm -rf /tmp/appimage-root
      unsquashfs -f -d /tmp/appimage-root -o "$OFFSET" "$APPIMAGE" >/dev/null
      APP_TARGET=/tmp/appimage-root/AppRun
      echo "ℹ️  Extracted to /tmp/appimage-root (offset $OFFSET)"
    fi
  fi
fi

if [ -z "${APP_TARGET:-}" ] || { [ "$APP_TARGET" != "/app/app" ] && [ ! -f "$APP_TARGET" ]; }; then
  echo "❌ Neither a Flutter bundle (/app/app) nor an *.AppImage found in /app/"
  echo ""
  echo "Download a bundle:    cd docker && ./download-linux-bundle.sh"
  echo "Or mount dist/ (with BiblioGenius-Linux-x64.AppImage) at /app."
  exit 1
fi

# Start virtual display
Xvfb :99 -screen 0 1280x720x24 -nolisten tcp &
sleep 2
export DISPLAY=:99

echo "=== BiblioGenius Linux App ==="

# Wrapper to start app inside a proper D-Bus session with gnome-keyring
run_app() {
  dbus-run-session -- sh -c '
    # Create default keyring with empty password and unlock it
    eval $(echo -n "" | gnome-keyring-daemon --start --unlock --components=secrets 2>/dev/null)
    export GNOME_KEYRING_CONTROL SSH_AUTH_SOCK
    # Create the "default" collection via secret-tool (avoids SystemPrompter dialog)
    echo -n "" | secret-tool store --label="init" init init 2>/dev/null || true
    exec "$@"
  ' _ "$@"
}

case "$MODE" in
  smoke)
    echo "Mode: smoke test"
    run_app "$APP_TARGET" 2>&1 &
    APP_PID=$!
    sleep 5
    if kill -0 $APP_PID 2>/dev/null; then
      echo "✅ App launched successfully (PID $APP_PID running)"
      kill $APP_PID 2>/dev/null || true
      exit 0
    else
      wait $APP_PID 2>/dev/null
      EXIT_CODE=$?
      echo "❌ App exited with code $EXIT_CODE"
      exit $EXIT_CODE
    fi
    ;;

  vnc)
    echo "Mode: VNC (open http://localhost:6080 in your browser)"

    fluxbox &
    sleep 1

    x11vnc -display :99 -nopw -shared -forever -rfbport 5900 &
    sleep 1

    websockify --web /usr/share/novnc 6080 localhost:5900 &
    sleep 1

    echo "✅ VNC ready — open http://localhost:6080/vnc.html"
    echo "Starting BiblioGenius..."

    run_app "$APP_TARGET" 2>&1 &
    wait
    ;;

  *)
    echo "Mode: serve (backend available on exposed port)"
    run_app "$APP_TARGET" 2>&1 &
    wait
    ;;
esac
