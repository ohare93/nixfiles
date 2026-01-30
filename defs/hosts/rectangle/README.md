# Rectangle - Raspberry Pi 5 Streaming Client

A Raspberry Pi 5 configured as a dedicated streaming client for gaming (Moonlight) and media (Jellyfin).

## Quick Reference

### Health Check Commands

```bash
# Overall system health
pi-health-check

# Watch temperature continuously
pi-temp-watch

# Check network readiness for streaming
pi-streaming-check <host-ip>
```

### Hardware Info

```bash
# Temperature
vcgencmd measure_temp

# Check for undervoltage/throttling
vcgencmd get_throttled

# CPU speed
vcgencmd measure_clock arm

# Memory split
vcgencmd get_mem arm && vcgencmd get_mem gpu
```

## Files in This Directory

- **`default.nix`** - Main system configuration
- **`hardware-configuration.nix`** - Auto-generated hardware config
- **`sd-card-optimization.nix`** - Optional SD card longevity optimizations
- **`PI-BEST-PRACTICES.md`** - Comprehensive guide to Pi maintenance and tools
- **`README.md`** - This file

## SD Card Optimization (Optional)

The `sd-card-optimization.nix` module implements best practices to extend SD card lifespan:

- Reduces writes by 80-90%
- Mounts temporary directories in RAM
- Uses zram for compressed swap (no disk writes)
- Monitors system health automatically
- Includes helpful diagnostic scripts

### To Enable:

Add to your `imports` in `default.nix`:

```nix
imports = [
  ./hardware-configuration.nix
  ./sd-card-optimization.nix  # Add this line
  # ... other imports
];
```

### Trade-offs:

**Pros:**
- Dramatically extends SD card lifespan (years instead of months)
- Faster system (less I/O overhead)
- Includes monitoring tools and health checks

**Cons:**
- Logs don't persist across reboots (fine for home streaming client)
- Uses more RAM (~300-500MB for tmpfs)

For a streaming client that you can easily rebuild, the trade-off is excellent.

## Recommended Power Supply

**Critical:** Use the official Raspberry Pi 5 27W USB-C power supply.

Undervoltage causes:
- Random crashes and freezes
- Data corruption on SD card
- Throttled performance
- Shortened hardware lifespan

Check for undervoltage: `vcgencmd get_throttled`
- `0x0` = Good
- Anything else = Power supply issue

## Cooling Recommendations

The Pi 5 runs warm, especially during streaming:

- **Passive (recommended):** Heatsink case (keeps under 70°C)
- **Active:** Active cooler (keeps under 50°C) - quieter than you'd think
- **Minimum:** Official heatsink

Monitor with: `pi-temp-watch`

## Network Recommendations

For best streaming experience:

1. **Wired Ethernet > WiFi** (lower latency, more stable)
2. **WiFi 5GHz > 2.4GHz** (less congestion)
3. **Close to router** if using WiFi

Test latency: `pi-streaming-check <gaming-pc-ip>`

Acceptable latency:
- Excellent: <2ms (wired)
- Good: 2-5ms
- Playable: 5-15ms
- Noticeable lag: >15ms

## Backup Strategy

### Configuration
Your nixfiles repo IS your backup. Just:
```bash
git add .
git commit -m "Update rectangle config"
git push
```

### Full SD Card Image (Optional)

From another Linux machine:
```bash
# Backup
sudo dd if=/dev/sdX bs=4M status=progress | gzip > rectangle-backup-$(date +%Y%m%d).img.gz

# Restore
gunzip -c rectangle-backup-YYYYMMDD.img.gz | sudo dd of=/dev/sdX bs=4M status=progress
```

### Important Files to Backup
- SSH keys: `~/.ssh/`
- Game configs: `~/.config/moonlight/`
- Jellyfin settings: `~/.config/jellyfin/`

## Troubleshooting

### Streaming is Laggy

1. Check network latency: `pi-streaming-check <host-ip>`
2. Check temperature: `pi-temp-watch` (throttling at 80°C)
3. Check for undervoltage: `vcgencmd get_throttled`
4. Try wired Ethernet
5. Lower streaming quality in Moonlight

### System Feels Slow

1. Check temperature (throttling?)
2. Check disk I/O: `iostat -x 5`
3. Check processes: `htop`
4. Check SD card errors: `dmesg | grep -i mmc`

### Won't Boot / Filesystem Read-Only

Likely SD card failure:
1. Try another SD card
2. Rebuild from nixfiles on new card
3. Restore backup image if you have one

### WiFi Disconnects

1. Check signal strength: `wavemon`
2. Check for interference (use 5GHz)
3. Update RPi firmware: `sudo rpi-eeprom-update`
4. Consider wired Ethernet

## Maintenance Schedule

**Weekly:**
- Check system health: `pi-health-check`
- Review for undervoltage events

**Monthly:**
- Update system: `sudo nixos-rebuild switch --upgrade`
- Push config changes to git

**Every 6 Months:**
- Full SD card backup image (optional)
- Clean dust from case/heatsink

## Useful Resources

- [PI-BEST-PRACTICES.md](./PI-BEST-PRACTICES.md) - Detailed guide
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [Moonlight Setup Guide](https://github.com/moonlight-stream/moonlight-docs/wiki)
- [Jellyfin Client Docs](https://jellyfin.org/docs/)

## Hardware Specs

- **Model:** Raspberry Pi 5
- **RAM:** 8GB
- **Storage:** MicroSD card (recommend Class 10 / A2 / UHS-I)
- **Display:** Whatever you connect via HDMI
- **Input:** Bluetooth (Xbox controller via xpadneo)
- **Network:** WiFi 6 / Gigabit Ethernet
