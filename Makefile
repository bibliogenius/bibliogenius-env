.PHONY: help setup install-all install-hub install-bundle install-rust start stop logs app app-chrome version version-app show-version release cargo-lock push-release check-migration ship ship-ios ship-mac ship-android sideload-apk build-linux ship-linux ship-windows

# Colors
YELLOW := \033[1;33m
GREEN := \033[1;32m
CYAN := \033[1;36m
BLUE := \033[1;34m
RESET := \033[0m

# Default target
help:
	@echo "$(BLUE)📚 BiblioGenius Ecosystem Makefile$(RESET)"
	@echo "$(BLUE)-----------------------------$(RESET)"
	@echo ""
	@echo "$(YELLOW)Available commands:$(RESET)"
	@echo ""
	@echo "$(CYAN)📦 Installation & Setup:$(RESET)"
	@echo "  $(GREEN)make setup P=<profile>$(RESET): Setup or switch profile (no-code / junior / senior)"
	@echo "  $(GREEN)make install-all$(RESET)    : Install dependencies for all components"
	@echo "  $(GREEN)make install-hub$(RESET)    : Install Composer dependencies for Symfony Hub"
	@echo "  $(GREEN)make install-bundle$(RESET) : Install Composer dependencies for Symfony Bundle"
	@echo "  $(GREEN)make install-rust$(RESET)   : Fetch Cargo dependencies for Rust Server"
	@echo ""
	@echo "$(CYAN)🚀 Runtime:$(RESET)"
	@echo "  $(GREEN)make start          $(RESET): Start the Docker environment (Hub + Rust Server)"
	@echo "  $(GREEN)make stop           $(RESET): Stop the Docker environment"
	@echo "  $(GREEN)make logs           $(RESET): View Docker logs"
	@echo ""
	@echo "$(CYAN)🧪 Testing & Dev:$(RESET)"
	@echo "  $(GREEN)make test-poc       $(RESET): Run the POC verification script"
	@echo "  $(GREEN)make app            $(RESET): Build and run the Flutter macOS app"

	@echo ""
	@echo "$(CYAN)📄 Documentation:$(RESET)"
	@echo "  $(GREEN)make push-docs      $(RESET): Commit and push documentation updates"
	@echo "  $(GREEN)make docs-index     $(RESET): Generate documentation index (INDEX.md)"
	@echo ""
	@echo "$(CYAN)🍎 Distribution:$(RESET)"
	@echo "  $(GREEN)make backend        $(RESET): Build Rust backend (bundle-macos without Flutter build)"
	@echo "  $(GREEN)make bundle-macos   $(RESET): Bundle Rust backend and build macOS app (Standalone)"
	@echo "  $(GREEN)make sideload-apk   $(RESET): Build signed release APK + verify prod signature (one-off sideload)"
	@echo "  $(GREEN)make test           $(RESET): Run all tests (Rust + Flutter)"
	@echo ""
	@echo "$(CYAN)🐧 Linux desktop (self-hosted, no store):$(RESET)"
	@echo "  $(GREEN)make build-linux    $(RESET): Build BiblioGenius-Linux-x64.AppImage from Mac via Docker (linux/amd64)"
	@echo "  $(GREEN)make ship-linux     $(RESET): rsync the AppImage + SHA256 to the VPS downloads/ (run manually after build)"
	@echo "  $(GREEN)make ship-windows   $(RESET): rsync BiblioGenius-Setup.exe (from GitHub artifact, placed in dist/) + SHA256 to the VPS"
	@echo ""
	@echo "$(CYAN)🏷️  Versioning & Release:$(RESET)"
	@echo "  $(GREEN)make release V=x.y.z$(RESET): Bump app version + Cargo.lock + commit + push + git tag"
	@echo "  $(GREEN)make version V=x.y.z$(RESET): Sync version across ALL files (adds hub + website)"
	@echo "  $(GREEN)make show-version   $(RESET): Show current version across all components"
	@echo ""
	@echo "$(CYAN)🚢 Ship to stores (fastlane):$(RESET)"
	@echo "  $(GREEN)make check-migration$(RESET): Replay all DB migrations on a copy of a real library (auto-runs before ship*)"
	@echo "  $(GREEN)make ship           $(RESET): Build & upload iOS + macOS + Android"
	@echo "  $(GREEN)make ship-ios       $(RESET): Build & upload iOS only"
	@echo "  $(GREEN)make ship-mac       $(RESET): Build & upload macOS only"
	@echo "  $(GREEN)make ship-android   $(RESET): Build & upload Android only"
	@echo ""
	@echo "  $(YELLOW)Full release procedure: see RELEASING.md$(RESET)"
	@echo ""

# =============================================================================
# ONBOARDING & PROFILE SWITCHING
# =============================================================================
# Usage: make setup P=no-code    (initial setup or switch to no-code)
#        make setup P=junior     (initial setup or switch to junior)
#        make setup P=senior     (initial setup or switch to senior)
# Re-running with a different profile clones missing repos and adjusts hooks.
setup:
ifndef P
	@echo "$(YELLOW)Usage: make setup P=<profile>$(RESET)"
	@echo "  Profiles: no-code, junior, senior"
	@exit 1
endif
	@python3 setup.py $(P)

# =============================================================================
# VERSIONING & RELEASE
# =============================================================================
# make release V=x.y.z : bump app version + Cargo.lock + commit + push + git tag
#                        (bibliogenius + bibliogenius-app only)
# make version V=x.y.z : same bump, extended to hub + website files, no commit
#                        (rare full resync)

# Bumps the version in the app-coupled files only.
version-app:
ifndef V
	@echo "$(YELLOW)⚠️  Usage: make release V=1.0.0-beta.2$(RESET)"
	@exit 1
endif
	@echo "$(CYAN)🏷️  Updating app version to $(V)...$(RESET)"
	@sed -i '' 's/^version = ".*"/version = "$(V)"/' bibliogenius/Cargo.toml
	$(eval BUILD := $(shell grep '^version: ' bibliogenius-app/pubspec.yaml | sed 's/.*+//'))
	$(eval NEXT_BUILD := $(shell echo $$(( $(BUILD) + 1 ))))
	@sed -i '' 's/^version: .*/version: $(V)+$(NEXT_BUILD)/' bibliogenius-app/pubspec.yaml
	@sed -i '' 's/\*\*Status\*\*: v.*/\*\*Status\*\*: v$(V) (Beta Testing)/' README.md
	@echo "$(GREEN)✅ Version $(V) set: Cargo.toml, pubspec.yaml (build $(NEXT_BUILD)), README.md$(RESET)"

# Extends version-app to the independently-deployed hub + website files.
version: version-app
	@sed -i '' 's/"version": ".*"/"version": "$(V)"/' bibliogenius-hub/composer.json
	@echo '$(V)' > bibliogenius-website/_build/version.txt
	@echo "$(GREEN)✅ Also synced: bibliogenius-hub/composer.json, bibliogenius-website/_build/version.txt$(RESET)"

release: version-app cargo-lock push-release

cargo-lock:
	@echo "$(CYAN)🔒 Updating Cargo.lock...$(RESET)"
	@cd bibliogenius && cargo update --workspace

push-release:
	@echo "$(CYAN)📤 Committing, pushing and tagging version $(V)...$(RESET)"
	@cd bibliogenius && git add Cargo.toml Cargo.lock && (git diff --cached --quiet || git commit -m "update to version $(V)") && git push
	@cd bibliogenius-app && git add pubspec.yaml && (git diff --cached --quiet || git commit -m "update to version $(V)") && git push
	@git add README.md && (git diff --cached --quiet || git commit -m "update to version $(V)") && git push
	@cd bibliogenius && if git rev-parse "v$(V)" >/dev/null 2>&1; then echo "  bibliogenius: tag v$(V) déjà présent, ignoré"; else git tag -a "v$(V)" -m "Release v$(V)" && git push origin "v$(V)"; fi
	@cd bibliogenius-app && if git rev-parse "v$(V)" >/dev/null 2>&1; then echo "  bibliogenius-app: tag v$(V) déjà présent, ignoré"; else git tag -a "v$(V)" -m "Release v$(V)" && git push origin "v$(V)"; fi
	@echo "$(GREEN)✅ Version $(V) committed, pushed and tagged (bibliogenius + bibliogenius-app).$(RESET)"

show-version:
	@echo "$(CYAN)📦 Current versions:$(RESET)"
	@echo "   Rust:    $$(grep '^version = ' bibliogenius/Cargo.toml | head -1)"
	@echo "   Flutter: $$(grep '^version: ' bibliogenius-app/pubspec.yaml)"
	@echo "   Hub:     $$(grep '\"version\"' bibliogenius-hub/composer.json 2>/dev/null || echo '(not set)')"
	@echo "   README:  $$(grep '^\*\*Status\*\*' README.md)"

# =============================================================================
# SHIP — build & upload to the stores via fastlane
# =============================================================================
# fastlane runs without `bundle exec` (see Fastfile header). ~30 min for all 3.

# Pre-ship gate: replay the FULL migration chain on a copy of a real old-schema
# library. Migrations that pass on clean dev databases can still brick real
# devices — 1.1.0-beta failed `foreign_key_check` on the by-design
# `peer_books.peer_id = 0` directory-cache sentinels and made init fail on
# every launch. The test only copies the source file, never writes to it.
# Override the source with REAL_DB=/path/to/old-library.db.
REAL_DB ?= $(PWD)/bibliogenius.db

check-migration:
	@echo "$(CYAN)🧬 Replaying migrations on a real library copy ($(REAL_DB))...$(RESET)"
	@test -f "$(REAL_DB)" || { echo "$(YELLOW)REAL_DB not found: $(REAL_DB) — point REAL_DB at an old-schema library file$(RESET)"; exit 1; }
	@cd bibliogenius && WS2_REAL_DB="$(REAL_DB)" cargo test --test uuid_pk_migration_prototype real_library_copy -- --nocapture
	@echo "$(GREEN)✅ Real-library migration replay passed.$(RESET)"

ship-ios: check-migration
	@cd bibliogenius-app && fastlane ios upload

ship-mac: check-migration
	@cd bibliogenius-app && fastlane mac upload

ship-android: check-migration
	@cd bibliogenius-app && fastlane android upload

# Builds & uploads all 3 platforms in series. Continues past a failing
# platform, prints a summary, exits non-zero if any platform failed.
ship: check-migration
	@cd bibliogenius-app && { \
	ios=KO; mac=KO; android=KO; \
	echo "$(CYAN)=== iOS ===$(RESET)"; fastlane ios upload && ios=OK; \
	echo "$(CYAN)=== macOS ===$(RESET)"; fastlane mac upload && mac=OK; \
	echo "$(CYAN)=== Android ===$(RESET)"; fastlane android upload && android=OK; \
	echo ""; echo "$(YELLOW)=== ship summary ===$(RESET)"; \
	echo "  iOS:     $$ios"; echo "  macOS:   $$mac"; echo "  Android: $$android"; \
	[ "$$ios" = OK ] && [ "$$mac" = OK ] && [ "$$android" = OK ]; \
	}

test:
	@echo "$(CYAN)🧪 Running all tests...$(RESET)"
	@echo "$(YELLOW)Running Rust tests...$(RESET)"
	cd bibliogenius && cargo test --quiet
	@echo "$(YELLOW)Running Flutter tests...$(RESET)"
	cd bibliogenius-app && flutter test --reporter compact
	@echo "$(GREEN)✅ All tests passed!$(RESET)"

check-rust:
	@echo "$(CYAN)Running Rust post-dev checks (fmt + clippy + test)...$(RESET)"
	cd bibliogenius && cargo fmt && cargo clippy -- -D warnings && cargo test
	@echo "$(GREEN)✅ Rust checks passed!$(RESET)"

test-rust:
	@echo "$(YELLOW)Running Rust tests...$(RESET)"
	cd bibliogenius && cargo test

test-flutter:
	@echo "$(YELLOW)Running Flutter tests...$(RESET)"
	cd bibliogenius-app && flutter test

docs-index:
	@echo "Generating documentation index..."
	@docker-compose -f docker/docker-compose.yml run --rm -v $(PWD)/bibliogenius-docs:/app/bibliogenius-docs hub php /app/bibliogenius-docs/scripts/generate_docs_index.php

backend:
	@echo "Building Rust backend for macOS..."
	cd bibliogenius-app && chmod +x macos/build_backend.sh && ./macos/build_backend.sh

bundle-macos:
	@echo "Bundling backend and building macOS app..."
	cd bibliogenius-app && chmod +x macos/build_backend.sh && ./macos/build_backend.sh
	cd bibliogenius-app && flutter build macos --release
	@echo "📦 Injecting backend into app bundle..."
	mkdir -p bibliogenius-app/build/macos/Build/Products/Release/app.app/Contents/Resources/backend
	cp bibliogenius-app/macos/Runner/Resources/backend/bibliogenius bibliogenius-app/build/macos/Build/Products/Release/app.app/Contents/Resources/backend/
	chmod +x bibliogenius-app/build/macos/Build/Products/Release/app.app/Contents/Resources/backend/bibliogenius
	@echo "✅ App bundled at bibliogenius-app/build/macos/Build/Products/Release/app.app"

# Build a signed release APK for a one-off sideload, and verify it is signed
# with the production key (guards against accidentally shipping a debug build).
sideload-apk:
	@echo "$(CYAN)📦 Building signed release APK...$(RESET)"
	cd bibliogenius-app && flutter build apk --release
	@APK="bibliogenius-app/build/app/outputs/flutter-apk/app-release.apk"; \
	SDK="$${ANDROID_HOME:-$${ANDROID_SDK_ROOT:-$$HOME/Library/Android/sdk}}"; \
	SIGNER=$$(ls "$$SDK"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1); \
	echo "$(CYAN)🔏 Verifying signature...$(RESET)"; \
	if [ -z "$$SIGNER" ]; then \
		echo "$(YELLOW)⚠️  apksigner introuvable sous $$SDK/build-tools — vérif sautée$(RESET)"; \
	else \
		"$$SIGNER" verify --print-certs "$$APK" || exit 1; \
	fi; \
	echo "$(GREEN)✅ APK prêt: $$APK$(RESET)"

# =============================================================================
# LINUX DESKTOP — self-hosted distribution (no store, no fastlane)
# =============================================================================
# Reproducible Linux x64 build from the Mac via Docker (qemu emulation), then a
# manual rsync to the VPS. Stable URLs, overwritten each release:
#   https://bibliogenius.org/downloads/BiblioGenius-Linux-x64.AppImage
#   https://bibliogenius.org/downloads/BiblioGenius-Linux-x64.AppImage.sha256
LINUX_BUILD_IMAGE := bibliogenius-linux-build:22.04
LINUX_APPIMAGE    := BiblioGenius-Linux-x64.AppImage
WINDOWS_INSTALLER := BiblioGenius-Setup.exe
DIST_DIR          := dist
SHIP_HOST         ?= hub-vps
SHIP_PATH         ?= /var/www/bibliogenius.org/downloads/

# Build the toolchain image (cached) then compile inside it with both repos
# bind-mounted as siblings. Slow on first run (qemu + Flutter precache).
build-linux:
	@echo "$(CYAN)🐧 Building Linux x64 toolchain image (linux/amd64)...$(RESET)"
	docker buildx build --platform linux/amd64 --load \
		-t $(LINUX_BUILD_IMAGE) -f docker/Dockerfile.linux-build docker
	@mkdir -p $(DIST_DIR)
	@echo "$(CYAN)🏗️  Compiling backend + Flutter Linux bundle...$(RESET)"
	docker run --rm --platform linux/amd64 \
		-v $(PWD)/bibliogenius:/src/bibliogenius \
		-v $(PWD)/bibliogenius-app:/src/bibliogenius-app \
		-v $(PWD)/$(DIST_DIR):/out \
		$(LINUX_BUILD_IMAGE)
	@echo "$(GREEN)✅ $(DIST_DIR)/$(LINUX_APPIMAGE) (+ .sha256)$(RESET)"

# rsync WITHOUT --delete so the site's `make deploy` (which uses --delete) never
# competes with it. Run manually — reuses your existing SSH access, no CI secret.
# Ships the AppImage + its SHA256 sidecar.
ship-linux:
	@test -f $(DIST_DIR)/$(LINUX_APPIMAGE) || { echo "$(YELLOW)⚠️  Run 'make build-linux' first$(RESET)"; exit 1; }
	@echo "$(CYAN)🚀 Shipping $(LINUX_APPIMAGE) → $(SHIP_HOST):$(SHIP_PATH)$(RESET)"
	rsync -avz --rsync-path="mkdir -p $(SHIP_PATH) && rsync" \
		$(DIST_DIR)/$(LINUX_APPIMAGE) $(DIST_DIR)/$(LINUX_APPIMAGE).sha256 \
		$(SHIP_HOST):$(SHIP_PATH)
	@echo "$(GREEN)✅ https://bibliogenius.org/downloads/$(LINUX_APPIMAGE)$(RESET)"

# Ship the Windows installer. Unlike Linux, the .exe is built on GitHub Actions
# (no cross-compile from Mac): download the `bibliogenius-windows` run artifact,
# unzip it, drop BiblioGenius-Setup.exe into dist/, then run this. The SHA256 is
# generated here since the file comes from outside the build pipeline.
ship-windows:
	@test -f $(DIST_DIR)/$(WINDOWS_INSTALLER) || { echo "$(YELLOW)⚠️  Place $(WINDOWS_INSTALLER) in $(DIST_DIR)/ first (from the GitHub Actions artifact)$(RESET)"; exit 1; }
	@cd $(DIST_DIR) && shasum -a 256 $(WINDOWS_INSTALLER) > $(WINDOWS_INSTALLER).sha256
	@echo "$(CYAN)🚀 Shipping $(WINDOWS_INSTALLER) → $(SHIP_HOST):$(SHIP_PATH)$(RESET)"
	rsync -avz --rsync-path="mkdir -p $(SHIP_PATH) && rsync" \
		$(DIST_DIR)/$(WINDOWS_INSTALLER) $(DIST_DIR)/$(WINDOWS_INSTALLER).sha256 \
		$(SHIP_HOST):$(SHIP_PATH)
	@echo "$(GREEN)✅ https://bibliogenius.org/downloads/$(WINDOWS_INSTALLER)$(RESET)"

app:
	@echo "Building and running Flutter macOS app..."
	cd bibliogenius-app && flutter build macos --release && open build/macos/Build/Products/Release/app.app

push-docs:
	@echo "Pushing documentation updates..."
	@cd bibliogenius-docs && \
	if [ ! -f .version ]; then echo 0 > .version; fi && \
	VERSION=$$(cat .version) && \
	NEXT_VERSION=$$((VERSION + 1)) && \
	echo $$NEXT_VERSION > .version && \
	git add . && \
	git commit -m "Update $$NEXT_VERSION" && \
	git push

install-all: install-hub install-bundle install-rust

install-hub:
	@echo "Installing dependencies for bibliogenius-hub..."
	docker-compose -f docker/docker-compose.yml run --rm hub composer install

install-bundle:
	@echo "Installing dependencies for bibliogenius-bundle..."
	docker-compose -f docker/docker-compose.yml run --rm hub composer install

install-rust:
	@echo "Fetching dependencies for bibliogenius (Rust)..."
	docker-compose -f docker/docker-compose.yml run --rm builder

install-minimal: install-rust
	@echo "Minimal installation complete."

install-demo: install-rust
	@echo "Installing demo data..."
	docker-compose -f docker/docker-compose.yml run --rm -e SEED_DEMO=true bibliogenius /app/bibliogenius

start:
	@echo "Starting Docker environment..."
	cd docker && docker-compose up -d

rebuild:
	@echo "Rebuilding Docker environment..."
	cd docker && docker-compose build bibliogenius hub && docker-compose up -d

stop:
	@echo "Stopping Docker environment..."
	cd docker && docker-compose down

logs:
	cd docker && docker-compose logs -f

test-poc:
	cd docker && ./test-poc.sh
