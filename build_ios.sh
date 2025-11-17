#!/usr/bin/env bash

# Build script for iOS (ARM64) - for jailbroken iPhone 8 running iOS 16
# This script cross-compiles bareiron for iOS using clang with the iOS SDK

# Check for registries before attempting to compile
if [ ! -f "include/registries.h" ]; then
  echo "=========================================="
  echo "WARNING: 'include/registries.h' is missing"
  echo "=========================================="
  echo ""
  echo "Registry files are required for a working server."
  echo "To generate them:"
  echo "  1. Download Minecraft 1.21.8 server.jar"
  echo "  2. Run: ./extract_registries.sh"
  echo ""
  echo "Alternatively, you can:"
  echo "  • Download pre-generated registries from a GitHub Actions artifact"
  echo "  • Generate on another machine and copy the files"
  echo ""
  
  if [[ -f "src/registries.c" ]]; then
    echo "Found src/registries.c but include/registries.h is missing."
    echo "Both files are required. Please regenerate registries."
    exit 1
  fi
  
  echo "Cannot proceed without registries."
  echo "See README.md 'Compilation' section for details."
  exit 1
fi

# Also check for registries.c
if [ ! -f "src/registries.c" ]; then
  echo "ERROR: 'src/registries.c' is missing."
  echo "Please run ./extract_registries.sh to generate registry files."
  exit 1
fi

# Check if we're on macOS with Xcode installed
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "=========================================="
  echo "WARNING: Not running on macOS"
  echo "=========================================="
  echo ""
  echo "iOS SDK compilation is only fully supported on macOS with Xcode."
  echo "However, we can try cross-compilation with generic ARM64 target."
  echo ""
  echo "Note: The resulting binary may require additional setup on iOS:"
  echo "  • Code signing with ldid or codesign"
  echo "  • Proper entitlements for network and file access"
  echo "  • May need library compatibility adjustments"
  echo ""
  read -p "Continue with ARM64 cross-compilation? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Build cancelled."
    echo ""
    echo "To build properly for iOS:"
    echo "  • Use a Mac with Xcode installed"
    echo "  • Install Xcode Command Line Tools: xcode-select --install"
    echo "  • Run this script on macOS"
    exit 1
  fi
  echo ""
  echo "Proceeding with ARM64 cross-compilation..."
  CROSS_COMPILE=true
fi

# iOS SDK detection (if running on macOS)
IOS_SDK=""
if [[ "$CROSS_COMPILE" != "true" ]]; then
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
fi

# Default compiler and flags
compiler="clang"
if [[ "$CROSS_COMPILE" == "true" ]]; then
  # Cross-compilation mode for non-macOS systems
  echo "Cross-compiling for ARM64 (generic, not iOS-specific)"
  ios_flags="-target aarch64-unknown-linux-gnu -O2"
  ios_linker="-static"
  echo ""
  echo "Note: This creates a generic ARM64 binary."
  echo "For jailbroken iOS devices, you may need to:"
  echo "  1. Sign the binary: ldid -S bareiron_ios"
  echo "  2. Ensure compatibility with iOS system libraries"
  echo "  3. Grant necessary permissions/entitlements"
  echo ""
else
  # macOS with iOS SDK
  ios_flags="-arch arm64 -isysroot $IOS_SDK -miphoneos-version-min=16.0"
  ios_linker=""
  echo "Compiling for iOS 16.0+ (ARM64) with SDK"
  # Additional iOS-specific flags
  # -DIOS_PLATFORM is defined by the compiler based on __APPLE__ + ARM detection
  ios_flags="$ios_flags -O2"
fi

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
