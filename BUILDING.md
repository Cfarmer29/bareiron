# Building bareiron

This guide covers various build scenarios and troubleshooting for bareiron.

## Quick Start

For most users, follow these steps:

1. Generate registry files (one-time setup)
2. Compile for your target platform
3. Run the server

## Generating Registry Files

Registry files (`include/registries.h` and `src/registries.c`) are required for compilation. They contain Minecraft protocol data extracted from the official server.

### Method 1: Automatic (Linux/macOS)

```bash
./extract_registries.sh
```

This script will:
- Check for Java 21+
- Download Minecraft 1.21.8 server.jar (if needed)
- Extract registry data
- Generate C header and source files

**Requirements:**
- Java 21 or newer
- Internet access (to download ~50MB server.jar)
- Node.js, Bun, or Deno (for JavaScript processing)

### Method 2: Manual Download

If you can't run the automatic script:

1. **Download the server JAR:**
   ```bash
   mkdir -p notchian
   cd notchian
   # Try the official source:
   curl -Lo server.jar https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar
   # OR use a mirror:
   # wget https://mcversions.net/download/1.21.8 -O server.jar
   cd ..
   ```

2. **Extract registries:**
   ```bash
   cd notchian
   echo "eula=true" > eula.txt
   java -DbundlerMainClass="net.minecraft.data.Main" -jar server.jar --all
   cd ..
   ```

3. **Generate C files:**
   ```bash
   node build_registries.js
   # OR: bun run build_registries.js
   # OR: deno run --allow-read --allow-write build_registries.js
   ```

### Method 3: Use Pre-Generated Files

If you're building in a restricted environment (no internet, behind firewall, etc.):

1. **Option A: Download from GitHub Actions**
   - Go to the [repository's Actions tab](https://github.com/Cfarmer29/bareiron/actions)
   - Find a successful "Build with Cosmopolitan" workflow run
   - Download the artifacts (may contain pre-generated files)
   - Extract `include/registries.h` and `src/registries.c`

2. **Option B: Generate on Another Machine**
   - Run `./extract_registries.sh` on a machine with internet access
   - Copy the generated files:
     - `include/registries.h`
     - `src/registries.c`
   - Transfer to your build environment

## Building for Different Platforms

### Linux (x86_64)

```bash
# Install gcc if not already installed
sudo apt-get update
sudo apt-get install gcc

# Build
./build.sh
```

The script will:
- Check for required registry files
- Compile all source files with optimizations
- Produce `bareiron` binary
- Automatically run the server for testing

### Windows (Native)

**Using MSYS2:**

1. Install [MSYS2](https://www.msys2.org/)
2. Open "MSYS2 MINGW64" shell
3. Install GCC: `pacman -Sy mingw-w64-x86_64-gcc`
4. Navigate to the project directory
5. Run: `./build.sh`

**Using WSL (Windows Subsystem for Linux):**

1. Install WSL and Ubuntu
2. Follow Linux build instructions above

### macOS (x86_64 or ARM64)

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Build
./build.sh
```

### iOS (Jailbroken Devices)

#### Option A: Build on macOS (Recommended)

```bash
# Install Xcode and command line tools
xcode-select --install

# Generate registries (if not done already)
./extract_registries.sh

# Build for iOS
./build_ios.sh
```

This produces `bareiron_ios` compiled with the iOS SDK for best compatibility.

#### Option B: Cross-Compile from Linux (Experimental)

```bash
# Install cross-compilation tools
sudo apt-get update
sudo apt-get install gcc-aarch64-linux-gnu
# OR: sudo apt-get install crossbuild-essential-arm64

# Alternative: Use clang (may need additional setup)
# sudo apt-get install clang

# Generate registries (if not done already)
./extract_registries.sh

# Build for ARM64
./build_ios.sh
# Answer 'y' when prompted
```

This produces a generic ARM64 binary that should work on jailbroken iOS devices.

**Note:** The build script will attempt to use clang with ARM64 target. If you encounter linker errors, you may need to install the proper cross-compilation toolchain (gcc-aarch64-linux-gnu) or modify the script to use it.

**Differences:**
- macOS build: Uses iOS SDK, produces iOS-specific binary
- Linux build: Generic ARM64 Linux binary, may need extra setup on device

**After building, transfer to iPhone:**
```bash
# Copy to device
scp bareiron_ios root@<iphone-ip>:/var/mobile/

# On iPhone:
chmod +x /var/mobile/bareiron_ios
ldid -S /var/mobile/bareiron_ios  # Sign the binary
./bareiron_ios
```

See `IOS_QUICKSTART.md` for detailed iOS setup instructions.

### ESP32 and Other Microcontrollers

1. Set up PlatformIO project with ESP-IDF framework
2. Clone this repository into the project
3. Configure WiFi credentials in `include/globals.h`
4. Build with PlatformIO

See README.md for more details on embedded builds.

## Troubleshooting

### "include/registries.h is missing"

**Cause:** Registry files haven't been generated yet.

**Solution:** Follow the "Generating Registry Files" section above.

### "Java 21 or newer required"

**Cause:** Your Java version is too old.

**Solution:**
```bash
# Ubuntu/Debian:
sudo apt-get install openjdk-21-jdk

# macOS (with Homebrew):
brew install openjdk@21

# Verify:
java -version
```

### "No JavaScript runtime found"

**Cause:** Need Node.js, Bun, or Deno to process registry data.

**Solution:**
```bash
# Install Node.js (Ubuntu/Debian):
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# OR install Bun:
curl -fsSL https://bun.sh/install | bash

# OR install Deno:
curl -fsSL https://deno.land/install.sh | sh
```

### "Could not resolve host" when downloading server.jar

**Cause:** No internet access or blocked domain.

**Solution:** Use Method 3 (Pre-Generated Files) from the registry generation section.

### iOS binary doesn't run on device

**Symptoms:**
- "Permission denied" error
- "Killed: 9" error
- Immediate crash

**Solutions:**
1. Make executable: `chmod +x bareiron_ios`
2. Sign the binary: `ldid -S bareiron_ios`
3. Check if code signing enforcement is disabled
4. Try running as root: `sudo ./bareiron_ios`
5. Check Console.app logs on macOS after connecting device

### Build fails with "undefined reference" errors

**Cause:** Missing source files or incorrect compilation.

**Solution:**
1. Ensure all files in `src/` are present
2. Verify `src/registries.c` exists
3. Try cleaning and rebuilding:
   ```bash
   rm -f bareiron bareiron.exe bareiron_ios
   ./build.sh  # or ./build_ios.sh
   ```

### Cross-compilation issues on Linux for iOS

**Issue 1: Build fails with linker errors**

**Error message:** "unrecognised emulation mode: aarch64linux"

**Cause:** System linker doesn't support ARM64 target.

**Solution:**
```bash
# Install ARM64 cross-compilation toolchain
sudo apt-get install gcc-aarch64-linux-gnu

# Modify build_ios.sh to use gcc-aarch64-linux-gnu:
# Change line: compiler="clang"
# To: compiler="aarch64-linux-gnu-gcc"
```

**Issue 2: Binary doesn't work on iOS device**

**Possible causes:**
- Library compatibility issues
- Missing iOS-specific implementations
- Incorrect entitlements or code signing

**Solutions:**
1. Try building on macOS with Xcode for proper iOS SDK support
2. Check device logs for specific error messages
3. Verify the device is jailbroken and allows unsigned code
4. Try different code signing options:
   ```bash
   # On device:
   ldid -S bareiron_ios
   # OR with entitlements:
   ldid -Sentitlements.xml bareiron_ios
   ```
5. Check that the binary is actually ARM64:
   ```bash
   file bareiron_ios
   # Should show: "ELF 64-bit LSB executable, ARM aarch64"
   ```

## Performance Tuning

For resource-constrained devices (ESP32, old phones, etc.), edit `include/globals.h`:

```c
// Reduce memory usage
#define MAX_PLAYERS 4          // Down from 16
#define VIEW_DISTANCE 1        // Down from 2
#define MAX_BLOCK_CHANGES 5000 // Down from 20000

// Reduce CPU usage
#define TIME_BETWEEN_TICKS 2000000  // 2 seconds (up from 1)

// Disable expensive features
// #define DO_FLUID_FLOW       // Uncomment to disable water/lava flow
// #define ALLOW_CHESTS        // Uncomment to disable chests
```

## Additional Resources

- [README.md](README.md) - Main documentation
- [IOS_NOTES.md](IOS_NOTES.md) - Technical iOS details
- [IOS_QUICKSTART.md](IOS_QUICKSTART.md) - Step-by-step iOS guide
- [CHANGES.md](CHANGES.md) - Version history
- [Minecraft Protocol Wiki](https://minecraft.wiki/w/Java_Edition_protocol) - Protocol reference

## Getting Help

If you encounter issues:

1. Check this troubleshooting section
2. Review error messages carefully
3. Ensure you have all prerequisites installed
4. Try the build on a clean environment
5. Check existing GitHub issues
6. Create a new issue with:
   - Your OS and version
   - Build commands you ran
   - Complete error output
   - Steps to reproduce
