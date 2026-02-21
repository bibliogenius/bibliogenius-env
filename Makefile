.PHONY: help setup install-all install-hub install-bundle install-rust start stop logs app app-chrome version show-version

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
	@echo "  $(GREEN)make setup P=<profile>$(RESET): Setup environment (no-code / junior / senior)"
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
	@echo "  $(GREEN)make test           $(RESET): Run all tests (Rust + Flutter)"
	@echo ""
	@echo "$(CYAN)🏷️  Versioning:$(RESET)"
	@echo "  $(GREEN)make version V=x.y.z$(RESET): Update version in all project files"
	@echo "  $(GREEN)make show-version   $(RESET): Show current version across all components"
	@echo ""

# =============================================================================
# ONBOARDING
# =============================================================================
# Usage: make setup P=no-code
#        make setup P=junior
#        make setup P=senior
setup:
ifndef P
	@echo "$(YELLOW)Usage: make setup P=<profile>$(RESET)"
	@echo "  Profils : no-code, junior, senior"
	@exit 1
endif
	@python3 setup.py $(P)

# =============================================================================
# VERSIONING
# =============================================================================
# Usage: make version V=1.0.0-beta.2
version:
ifndef V
	@echo "$(YELLOW)⚠️  Usage: make version V=1.0.0-beta.2$(RESET)"
	@exit 1
endif
	@echo "$(CYAN)🏷️  Updating version to $(V)...$(RESET)"
	@sed -i '' 's/^version = ".*"/version = "$(V)"/' bibliogenius/Cargo.toml
	@sed -i '' 's/^version: .*/version: $(V)+1/' bibliogenius-app/pubspec.yaml
	@sed -i '' 's/"version": ".*"/"version": "$(V)"/' bibliogenius-hub/composer.json
	@sed -i '' 's/\*\*Status\*\*: v.*/\*\*Status\*\*: v$(V) (Beta Testing)/' README.md
	@echo "$(GREEN)✅ Version updated to $(V) in:$(RESET)"
	@echo "   - bibliogenius/Cargo.toml"
	@echo "   - bibliogenius-app/pubspec.yaml"
	@echo "   - bibliogenius-hub/composer.json"
	@echo "   - README.md"

show-version:
	@echo "$(CYAN)📦 Current versions:$(RESET)"
	@echo "   Rust:    $$(grep '^version = ' bibliogenius/Cargo.toml | head -1)"
	@echo "   Flutter: $$(grep '^version: ' bibliogenius-app/pubspec.yaml)"
	@echo "   Hub:     $$(grep '\"version\"' bibliogenius-hub/composer.json 2>/dev/null || echo '(not set)')"
	@echo "   README:  $$(grep '^\*\*Status\*\*' README.md)"

test:
	@echo "$(CYAN)🧪 Running all tests...$(RESET)"
	@echo "$(YELLOW)Running Rust tests...$(RESET)"
	cd bibliogenius && cargo test --quiet
	@echo "$(YELLOW)Running Flutter tests...$(RESET)"
	cd bibliogenius-app && flutter test --reporter compact
	@echo "$(GREEN)✅ All tests passed!$(RESET)"

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
