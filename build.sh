#!/bin/bash

# ZTD Password Manager Build Script

set -e

echo "========================================"
echo "ZTD Password Manager - Build Script"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version: $(flutter --version | head -1)"

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Run code generation (if needed)
# print_status "Running code generation..."
# flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
print_status "Running tests..."
flutter test

# Build for different platforms
case "$1" in
    android)
        print_status "Building Android APK..."
        flutter build apk --release
        print_status "Building Android App Bundle..."
        flutter build appbundle --release
        ;;
    ios)
        print_status "Building iOS..."
        flutter build ios --release
        ;;
    web)
        print_status "Building Web..."
        flutter build web --release
        ;;
    macos)
        print_status "Building macOS..."
        flutter build macos --release
        ;;
    windows)
        print_status "Building Windows..."
        flutter build windows --release
        ;;
    linux)
        print_status "Building Linux..."
        flutter build linux --release
        ;;
    all)
        print_status "Building for all platforms..."
        flutter build apk --release
        flutter build appbundle --release
        flutter build ios --release
        flutter build web --release
        flutter build macos --release
        flutter build windows --release
        flutter build linux --release
        ;;
    *)
        print_status "Building Android (default)..."
        flutter build apk --release
        print_status "Building Android App Bundle..."
        flutter build appbundle --release
        ;;
esac

print_status "Build completed successfully!"

# Show output locations
echo ""
echo "========================================"
echo "Build Outputs:"
echo "========================================"

if [ -d "build/app/outputs/flutter-apk" ]; then
    echo "Android APK: build/app/outputs/flutter-apk/"
    ls -lh build/app/outputs/flutter-apk/*.apk 2>/dev/null || true
fi

if [ -d "build/app/outputs/bundle/release" ]; then
    echo ""
    echo "Android App Bundle: build/app/outputs/bundle/release/"
    ls -lh build/app/outputs/bundle/release/*.aab 2>/dev/null || true
fi

if [ -d "build/ios/iphoneos" ]; then
    echo ""
    echo "iOS: build/ios/iphoneos/"
fi

if [ -d "build/web" ]; then
    echo ""
    echo "Web: build/web/"
fi

if [ -d "build/macos/Build/Products/Release" ]; then
    echo ""
    echo "macOS: build/macos/Build/Products/Release/"
fi

if [ -d "build/windows/x64/runner/Release" ]; then
    echo ""
    echo "Windows: build/windows/x64/runner/Release/"
fi

if [ -d "build/linux/x64/release/bundle" ]; then
    echo ""
    echo "Linux: build/linux/x64/release/bundle/"
fi

echo ""
echo "========================================"
print_status "Build process completed!"
echo "========================================"
