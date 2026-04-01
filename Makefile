.PHONY: build install uninstall clean dmg

VERSION := $(shell cat VERSION)
APP_NAME = Pester
APP_DIR = $(HOME)/Applications/$(APP_NAME).app
CLI_DIR = $(HOME)/.pester/bin

build:
	swift build -c release

# Compile asset catalog into Assets.car
assets:
	@mkdir -p .build/assets
	@xcrun actool Resources/Assets.xcassets \
		--compile .build/assets \
		--platform macosx \
		--minimum-deployment-target 14.0 \
		--app-icon AppIcon \
		--output-partial-info-plist .build/assets/partial.plist \
		2>/dev/null

install: build assets
	@mkdir -p "$(APP_DIR)/Contents/MacOS"
	@mkdir -p "$(APP_DIR)/Contents/Resources"
	@cp .build/release/Pester "$(APP_DIR)/Contents/MacOS/"
	@sed 's/VERSION_PLACEHOLDER/$(VERSION)/g' Resources/Info.plist > "$(APP_DIR)/Contents/Info.plist"
	@cp .build/assets/Assets.car "$(APP_DIR)/Contents/Resources/"
	@mkdir -p "$(CLI_DIR)"
	@cp .build/release/pester-cli "$(CLI_DIR)/"
	@./scripts/setup-hooks.sh
	@echo ""
	@echo "Installed $(APP_NAME) v$(VERSION):"
	@echo "  $(APP_DIR)"
	@echo "  $(CLI_DIR)/pester-cli"

uninstall:
	@rm -rf "$(APP_DIR)"
	@rm -f "$(CLI_DIR)/pester-cli"
	@echo "Uninstalled."

dmg: build assets
	@rm -rf .build/dmg
	@mkdir -p .build/dmg/Pester.app/Contents/MacOS
	@mkdir -p .build/dmg/Pester.app/Contents/Resources
	@cp .build/release/Pester .build/dmg/Pester.app/Contents/MacOS/
	@cp .build/release/pester-cli .build/dmg/Pester.app/Contents/MacOS/
	@sed 's/VERSION_PLACEHOLDER/$(VERSION)/g' Resources/Info.plist > .build/dmg/Pester.app/Contents/Info.plist
	@cp .build/assets/Assets.car .build/dmg/Pester.app/Contents/Resources/
	@cp scripts/setup-hooks.sh .build/dmg/Pester.app/Contents/Resources/
	@rm -f .build/Pester-$(VERSION).dmg
	@create-dmg \
		--volname "Pester" \
		--window-size 600 400 \
		--icon-size 128 \
		--icon "Pester.app" 150 185 \
		--app-drop-link 450 185 \
		--hide-extension "Pester.app" \
		.build/Pester-$(VERSION).dmg .build/dmg
	@echo ""
	@echo "Created .build/Pester-$(VERSION).dmg"

clean:
	swift package clean
