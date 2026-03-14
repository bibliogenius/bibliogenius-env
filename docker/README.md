# Docker - BiblioGenius

Docker Compose services for development, testing, and local infrastructure.

## Services

| Service | Description | Port |
|---------|-------------|------|
| `bibliogenius` | Rust backend (standalone server) | 8001 |
| `hub` | Symfony hub (registry, discovery, relay) | 8081 |
| `builder` | Rust dependency cache builder | — |
| `linux-app` | Flutter Linux bundle (headless, API, or VNC) | 8042, 6080 |

## Quick start

```bash
cd docker

# Start backend + hub
docker compose up bibliogenius hub

# Run P2P verification
./verify_p2p.sh
```

## Testing the Linux bundle

The `linux-app` service runs the Flutter Linux release bundle inside an Ubuntu container with a virtual display (Xvfb). This lets you verify the build works on Linux without a Linux machine.

### Setup (one-time)

```bash
# Download the latest Linux bundle from GitHub Releases
./download-linux-bundle.sh

# Build the Docker image
docker compose build linux-app
```

To download a specific version: `./download-linux-bundle.sh v0.8.6`

### Smoke test (headless)

```bash
docker compose run --rm linux-app smoke
```

Starts the app, waits 5 seconds, and exits with 0 if the app is still running.

### API verification

```bash
# Start the app in serve mode (keeps running)
docker compose run --rm -d --service-ports linux-app

# Run the verification script
./verify_linux.sh

# Stop when done
docker compose stop
```

### GUI testing (VNC via browser)

```bash
docker compose run --rm --service-ports linux-app vnc
```

Then open http://localhost:6080/vnc.html in your browser. Click "Connect" to see the Linux desktop with the app running.

### Notes

- The Linux bundle is auto-downloaded by `download-linux-bundle.sh` into `_ressources/bundle/`
- The container runs as `linux/amd64` — on Apple Silicon, it uses Rosetta emulation
- On first VNC launch, the keyring may prompt for a password — leave it empty and confirm
- Rosetta emulation may cause issues with password hashing (Argon2); this does not affect real Linux hosts
