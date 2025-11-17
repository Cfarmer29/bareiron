#!/usr/bin/env bash
set -euo pipefail

REQUIRED_MAJOR=21
SERVER_JAR="${SERVER_JAR:-server.jar}"
NOTCHIAN_DIR="notchian"
JS_RUNTIME=""

get_java_version() {
  java -version 2>&1 | awk -F[\".] '/version/ {print $2}'
}

check_java() {
  if ! command -v java >/dev/null 2>&1; then
    echo "Java not found in PATH."
    exit 1
  fi

  local major
  major="$(get_java_version)"

  if (( major < REQUIRED_MAJOR )); then
    echo "Java $REQUIRED_MAJOR or newer required, but found Java $major."
    exit 1
  fi
}

prepare_notchian_dir() {
  if [[ ! -d "$NOTCHIAN_DIR" ]]; then
    echo "Creating $NOTCHIAN_DIR directory..."
    mkdir -p "$NOTCHIAN_DIR"
  fi
  cd "$NOTCHIAN_DIR"
}

dump_registries() {
  if [[ ! -f "$SERVER_JAR" ]]; then
    echo "=========================================="
    echo "ERROR: No server.jar found"
    echo "=========================================="
    echo ""
    echo "Expected location: $NOTCHIAN_DIR/$SERVER_JAR"
    echo ""
    echo "Download options:"
    echo "  1. Official source (recommended):"
    echo "     curl -Lo notchian/server.jar https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar"
    echo ""
    echo "  2. Alternative mirrors:"
    echo "     • https://mcversions.net/download/1.21.8"
    echo "     • https://getbukkit.org/download/vanilla"
    echo ""
    echo "  3. Manual download:"
    echo "     • Visit minecraft.net and download version 1.21.8"
    echo "     • Place server.jar in the '$NOTCHIAN_DIR' directory"
    echo ""
    echo "After downloading, run this script again."
    echo ""
    exit 1
  fi

  echo "Extracting registries from Minecraft server..."
  java -DbundlerMainClass="net.minecraft.data.Main" -jar "$SERVER_JAR" --all
  
  if [[ $? -ne 0 ]]; then
    echo ""
    echo "ERROR: Failed to extract registries from server.jar"
    echo "This could mean:"
    echo "  • Corrupt or incorrect server.jar file"
    echo "  • Insufficient Java version (need Java 21+)"
    echo "  • Not enough disk space"
    echo ""
    exit 1
  fi
}

detect_js_runtime() {
  if command -v node >/dev/null 2>&1; then
    JS_RUNTIME="node"
  elif command -v bun >/dev/null 2>&1; then
    JS_RUNTIME="bun"
  elif command -v deno >/dev/null 2>&1; then
    JS_RUNTIME="deno run"
  else
    echo "No JavaScript runtime found (Node.js, Bun, or Deno)."
    exit 1
  fi
}

run_js_script() {
  local script="$1"
  if [[ -z "$JS_RUNTIME" ]]; then
    detect_js_runtime
  fi
  echo "Running $script with $JS_RUNTIME..."
  $JS_RUNTIME "$script"
}

check_java
prepare_notchian_dir
dump_registries
run_js_script "../build_registries.js"
echo "Registry dump and processing complete."
