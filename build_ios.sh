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
  echo "Warning: iOS cross-compilation is typically done on macOS with Xcode."
  echo "Attempting to build with clang for ARM64 anyway..."
fi

# iOS SDK detection (if running on macOS)
IOS_SDK=""
if command -v xcrun &> /dev/null; then
  IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
  if [ -n "$IOS_SDK" ]; then
    echo "Found iOS SDK at: $IOS_SDK"
  fi
fi

# Default compiler and flags
compiler="clang"
ios_flags="-target arm64-apple-darwin"
ios_linker=""

# If iOS SDK is available, use it
if [ -n "$IOS_SDK" ]; then
  ios_flags="-arch arm64 -isysroot $IOS_SDK -miphoneos-version-min=16.0"
  echo "Compiling for iOS 16.0+ (ARM64) with SDK"
else
  echo "Compiling for iOS/Darwin ARM64 (generic)"
  echo "Note: For best results, compile on macOS with Xcode installed"
fi

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
  echo "4. Run it: ./bareiron_ios"
  echo ""
  echo "Note: You may need to sign the binary or disable code signing"
  echo "enforcement on your jailbroken device."
else
  echo "Build failed!"
  exit 1
fi
