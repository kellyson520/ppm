# ZTD Password Manager Makefile

.PHONY: help clean deps test build-android build-ios build-web build-macos build-windows build-linux build-all run

# Default target
help:
	@echo "ZTD Password Manager - Build Commands"
	@echo "======================================"
	@echo "make clean          - Clean build artifacts"
	@echo "make deps           - Get dependencies"
	@echo "make test           - Run tests"
	@echo "make build-android  - Build Android APK and AAB"
	@echo "make build-ios      - Build iOS"
	@echo "make build-web      - Build Web"
	@echo "make build-macos    - Build macOS"
	@echo "make build-windows  - Build Windows"
	@echo "make build-linux    - Build Linux"
	@echo "make build-all      - Build all platforms"
	@echo "make run            - Run in debug mode"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@flutter clean

# Get dependencies
deps:
	@echo "Getting dependencies..."
	@flutter pub get

# Run tests
test:
	@echo "Running tests..."
	@flutter test

# Build Android
build-android:
	@echo "Building Android..."
	@flutter build apk --release
	@flutter build appbundle --release

# Build iOS
build-ios:
	@echo "Building iOS..."
	@flutter build ios --release

# Build Web
build-web:
	@echo "Building Web..."
	@flutter build web --release

# Build macOS
build-macos:
	@echo "Building macOS..."
	@flutter build macos --release

# Build Windows
build-windows:
	@echo "Building Windows..."
	@flutter build windows --release

# Build Linux
build-linux:
	@echo "Building Linux..."
	@flutter build linux --release

# Build all platforms
build-all: clean deps test
	@echo "Building all platforms..."
	@make build-android
	@make build-ios
	@make build-web
	@make build-macos
	@make build-windows
	@make build-linux

# Run in debug mode
run:
	@echo "Running in debug mode..."
	@flutter run

# Analyze code
analyze:
	@echo "Analyzing code..."
	@flutter analyze

# Format code
format:
	@echo "Formatting code..."
	@flutter format lib/

# Generate code (if using code generation)
generate:
	@echo "Generating code..."
	@flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes and generate
watch:
	@echo "Watching for changes..."
	@flutter pub run build_runner watch --delete-conflicting-outputs
