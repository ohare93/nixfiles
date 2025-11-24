# Raspberry Pi Best Practices & Tools Guide

This guide covers essential tools and configurations to keep your Raspberry Pi 5 "rectangle" running smoothly and extend SD card lifespan.

## SD Card Health & Longevity

SD cards have limited write cycles. Reducing unnecessary writes dramatically extends their lifespan.

### 1. Log2RAM (Critical)
Stores logs in RAM and periodically syncs to disk. This is the single most important optimization.

**Benefits:**
- Reduces constant log writes from hundreds/thousands per day to a few syncs
- Logs survive reboots (synced before shutdown)
- Can reduce writes by 80-90%

### 2. Filesystem Mount Options
Use `noatime` to prevent updating file access timestamps on every read.

**Impact:** Eliminates one write operation per file read.

### 3. Temporary Directories in tmpfs
Mount `/tmp`, `/var/tmp`, and browser caches in RAM.

**Impact:** Zero disk writes for temporary files.

### 4. Systemd Journal Limits
Limit journal size to prevent unbounded growth.

**Recommended:** 50-100MB max, 7-14 day retention.

### 5. Swap Management
Options:
- **No swap:** Best for SD cards (you have 8GB RAM)
- **zram:** Compressed RAM swap (no disk writes)
- **Avoid disk swap:** Creates constant write cycles

### 6. Browser Profile in tmpfs
Chromium's cache and temporary data cause heavy writes.

**Solution:** Mount browser cache to tmpfs or disable disk cache.

## Essential Monitoring Tools

### Temperature Monitoring
```bash
# Built-in RPi tool
vcgencmd measure_temp

# Watch continuously
watch -n 2 vcgencmd measure_temp
```

**Thresholds:**
- Normal: 40-60°C
- Warm: 60-75°C
- Throttling starts: 80°C
- Shutdown: 85°C

### Disk Health & Usage
```bash
# Check SD card health (requires smartmontools)
sudo smartctl -a /dev/mmcblk0

# Monitor I/O stats
iostat -x 5

# Check for filesystem errors
sudo dmesg | grep -i "mmc\|error"
```

### System Resources
- `htop` - Interactive process viewer (already installed)
- `iotop` - I/O usage by process
- `nethogs` - Network usage by process

## Hardware-Specific Tools

### RPi Firmware & EEPROM
```bash
# Update firmware
sudo rpi-eeprom-update

# Check current version
sudo rpi-eeprom-update -a
```

### GPU/Hardware Info
```bash
# GPU memory split
vcgencmd get_mem arm && vcgencmd get_mem gpu

# Codec enabled status
vcgencmd codec_enabled H264

# Current clock speeds
vcgencmd measure_clock arm
vcgencmd measure_clock core
```

## Backup Strategies

### SD Card Imaging (from another machine)
```bash
# Create compressed backup
sudo dd if=/dev/sdX bs=4M status=progress | gzip > rectangle-backup-$(date +%Y%m%d).img.gz

# Restore
gunzip -c rectangle-backup-YYYYMMDD.img.gz | sudo dd of=/dev/sdX bs=4M status=progress
```

### NixOS Configuration Backup
Your nixfiles repo IS your backup! Just:
1. Commit configuration changes regularly
2. Push to remote repository
3. Rebuilding from scratch is `nixos-rebuild`

### User Data Backup
Since rectangle is a streaming client, consider:
- Backup SSH keys and authorized_keys
- Backup any saved game configurations
- Jellyfin watch history (if stored locally)

## Network Reliability

### Watchdog Timer
Automatically reboots if system becomes unresponsive.

**Recommended:** Enable hardware watchdog for unattended systems.

### Connection Monitoring
For headless operation, monitor network connectivity and auto-reconnect.

## Power Management

### Undervoltage Detection
```bash
# Check for undervoltage events (bit 16 = under-voltage occurred)
vcgencmd get_throttled
```

**Result codes:**
- `0x0`: No issues
- `0x50000`: Past under-voltage (use better power supply!)
- `0x50005`: Current under-voltage (critical!)

**Solution:** Use official RPi 5 27W USB-C power supply.

### Power-Efficient Settings
For 24/7 operation:
- Disable unused interfaces (HDMI when streaming)
- Set appropriate GPU memory split
- Enable CPU governor (ondemand or schedutil)

## Useful Utilities

### System Information
- `neofetch` - Pretty system info
- `inxi` - Detailed hardware info
- `lsblk` - Block device info
- `lsusb` / `lspci` - Connected devices (already have pciutils/usbutils)

### Network Tools
- `mtr` - Network diagnostic tool (traceroute + ping)
- `iftop` - Network bandwidth monitor
- `wavemon` - WiFi signal monitor

### Performance Testing
- `sysbench` - CPU/memory benchmarks
- `iperf3` - Network throughput testing
- `hdparm` - Disk read testing

## Streaming-Specific Optimizations

### For Moonlight (Game Streaming)
- Ensure GPU memory split adequate (128MB minimum)
- Monitor network latency (`ping -f GAMEPC`)
- Use wired Ethernet if possible (lower latency than WiFi)
- Check for thermal throttling during gaming sessions

### For Jellyfin
- Hardware video decode support (V4L2/DRM)
- Adequate GPU memory for video processing
- Monitor temperature during 4K playback

## Red Flags to Watch

1. **Frequent undervoltage warnings** → Replace power supply
2. **Temperature constantly >75°C** → Improve cooling (heatsink/fan)
3. **High iowait in htop** → SD card may be failing or too slow
4. **Filesystem becomes read-only** → SD card failure imminent
5. **Random freezes/crashes** → Check logs for hardware errors

## Maintenance Schedule

**Daily (automatic):**
- Log rotation and cleanup
- Temperature monitoring

**Weekly:**
- Check for undervoltage events
- Review system logs for errors
- Monitor disk usage

**Monthly:**
- Update system packages (`nixos-rebuild switch --upgrade`)
- Check EEPROM/firmware updates
- Verify backup strategy working

**Every 6 months:**
- Full SD card backup image
- Consider SD card replacement (preventive)

## When to Replace SD Card

**Warning signs:**
- Frequent read/write errors in dmesg
- Filesystem corruption
- Noticeably slower performance
- Age >2-3 years with heavy use

**Tip:** Keep a spare SD card with a recent image for quick replacement.
