# Application settings
APP_NAME := weather
VERSION := 1.0.0
GO_VERSION := 1.24

# Include environment variables from .env file if it exists
-include .env
export

.DEFAULT_GOAL := help

##@ General
.PHONY: help
help: ## Display this help message
	@clear
	@echo "Weather App - $(VERSION)"
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1;33m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development
.PHONY: run
run: ## Run the application
	go run main.go

.PHONY: test
test: ## Run tests with coverage
	go test -v -cover ./...

.PHONY: lint
lint: ## Run linter (golangci-lint)
	golangci-lint run ./...

.PHONY: format
format: ## Format code using goimports
	go install golang.org/x/tools/cmd/goimports@latest
	goimports -l -w .
	go mod tidy

.PHONY: deps
deps: ## Download dependencies
	go mod download
	go mod verify

##@ Build
.PHONY: build
build: ## Build for current platform
	go build -o build/$(APP_NAME) main.go

.PHONY: build-windows
build-windows: ## Build for Windows
	mkdir -p build
	CC=x86_64-w64-mingw32-gcc CGO_ENABLED=1 GOOS=windows GOARCH=amd64 \
		fyne package -os windows -icon Icon.png \
		-name "$(APP_NAME)_windows_$(shell date +%Y%m%d%H%M%S)" \
		-appID "com.$(APP_NAME)" -release
	mv $(APP_NAME)_windows_*.exe build/

.PHONY: build-macos-m1
build-macos-m1: ## Build for macOS M1
	mkdir -p build
	GOARCH=arm64 \
		fyne package -os darwin -icon Icon.png \
		-name "$(APP_NAME)_arm64_darwin_$(shell date +%Y%m%d%H%M%S)" \
		-appID "com.$(APP_NAME)" -release
	mv $(APP_NAME)_arm64_darwin_*.app build/

.PHONY: build-macos-intel
build-macos-intel: ## Build for macOS Intel
	mkdir -p build
	GOARCH=amd64 \
		fyne package -os darwin -icon Icon.png \
		-name "$(APP_NAME)_amd64_darwin_$(shell date +%Y%m%d%H%M%S)" \
		-appID "com.$(APP_NAME)" -release
	mv $(APP_NAME)_amd64_darwin_*.app build/

.PHONY: build-linux
build-linux: ## Build for Linux
	mkdir -p build
	GOOS=linux GOARCH=amd64 \
		fyne package -os linux -icon Icon.png \
		-name "$(APP_NAME)_linux_$(shell date +%Y%m%d%H%M%S)" \
		-appID "com.$(APP_NAME)" -release
	mv $(APP_NAME)_linux_*.tar.xz build/

##@ Clean
.PHONY: clean
clean: ## Clean build artifacts
	rm -rf build/
	go clean -cache -testcache

##@ Aliases
.PHONY: r
r: run ## Alias for run

.PHONY: t
t: test ## Alias for test

.PHONY: l
l: lint ## Alias for lint

.PHONY: f
f: format ## Alias for format

