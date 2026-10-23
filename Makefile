.PHONY: help setup install-all install-hub install-bundle install-rust start stop logs app app-chrome version version-app show-version release cargo-lock push-release check-migration check-release-env ship ship-ios ship-mac ship-android sideload-apk build-linux ship-linux ship-windows hub-dump hub-dump-open hub-dump-psql hub-dump-close

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
	@echo "  $(GREEN)make audit-curated  $(RESET): Audit the curated corpus against the sources (slow, network)"
	@echo "  $(GREEN)make audit-curated-offline$(RESET): Same, structural checks only"

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
	@echo "$(CYAN)🗄️  Hub database dump (encrypted, production data):$(RESET)"
	@echo "  $(GREEN)make hub-dump       $(RESET): Pull a fresh pg_dump over SSH into the encrypted image, keep only the latest"
	@echo "  $(GREEN)make hub-dump-open  $(RESET): Mount the encrypted image at /Volumes/hub-backup (grep-ready)"
	@echo "  $(GREEN)make hub-dump-psql  $(RESET): Load the dump into a throwaway tmpfs Postgres and open psql"
	@echo "  $(GREEN)make hub-dump-close $(RESET): Stop that Postgres, eject and compact the image"
	@echo ""
	@echo "$(CYAN)🏷️  Versioning & Release:$(RESET)"
	@echo "  $(GREEN)make release V=x.y.z$(RESET): Bump app version + Cargo.lock + commit + push + git tag"
	@echo "  $(GREEN)make version V=x.y.z$(RESET): Sync version across ALL files (adds hub + website)"
	@echo "  $(GREEN)make show-version   $(RESET): Show current version across all components"
	@echo ""
	@echo "$(CYAN)🚢 Ship to stores (fastlane):$(RESET)"
	@echo "  $(GREEN)make check-migration$(RESET): Replay all DB migrations on a copy of a real library (auto-runs before ship*)"
	@echo "  $(GREEN)make check-release-env$(RESET): Refuse to ship if bibliogenius-app/.env targets another hub than production (auto-runs before ship*)"
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

# Pre-ship gate: `bibliogenius-app/.env` is a bundled Flutter asset (pubspec
# `assets: - .env`) and a release build does NOT ignore it: `ApiService.hubUrl`
# returns `HUB_URL` whenever the key is set, and only falls back to the
# production hub when it is absent or empty. A `.env` left on staging after a
# recette would therefore ship to the stores. Absent file, commented or empty
# key = fine (release fallback is production). Only the `ship*` targets use
# this gate; `flutter run`, `flutter build` and `sideload-apk` are untouched.
# Prints nothing from the file but the offending HUB_URL value.
APP_ENV         ?= bibliogenius-app/.env
RELEASE_HUB_URL := https://hub.bibliogenius.org

check-release-env:
	@if [ -f "$(APP_ENV)" ]; then \
		hub=$$(grep -E '^[[:space:]]*(export[[:space:]]+)?HUB_URL[[:space:]]*=' "$(APP_ENV)" | tail -1 \
			| sed -E 's/^[^=]*=[[:space:]]*//; s/[[:space:]]+#.*$$//; s/[[:space:]]+$$//; s/^"(.*)"$$/\1/; s/^'"'"'(.*)'"'"'$$/\1/; s:/+$$::'); \
		if [ -n "$$hub" ] && [ "$$hub" != "$(RELEASE_HUB_URL)" ]; then \
			echo "$(YELLOW)⚠️  $(APP_ENV) is a bundled asset and HUB_URL=$$hub is not the production hub ($(RELEASE_HUB_URL)).$(RESET)"; \
			echo "$(YELLOW)   Point HUB_URL at production (or comment it out) before shipping.$(RESET)"; \
			exit 1; \
		fi; \
	fi
	@echo "$(GREEN)✅ Release env check passed: $(APP_ENV) targets production.$(RESET)"

# Independent E2EE account-sync health check (bg CLI, local unversioned
# tool in bibliogenius-web-poc/). Verifies from OUTSIDE the app that a
# brand-new device could recover the account's library from the hub.
sync-check:
	@test -d bibliogenius-web-poc || { echo "$(YELLOW)bibliogenius-web-poc/ not found on this machine (local tool)$(RESET)"; exit 1; }
	@$(MAKE) -C bibliogenius-web-poc check

ship-ios: check-release-env check-migration
	@cd bibliogenius-app && fastlane ios upload

ship-mac: check-release-env check-migration
	@cd bibliogenius-app && fastlane mac upload

ship-android: check-release-env check-migration
	@cd bibliogenius-app && fastlane android upload

# Builds & uploads all 3 platforms in series. Continues past a failing
# platform, prints a summary, exits non-zero if any platform failed.
ship: check-release-env check-migration
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

# Curated corpus audit (ADR-066 section 8b). Deliberately NOT part of `make
# test`: it walks hundreds of ISBNs across public catalogues that owe us
# nothing. Run it before promoting a list to `curation_status: reviewed`.
# Pass arguments through, e.g. `make audit-curated A="--list goncourt"`.
audit-curated:
	@echo "$(CYAN)🔍 Auditing the curated corpus against the sources...$(RESET)"
	@echo "$(YELLOW)Sequential and throttled; a full pass takes several minutes.$(RESET)"
	@echo "$(YELLOW)Export GOOGLE_BOOKS_API_KEY to avoid the keyless per-day quota.$(RESET)"
	cd bibliogenius-app && dart tools/audit_curated_lists.dart $(A)

audit-curated-offline:
	@echo "$(CYAN)🔍 Structural checks on the curated corpus (no network)...$(RESET)"
	cd bibliogenius-app && dart tools/audit_curated_lists.dart --offline $(A)

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

# =============================================================================
# HUB DATABASE DUMP - encrypted local copy of production data
# =============================================================================
# Hub dumps hold real user data (see .agents/instructions/policies.md, "Hub
# Backup Data Policy"). They never sit in clear on the Mac: pg_dump streams
# from the hub container over SSH straight into an encrypted APFS sparse
# bundle (AES-256, hdiutil, nothing to install). Plaintext exists only inside
# the mounted volume; `make hub-dump-close` locks it again.
# Retention: one dump, the latest (older ones inside the volume are removed).
# The volume passphrase lives in the macOS Keychain, same convention as the
# fastlane secrets. Create it once (prompts for the passphrase, nothing echoed):
#   security add-generic-password -s bg-hub-backup-image -a hub-backup -w
# Spotlight indexing is disabled on the volume (.metadata_never_index) so the
# dump content never lands in the Spotlight index outside the encrypted image.
HUB_DUMP_IMAGE     := _backup/hub-backup/hub-backup.sparsebundle
HUB_DUMP_VOLUME    := /Volumes/hub-backup
HUB_DUMP_PASS      ?= security find-generic-password -s bg-hub-backup-image -w
HUB_DUMP_SSH       ?= hub-vps
HUB_DUMP_CONTAINER ?= hub-prod
HUB_DUMP_PG        := hub-dump-pg

# Read the passphrase into $P or fail with a hint. Used inside recipes only.
define hub_dump_pass
P="$$($(HUB_DUMP_PASS) 2>/dev/null)"; [ -n "$$P" ] || { echo "$(YELLOW)⚠️  Keychain entry missing. Run: security add-generic-password -s bg-hub-backup-image -a hub-backup -w$(RESET)"; exit 1; }
endef

# Create the image on first use, then mount it (hidden from the Finder sidebar).
hub-dump-open:
	@if [ ! -d "$(HUB_DUMP_IMAGE)" ]; then \
		$(hub_dump_pass); \
		echo "$(CYAN)🔐 Creating encrypted image $(HUB_DUMP_IMAGE)...$(RESET)"; \
		printf '%s' "$$P" | hdiutil create -quiet -type SPARSEBUNDLE -fs APFS \
			-encryption AES-256 -stdinpass -size 8g -volname hub-backup "$(HUB_DUMP_IMAGE)"; \
	fi
	@if [ ! -d "$(HUB_DUMP_VOLUME)" ]; then \
		$(hub_dump_pass); \
		printf '%s' "$$P" | hdiutil attach -quiet -stdinpass -nobrowse "$(HUB_DUMP_IMAGE)"; \
		touch "$(HUB_DUMP_VOLUME)/.metadata_never_index"; \
	fi
	@echo "$(GREEN)✅ Mounted at $(HUB_DUMP_VOLUME)$(RESET)"
	@ls -lh "$(HUB_DUMP_VOLUME)"/hub-backup-*.sql 2>/dev/null || echo "   (no dump yet, run 'make hub-dump')"

# Pull a fresh dump into the encrypted volume, then keep only that one.
# The query part of DATABASE_URL (Doctrine options) is stripped for libpq.
# The throwaway Postgres is dropped first so hub-dump-psql reloads the new dump.
hub-dump: hub-dump-open
	@docker rm -f "$(HUB_DUMP_PG)" >/dev/null 2>&1 || true
	@set -e; F="$(HUB_DUMP_VOLUME)/hub-backup-$$(date +%Y-%m-%d-%H%M%S).sql"; \
	echo "$(CYAN)⬇️  pg_dump via $(HUB_DUMP_SSH)/$(HUB_DUMP_CONTAINER) → $$F$(RESET)"; \
	ssh $(HUB_DUMP_SSH) "docker exec $(HUB_DUMP_CONTAINER) sh -c 'PGSSLMODE=require pg_dump --no-owner --no-acl \"\$${DATABASE_URL%%\?*}\"'" > "$$F"; \
	head -c 300 "$$F" | grep -q "PostgreSQL database dump" || { echo "$(YELLOW)⚠️  Not a pg_dump output, removed$(RESET)"; rm -f "$$F"; exit 1; }; \
	tail -c 400 "$$F" | grep -q "database dump complete" || { echo "$(YELLOW)⚠️  Truncated dump (no end marker), removed; previous dump kept$(RESET)"; rm -f "$$F"; exit 1; }; \
	find "$(HUB_DUMP_VOLUME)" -maxdepth 1 -name 'hub-backup-*.sql' ! -name "$$(basename "$$F")" -exec rm -v {} +; \
	echo "$(GREEN)✅ $$F ($$(du -h "$$F" | cut -f1))$(RESET)"

# Load the dump into a throwaway Postgres 15 (data dir on tmpfs: nothing is
# written to the Docker VM disk) and open psql. Removed by hub-dump-close.
# No port is published: the dump is reachable through `docker exec` only.
hub-dump-psql: hub-dump-open
	@set -e; F="$$(ls -t "$(HUB_DUMP_VOLUME)"/hub-backup-*.sql 2>/dev/null | head -1)"; \
	[ -n "$$F" ] || { echo "$(YELLOW)⚠️  No dump in $(HUB_DUMP_VOLUME), run 'make hub-dump' first$(RESET)"; exit 1; }; \
	if ! docker ps --format '{{.Names}}' | grep -qx "$(HUB_DUMP_PG)"; then \
		echo "$(CYAN)🐘 Loading $$F into a tmpfs Postgres ($(HUB_DUMP_PG))...$(RESET)"; \
		docker run --rm -d --name "$(HUB_DUMP_PG)" --tmpfs /var/lib/postgresql/data:rw,size=3g \
			-e POSTGRES_HOST_AUTH_METHOD=trust -e POSTGRES_DB=hubdump \
			postgres:15-alpine >/dev/null; \
		i=0; until docker exec "$(HUB_DUMP_PG)" pg_isready -q -U postgres 2>/dev/null; do \
			i=$$((i+1)); [ $$i -lt 30 ] || { echo "$(YELLOW)⚠️  Postgres did not start in 30 s$(RESET)"; docker rm -f "$(HUB_DUMP_PG)" >/dev/null 2>&1; exit 1; }; sleep 1; done; \
		docker exec -i "$(HUB_DUMP_PG)" psql -q -U postgres hubdump < "$$F" >/dev/null; \
	fi; \
	docker exec -it "$(HUB_DUMP_PG)" psql -U postgres hubdump

# Stop the throwaway Postgres, eject the volume, reclaim space in the image.
hub-dump-close:
	@docker rm -f "$(HUB_DUMP_PG)" >/dev/null 2>&1 || true
	@if [ -d "$(HUB_DUMP_VOLUME)" ]; then hdiutil detach -quiet "$(HUB_DUMP_VOLUME)"; fi
	@if [ -d "$(HUB_DUMP_IMAGE)" ]; then $(hub_dump_pass); printf '%s' "$$P" | hdiutil compact -quiet -stdinpass "$(HUB_DUMP_IMAGE)" || true; fi
	@echo "$(GREEN)🔒 $(HUB_DUMP_IMAGE) locked$(RESET)"


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
