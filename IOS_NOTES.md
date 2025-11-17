# iOS Platform Support

This document provides technical details about the iOS platform support implementation for bareiron.

## Platform Detection

The `IOS_PLATFORM` macro is automatically defined when compiling for iOS devices. The detection logic in `include/globals.h` is:

```c
#if defined(__APPLE__) && (defined(__arm__) || defined(__arm64__) || defined(__aarch64__))
  #define IOS_PLATFORM
#endif
```

This macro is defined when:
- `__APPLE__` is defined (Apple platform)
- AND one of the ARM architecture macros is defined:
  - `__arm__` (32-bit ARM, older iOS devices)
  - `__arm64__` (64-bit ARM, used by clang)
  - `__aarch64__` (64-bit ARM, alternative name)

## Target Device

- **Device**: iPhone 8
- **Architecture**: ARM64 (AArch64)
- **iOS Version**: 16.0+
- **Chip**: Apple A11 Bionic
- **RAM**: 2GB

## Compilation

### On macOS with Xcode (Recommended)

**Note**: iOS compilation with the official iOS SDK requires macOS with Xcode. This produces the most compatible binary.

```bash
# Install Xcode command line tools if not already installed
xcode-select --install

# Build for iOS
./build_ios.sh
```

This will use the iOS SDK and produce a properly signed ARM64 binary.

### Cross-compilation from Linux (Experimental)

While the iOS SDK is only available on macOS, you can create a generic ARM64 binary on Linux that may work on jailbroken iOS devices:

```bash
# Install clang (if not already installed)
sudo apt-get install clang

# Build for ARM64
./build_ios.sh
# Answer 'y' when prompted about cross-compilation
```

**Limitations of Linux cross-compilation:**
- The iOS SDK is proprietary and only available on macOS
- Creates a generic ARM64 binary using standard libc, not iOS-specific implementations
- May require additional code signing and entitlements on the device
- System library compatibility is not guaranteed
- Should work on jailbroken devices with proper signing (ldid -S)

**When to use Linux cross-compilation:**
- You don't have access to a Mac
- You're targeting jailbroken devices with flexible code execution policies
- You're willing to troubleshoot compatibility issues
- You want to quickly test if the code compiles for ARM64

## Code Compatibility

The existing codebase is already compatible with iOS because it uses:

1. **Standard POSIX networking APIs**: `socket()`, `bind()`, `listen()`, `accept()`, `send()`, `recv()`
   - These are part of BSD sockets, which iOS fully supports

2. **Standard POSIX file I/O**: `fopen()`, `fread()`, `fwrite()`, `fclose()`, `fseek()`
   - These work identically on iOS as on other Unix systems

3. **Standard C library**: All standard C functions used in the code are available on iOS

4. **POSIX time functions**: `clock_gettime()` with `CLOCK_MONOTONIC`
   - Available on iOS 10.0+

No iOS-specific code changes were required!

## Deployment to Jailbroken iPhone

1. **Build the binary** (on macOS or Linux):
   ```bash
   ./build_ios.sh
   ```

2. **Transfer to device** (via SSH, iFunBox, Filza, etc.):
   ```bash
   scp bareiron_ios root@<iphone-ip>:/var/mobile/bareiron_ios
   ```

3. **SSH into the device**:
   ```bash
   ssh root@<iphone-ip>
   ```

4. **Make executable**:
   ```bash
   chmod +x /var/mobile/bareiron_ios
   ```

5. **Sign the binary** (if needed):
   ```bash
   ldid -S bareiron_ios
   ```

6. **Run the server**:
   ```bash
   cd /var/mobile
   ./bareiron_ios
   ```

## Performance Considerations

The iPhone 8 has an A11 Bionic chip with 2 performance cores @ 2.39 GHz and 4 efficiency cores @ 1.42 GHz. With 2GB of RAM, it should handle bareiron well with appropriate settings:

### Recommended `globals.h` settings:

```c
#define MAX_PLAYERS 4          // Reduce from 16 for mobile
#define VIEW_DISTANCE 2        // Keep at 2 or reduce to 1
#define TIME_BETWEEN_TICKS 1000000  // 1 second is fine
#define MAX_BLOCK_CHANGES 10000     // Reduce to save memory
```

These settings will use approximately:
- Block changes: ~195 KB (10000 * ~19.5 bytes)
- Player data: ~5 KB (4 * ~1.3 KB)
- Mob data: ~144 bytes (4 * 36 bytes)
- Total: ~200 KB + code + stack

## Running in Background

To keep the server running when disconnecting SSH:

### Using nohup:
```bash
nohup ./bareiron_ios > bareiron.log 2>&1 &
```

### Using screen (if installed via Cydia/Sileo):
```bash
screen -S bareiron
./bareiron_ios
# Press Ctrl+A then D to detach
```

### Using tmux (if installed):
```bash
tmux new -s bareiron
./bareiron_ios
# Press Ctrl+B then D to detach
```

## Networking

The server binds to `0.0.0.0:25565` by default, listening on all network interfaces:
- **WiFi**: Other devices on the same network can connect
- **Cellular**: If your carrier allows it (usually blocked)
- **USB Tethering**: Works with tethered devices

You may need to configure your firewall or use tools like `iptables` (if installed) to manage access.

## Troubleshooting

### "Permission denied" when running
- Make sure the binary is executable: `chmod +x bareiron_ios`
- Try signing with ldid: `ldid -S bareiron_ios`
- Check if you need to disable code signing enforcement

### "Address already in use" error
- Another process is using port 25565
- Find it: `lsof -i :25565`
- Kill it: `kill <PID>`

### Server crashes or freezes
- Reduce `VIEW_DISTANCE` to 1
- Reduce `MAX_PLAYERS` to 2-4
- Increase `TIME_BETWEEN_TICKS` to 2000000 (2 seconds)
- Disable `DO_FLUID_FLOW` and `ALLOW_CHESTS`

### Cannot connect from other devices
- Check iPhone's IP address: `ifconfig`
- Make sure devices are on same WiFi network
- Check if firewall is blocking port 25565
- Try connecting to: `<iphone-ip>:25565`

## Limitations

1. **No App Store distribution**: This requires a jailbroken device
2. **Code signing**: May need manual signing with ldid or similar tools
3. **Background execution**: iOS may kill the process to save battery; use background execution tools
4. **Battery drain**: Running a server is CPU-intensive; keep device plugged in
5. **No push notifications**: When the app is killed, players can't be notified
6. **Memory pressure**: iOS may terminate the process if system memory is low

## Technical Notes

- The `IOS_PLATFORM` macro is currently defined but not actively used in the code, as all iOS-specific behavior is handled by the existing POSIX code paths
- If iOS-specific features are needed in the future (e.g., iOS-specific file paths, network configuration), the `IOS_PLATFORM` macro can be used to conditionally compile iOS-specific code
- World data is saved to `world.bin` in the current working directory, so it's best to run the server from a consistent location
