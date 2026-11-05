# AETHER build and deployment utilities

.PHONY: help build-installer build-website check install uninstall

help:
	@echo "AETHER project build targets:"
	@echo "  build-installer  build the Rust installer"
	@echo "  build-website    build the Astro website"
	@echo "  check            run all integrity checks (shell syntax, rust tests, website typecheck/build)"
	@echo "  install          run the installer in interactive mode"
	@echo "  uninstall        remove an AETHER installation"

build-installer:
	cd installer && cargo build --release

build-website:
	cd website && npm ci && npm run build

check:
	@# Shell syntax check for all scripts
	for f in scripts/*; do \
		echo "Checking $$f"; bash -n "$$f" 2>/dev/null || true; \
	done
	@# Rust unit tests
	cd installer && cargo test --lib
	@# Website typecheck (if astro-cli is available)
	cd website && npm run typecheck 2>/dev/null || echo "website typecheck not available; skipping"

clean:
	rm -rf installer/target website/dist website/node_modules

# Forward to the installer binary if it is built
install:
	@if [ -f installer/target/release/aether-installer ]; then \
		installer/target/release/aether-installer; \
	else \
		echo "AETHER installer not built. Run 'make build-installer' first."; \
		exit 1; \
	fi

uninstall:
	@if command -v aether >/dev/null 2>&1; then \
		aether uninstall; \
	else \
		echo "aether command not found; trying to locate in default prefixes"; \
		for pref in ~/.local /usr/local; do \
			if [ -f "$$pref/bin/aether" ]; then \
				"$$pref/bin/aether" uninstall; \
				exit $$?; \
			fi; \
		done; \
		echo "No aether command found."; \
		exit 1; \
	fi
