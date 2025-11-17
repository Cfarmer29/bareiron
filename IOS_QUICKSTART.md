# iOS Quick Start Guide
## Running bareiron on jailbroken iPhone 8 with iOS 16

This guide walks you through getting bareiron running on your jailbroken iPhone 8.

## Prerequisites

- Jailbroken iPhone 8 running iOS 16
- SSH access to your iPhone (install OpenSSH from Cydia/Sileo)
- **macOS computer with Xcode** for building (or use pre-built binary if available)
- Same WiFi network for initial setup
- Optional: `ldid` tool for code signing (can be installed on iPhone via Cydia/Sileo)

## Step 1: Build the Server

### Requirements:
- **macOS with Xcode** (required - iOS cross-compilation from Linux is not supported)

### Build Steps:
```bash
# Clone or download this repository
git clone https://github.com/Cfarmer29/bareiron.git
cd bareiron

# Install Xcode command line tools (if not already installed)
xcode-select --install

# Generate registries (one-time setup)
./extract_registries.sh

# Build for iOS
./build_ios.sh
```

You should now have a `bareiron_ios` binary.

**Note**: If you're on Linux, iOS compilation is not possible due to iOS SDK requirements. See `IOS_NOTES.md` for technical details.

## Step 2: Transfer to iPhone

### Find your iPhone's IP address:
On the iPhone, go to Settings → WiFi → (tap the 'i' icon) → IP Address

### Transfer via SCP:
```bash
# Default password is usually "alpine" if unchanged
scp bareiron_ios root@<iphone-ip>:/var/mobile/
```

### Alternative: Use iFunBox, Filza, or similar tools
If you prefer a GUI, use any file manager app that supports root access.

## Step 3: Set Up on iPhone

SSH into your iPhone:
```bash
ssh root@<iphone-ip>
# Password is usually "alpine" if unchanged
```

Create a directory and prepare the server:
```bash
# Create a directory for the server
mkdir -p /var/mobile/bareiron
cd /var/mobile/bareiron

# Move the binary here
mv /var/mobile/bareiron_ios .

# Make it executable
chmod +x bareiron_ios

# Sign the binary (if you have ldid installed)
ldid -S bareiron_ios
```

## Step 4: Run the Server

Start the server:
```bash
./bareiron_ios
```

You should see output like:
```
World seed (hashed): A103DE6C
RNG seed (hashed): E2B9419

No "world.bin" file found, creating one...

Server listening on port 25565...
```

## Step 5: Connect from Minecraft

1. Open Minecraft Java Edition on your computer
2. Click "Multiplayer" → "Direct Connection"
3. Enter: `<iphone-ip>:25565`
4. Click "Join Server"

You should now be connected to your iPhone-hosted Minecraft server!

## Step 6: Running in Background (Optional)

To keep the server running when you disconnect SSH:

### Using nohup (simple):
```bash
cd /var/mobile/bareiron
nohup ./bareiron_ios > server.log 2>&1 &
```

To check the log later:
```bash
tail -f /var/mobile/bareiron/server.log
```

To stop the server:
```bash
# Find the process
ps aux | grep bareiron_ios
# Kill it
kill <PID>
```

### Using screen (if installed):
```bash
# Install screen from Cydia/Sileo first
screen -S minecraft
cd /var/mobile/bareiron
./bareiron_ios

# Press Ctrl+A then D to detach
# Reattach later with: screen -r minecraft
```

## Performance Tuning for iPhone 8

If you experience lag or crashes, edit the configuration before building:

In `include/globals.h`, change:
```c
#define MAX_PLAYERS 4          // Reduce from 16
#define VIEW_DISTANCE 1        // Reduce from 2
#define MAX_BLOCK_CHANGES 10000  // Reduce from 20000
```

Then rebuild and transfer again.

## Troubleshooting

### "Permission denied" error
```bash
chmod +x bareiron_ios
ldid -S bareiron_ios  # If you have ldid
```

### "Address already in use"
Something else is using port 25565:
```bash
# Find what's using the port
lsof -i :25565
# Kill it
kill <PID>
```

### Cannot connect from Minecraft
- Make sure your computer and iPhone are on the same WiFi network
- Check iPhone's IP address in Settings → WiFi
- Try disabling any firewall on the iPhone
- Ensure the server is running: `ps aux | grep bareiron`

### Server crashes
- Check the log: `cat server.log` (if using nohup)
- Reduce settings as described in Performance Tuning
- Make sure you have enough free memory
- Keep the device plugged in to prevent thermal throttling

### Game is too slow/laggy
Edit `include/globals.h` before building:
```c
#define VIEW_DISTANCE 1          // Lower render distance
#define TIME_BETWEEN_TICKS 2000000  // Slower tick rate (2 seconds)
// #define DO_FLUID_FLOW         // Disable water flow
// #define ALLOW_CHESTS          // Disable chests
```

## Keeping the Server Running

The iPhone may kill background processes to save battery. To keep it running:

1. **Keep plugged in**: This prevents battery-saving measures
2. **Use screen/tmux**: Terminal multiplexers help persist processes
3. **Disable Auto-Lock**: Settings → Display & Brightness → Auto-Lock → Never
4. **Background execution**: Some jailbreak tweaks can help keep processes alive

## Automatic Startup (Advanced)

To start the server automatically on boot, create a launch daemon:

```bash
# Create the plist file
cat > /Library/LaunchDaemons/com.bareiron.server.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.bareiron.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/var/mobile/bareiron/bareiron_ios</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/var/mobile/bareiron</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/mobile/bareiron/server.log</string>
    <key>StandardErrorPath</key>
    <string>/var/mobile/bareiron/server.log</string>
</dict>
</plist>
EOF

# Set permissions
chmod 644 /Library/LaunchDaemons/com.bareiron.server.plist

# Load the daemon
launchctl load /Library/LaunchDaemons/com.bareiron.server.plist
```

To stop it:
```bash
launchctl unload /Library/LaunchDaemons/com.bareiron.server.plist
```

## Next Steps

- Customize the server by editing `include/globals.h` and rebuilding
- Share your iPhone's IP with friends to let them join
- Set up port forwarding on your router to allow connections from outside your network (advanced)
- Monitor battery usage and thermal performance

## Getting Help

If you encounter issues:
1. Check the troubleshooting section above
2. Review `IOS_NOTES.md` for technical details
3. Check the main `README.md` for general bareiron information
4. Look at the server log for error messages

Enjoy your pocket-sized Minecraft server! 🎮📱
