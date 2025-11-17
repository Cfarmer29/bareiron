#!/usr/bin/env bash
set -euo pipefail

# Helper script to download pre-generated registry files from GitHub Actions artifacts
# This is useful when you can't generate registries locally (no Java, no internet, etc.)

REPO_OWNER="${REPO_OWNER:-Cfarmer29}"
REPO_NAME="${REPO_NAME:-bareiron}"
BRANCH="${BRANCH:-main}"

echo "=========================================="
echo "Registry Downloader for bareiron"
echo "=========================================="
echo ""
echo "This script helps you obtain pre-generated registry files"
echo "from GitHub Actions artifacts."
echo ""
echo "Note: This requires:"
echo "  • GitHub CLI (gh) to be installed and authenticated"
echo "  • OR manual download from GitHub.com"
echo ""

check_gh_cli() {
  if command -v gh &> /dev/null; then
    return 0
  else
    return 1
  fi
}

if check_gh_cli; then
  echo "GitHub CLI detected. Attempting to download from recent workflow runs..."
  echo ""
  
  # Try to find a recent successful workflow run
  echo "Fetching recent successful workflow runs..."
  WORKFLOW_RUNS=$(gh run list --repo "$REPO_OWNER/$REPO_NAME" --workflow="build.yml" --status=success --limit=5 --json databaseId,headBranch,conclusion 2>/dev/null || echo "")
  
  if [[ -z "$WORKFLOW_RUNS" ]]; then
    echo "ERROR: Could not fetch workflow runs. Make sure you're authenticated with 'gh auth login'"
    exit 1
  fi
  
  echo "Found recent successful builds."
  echo ""
  echo "Note: GitHub Actions artifacts are typically only available for 90 days."
  echo "Unfortunately, registry files (registries.c and registries.h) are part of"
  echo "the build process and not typically saved as artifacts in the current workflow."
  echo ""
  echo "However, you have options:"
  echo ""
else
  echo "GitHub CLI (gh) not found."
  echo ""
fi

echo "Options to obtain registry files:"
echo ""
echo "1. Generate them locally (recommended):"
echo "   ./extract_registries.sh"
echo ""
echo "2. Generate on another machine with internet access:"
echo "   • Run: ./extract_registries.sh"
echo "   • Copy these files to your build environment:"
echo "     - include/registries.h"
echo "     - src/registries.c"
echo ""
echo "3. Manual generation:"
echo "   a. Download Minecraft 1.21.8 server.jar:"
echo "      mkdir -p notchian && cd notchian"
echo "      curl -Lo server.jar https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar"
echo "      cd .."
echo "   b. Extract registries:"
echo "      cd notchian"
echo "      echo 'eula=true' > eula.txt"
echo "      java -DbundlerMainClass='net.minecraft.data.Main' -jar server.jar --all"
echo "      cd .."
echo "   c. Generate C files:"
echo "      node build_registries.js"
echo ""
echo "4. Request pre-generated files:"
echo "   • Open an issue on GitHub requesting registry files"
echo "   • Someone with a working build environment can share them"
echo ""
echo "For more information, see BUILDING.md"
