#!/bin/bash
set -e

MODE="${1:-serve}"

# Check that the bundle is present
if [ ! -f /app/app ]; then
  echo "❌ Linux bundle not found at /app/"
  echo ""
  echo "Download it first:"
  echo "  cd docker && ./download-linux-bundle.sh"
  echo ""
  echo "Or manually place a Flutter Linux bundle in _ressources/bundle/"
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
    run_app /app/app 2>&1 &
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

    run_app /app/app 2>&1 &
    wait
    ;;

  *)
    echo "Mode: serve (backend available on exposed port)"
    run_app /app/app 2>&1 &
    wait
    ;;
esac
