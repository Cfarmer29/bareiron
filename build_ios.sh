#!/usr/bin/env bash

# Build script for iOS (ARM64) - for jailbroken iPhone 8 running iOS 16
# This script cross-compiles bareiron for iOS using clang with the iOS SDK

# Check for registries before attempting to compile
if [ ! -f "include/registries.h" ]; then
  echo "Error: 'include/registries.h' is missing."
  echo "Please follow the 'Compilation' section of the README to generate it."
  exit 1
fi

# Check if we're on macOS with Xcode installed
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "=========================================="
  echo "ERROR: iOS compilation requires macOS"
  echo "=========================================="
  echo ""
  echo "Cross-compilation for iOS from Linux is not supported because:"
  echo "  1. iOS SDK is required for system headers (stdlib.h, stdio.h, etc.)"
  echo "  2. Apple's SDK is only available on macOS with Xcode"
  echo "  3. Generic ARM64 binaries won't have proper iOS system library linkage"
  echo ""
  echo "To build for iOS:"
  echo "  • Use a Mac with Xcode installed"
  echo "  • Install Xcode Command Line Tools: xcode-select --install"
  echo "  • Run this script on macOS"
  echo ""
  echo "Alternative: Build a generic ARM64 binary for testing"
  echo "  • This won't run on iOS, but might work on other ARM64 systems"
  echo "  • Use: clang -target arm64-unknown-linux-gnu src/*.c -O2 -Iinclude -o bareiron_arm64"
  echo ""
  exit 1
fi

# iOS SDK detection (if running on macOS)
IOS_SDK=""
if command -v xcrun &> /dev/null; then
  IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
  if [ -n "$IOS_SDK" ]; then
    echo "Found iOS SDK at: $IOS_SDK"
  else
    echo "ERROR: iOS SDK not found. Please install Xcode and run: xcode-select --install"
    exit 1
  fi
else
  echo "ERROR: xcrun not found. Please install Xcode and run: xcode-select --install"
  exit 1
fi

# Default compiler and flags
compiler="clang"
ios_flags="-arch arm64 -isysroot $IOS_SDK -miphoneos-version-min=16.0"
ios_linker=""

echo "Compiling for iOS 16.0+ (ARM64) with SDK"

# Additional iOS-specific flags
# -DIOS_PLATFORM is defined by the compiler based on __APPLE__ + ARM detection
ios_flags="$ios_flags -O2"

echo "Building bareiron for iOS (iPhone 8, ARM64)..."
rm -f bareiron_ios

# Compile
$compiler src/*.c $ios_flags -Iinclude -o bareiron_ios $ios_linker

if [ $? -eq 0 ]; then
  echo "Build successful! Binary: bareiron_ios"
  echo ""
  echo "To install on jailbroken iPhone 8:"
  echo "1. Copy bareiron_ios to your device (via SSH, iFunBox, etc.)"
  echo "2. Move it to a location like /usr/local/bin/ or /var/mobile/"
  echo "3. Make it executable: chmod +x bareiron_ios"
  echo "4. Sign the binary: ldid -S bareiron_ios (if needed)"
  echo "5. Run it: ./bareiron_ios"
  echo ""
  echo "Note: You may need to sign the binary or disable code signing"
  echo "enforcement on your jailbroken device."
else
  echo "Build failed!"
  exit 1
fi
