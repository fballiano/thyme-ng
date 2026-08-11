# thyme-ng — build helpers.
#
#   make generate   regenerate ThymeNG.xcodeproj from project.yml (needs xcodegen)
#   make build      build the Release app into ./build
#   make debug      build the Debug app into ./build
#   make test       run the unit tests
#   make run        build, then launch the app
#   make install    copy the app into /Applications
#   make clean      remove ./build

SHELL          := /bin/bash
PROJECT        := ThymeNG.xcodeproj
SCHEME         := ThymeNG
APP            := thyme-ng.app
BUILD_DIR      := $(CURDIR)/build
APP_RELEASE    := $(BUILD_DIR)/Build/Products/Release/$(APP)
APP_DEBUG      := $(BUILD_DIR)/Build/Products/Debug/$(APP)
XCODEBUILD     := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(BUILD_DIR)
QUIET          := -quiet

.PHONY: all generate build debug test run install uninstall clean

all: build

generate:
	xcodegen generate

build:
	$(XCODEBUILD) -configuration Release $(QUIET) build
	@echo "Built $(APP_RELEASE)"

debug:
	$(XCODEBUILD) -configuration Debug $(QUIET) build
	@echo "Built $(APP_DEBUG)"

# Serial testing: the tests load into the real app, so a parallel run would
# launch one copy of the app per test worker. The results are printed, so this
# target does not use -quiet.
test:
	@set -o pipefail; $(XCODEBUILD) -configuration Debug \
		-destination 'platform=macOS,arch=arm64' \
		-parallel-testing-enabled NO test \
		| grep -vE 'linkd.autoShortcut|Process Instance Registry|synchronousRemoteObjectProxy'

run: build
	@pkill -x thyme-ng || true
	@open $(APP_RELEASE)

install: build
	@pkill -x thyme-ng || true
	@rm -rf /Applications/$(APP)
	@cp -R $(APP_RELEASE) /Applications/$(APP)
	@echo "Installed /Applications/$(APP)"

uninstall:
	@pkill -x thyme-ng || true
	@rm -rf /Applications/$(APP)
	@echo "Removed /Applications/$(APP)"

clean:
	@rm -rf $(BUILD_DIR)
