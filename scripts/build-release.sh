#!/bin/bash
# AgriFlow - Android Release Build Script

set -e  # Exit on error

echo "📱 AgriFlow Android Release Build"
echo "=================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found"
    exit 1
fi

echo "✓ Flutter found: $(flutter --version | head -1)"
echo ""

# Check for signing config
if [ ! -f "android/key.properties" ]; then
    echo "⚠️  WARNING: android/key.properties not found"
    echo ""
    echo "Building with debug signing (NOT suitable for Play Store)"
    echo ""
    read -p "Continue anyway? (y/N): " continue
    if [[ ! $continue =~ ^[Yy]$ ]]; then
        echo ""
        echo "Setup signing first:"
        echo "  1. Generate keystore: keytool -genkey -v -keystore android/app/agriflow-release.keystore -alias agriflow -keyalg RSA -keysize 2048 -validity 10000"
        echo "  2. Copy android/key.properties.example to android/key.properties"
        echo "  3. Fill in your passwords in android/key.properties"
        echo ""
        exit 1
    fi
fi

# Pre-build checks
echo "🔍 Pre-build checks..."
echo ""

# Check pubspec.yaml version
VERSION=$(grep "^version:" pubspec.yaml | cut -d' ' -f2)
echo "  App version: $VERSION"

# Check application ID
APP_ID=$(grep "applicationId" android/app/build.gradle.kts | grep -o '"[^"]*"' | tr -d '"')
echo "  Application ID: $APP_ID"

if [[ $APP_ID == "com.example.agriflow" ]]; then
    echo ""
    echo "  ⚠️  WARNING: Using example application ID"
    echo "     Change in android/app/build.gradle.kts before Play Store submission"
    echo ""
fi

# Ask which build type
echo ""
echo "📦 Build type:"
echo "1) App Bundle (AAB) - for Play Store (recommended)"
echo "2) APK - for direct distribution"
echo "3) Both"
echo ""
read -p "Select option (1-3): " build_type

echo ""
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

echo ""
echo "🔨 Building release..."
echo ""

case $build_type in
    1)
        flutter build appbundle --release
        echo ""
        echo "✅ App Bundle built successfully!"
        echo ""
        echo "📁 Output: build/app/outputs/bundle/release/app-release.aab"
        ;;
    2)
        flutter build apk --release --split-per-abi
        echo ""
        echo "✅ APKs built successfully!"
        echo ""
        echo "📁 Outputs:"
        ls -lh build/app/outputs/flutter-apk/*-release.apk
        ;;
    3)
        flutter build appbundle --release
        flutter build apk --release --split-per-abi
        echo ""
        echo "✅ Both builds completed successfully!"
        echo ""
        echo "📁 App Bundle: build/app/outputs/bundle/release/app-release.aab"
        echo "📁 APKs:"
        ls -lh build/app/outputs/flutter-apk/*-release.apk
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

# Show size info
echo ""
echo "📊 Build size:"
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    echo "  AAB: $SIZE"
fi

echo ""
echo "════════════════════════════════════════"
echo "✨ Build complete!"
echo "════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  • Test on device: flutter install --release"
echo "  • Upload to Play Console for testing"
echo "  • Submit for review when ready"
echo ""
