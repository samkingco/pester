.PHONY: build install uninstall clean dmg

VERSION := $(shell cat VERSION)
APP_NAME = Pester
APP_DIR = $(HOME)/Applications/$(APP_NAME).app
CLI_DIR = $(HOME)/.pester/bin

build:
	swift build -c release

install: build
	@mkdir -p "$(APP_DIR)/Contents/MacOS"
	@mkdir -p "$(APP_DIR)/Contents/Resources"
	@cp .build/release/Pester "$(APP_DIR)/Contents/MacOS/"
	@sed 's/VERSION_PLACEHOLDER/$(VERSION)/g' Resources/Info.plist > "$(APP_DIR)/Contents/Info.plist"
	@cp Resources/AppIcon.icns "$(APP_DIR)/Contents/Resources/"
	@cp -R Resources/AppIcon.icon "$(APP_DIR)/Contents/Resources/"
	@mkdir -p "$(CLI_DIR)"
	@cp .build/release/pester-cli "$(CLI_DIR)/"
	@mkdir -p "$(HOME)/.pester/pending"
	@./scripts/setup-hooks.sh
	@echo ""
	@echo "Installed $(APP_NAME) v$(VERSION):"
	@echo "  $(APP_DIR)"
	@echo "  $(CLI_DIR)/pester-cli"

uninstall:
	@rm -rf "$(APP_DIR)"
	@rm -f "$(CLI_DIR)/pester-cli"
	@echo "Uninstalled."

dmg: build
	@rm -rf .build/dmg
	@mkdir -p .build/dmg/Pester.app/Contents/MacOS
	@mkdir -p .build/dmg/Pester.app/Contents/Resources
	@cp .build/release/Pester .build/dmg/Pester.app/Contents/MacOS/
	@cp .build/release/pester-cli .build/dmg/Pester.app/Contents/MacOS/
	@sed 's/VERSION_PLACEHOLDER/$(VERSION)/g' Resources/Info.plist > .build/dmg/Pester.app/Contents/Info.plist
	@cp Resources/AppIcon.icns .build/dmg/Pester.app/Contents/Resources/
	@cp -R Resources/AppIcon.icon .build/dmg/Pester.app/Contents/Resources/
	@cp scripts/setup-hooks.sh .build/dmg/Pester.app/Contents/Resources/
	@hdiutil create -volname Pester -srcfolder .build/dmg -ov -format UDZO .build/Pester-$(VERSION).dmg
	@echo ""
	@echo "Created .build/Pester-$(VERSION).dmg"

clean:
	swift package clean
