#!/usr/bin/env bash

# Check for registries before attempting to compile, prevents confusion
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

# Figure out executable suffix (for MSYS compilation)
case "$OSTYPE" in
  msys*|cygwin*|win32*) exe=".exe" ;;
  *) exe="" ;;
esac

# mingw64-specific linker options
windows_linker=""
unameOut="$(uname -s)"
case "$unameOut" in
  MINGW64_NT*)
    windows_linker="-static -lws2_32 -pthread"
    ;;
esac

# Default compiler
compiler="gcc"

# Handle arguments for windows 9x build
for arg in "$@"; do
  case $arg in
    --9x)
      if [[ "$unameOut" == MINGW64_NT* ]]; then
        compiler="/opt/bin/i686-w64-mingw32-gcc"
        windows_linker="$windows_linker -Wl,--subsystem,console:4"
      else
        echo "Error: Compiling for Windows 9x is only supported when running under the MinGW64 shell."
        exit 1
      fi
      ;;
  esac
done

rm -f "bareiron$exe"
$compiler src/*.c -O2 -Iinclude -o "bareiron$exe" $windows_linker
"./bareiron$exe"
