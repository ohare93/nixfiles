# SD Card Longevity & System Health Optimizations
# This module implements best practices for Raspberry Pi systems using SD cards
#
# To enable: Add this to your imports in default.nix:
#   imports = [ ./sd-card-optimization.nix ];
#
# IMPORTANT: Using volatile logs means logs don't survive reboots!
# For production systems, consider a proper log2ram setup or remote logging.
{
  lib,
  pkgs,
  ...
}: {
  # ===== SD CARD WRITE REDUCTION =====

  # 1. Mount filesystem with noatime (don't update access time on reads)
  # Prevents writing timestamps every time a file is read (eliminates 1 write per read operation)
  fileSystems."/" = {
    options = ["noatime" "nodiratime"];
  };

  # 2. Temporary directories in RAM (tmpfs)
  # All temporary files live in RAM (zero SD writes, instant access, cleared on reboot)
  boot.tmp = {
    useTmpfs = true; # Mount /tmp in RAM
    tmpfsSize = "25%"; # Use up to 25% of RAM for /tmp (~2GB on 8GB Pi)
  };

  # Mount /var/tmp in RAM as well (additional temp directory used by some services)
  fileSystems."/var/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["noatime" "mode=1777" "size=512M"];
  };

  # 3. Systemd journal size limits (prevent unbounded growth)
  # Limits log size and batches writes every 5 minutes instead of constantly (reduces writes by ~70%)
  services.journald.extraConfig = ''
    SystemMaxUse=100M          # Cap total journal size at 100MB
    SystemMaxFileSize=10M      # Max 10MB per journal file
    MaxRetentionSec=7day       # Only keep 7 days of logs
    SyncIntervalSec=5m         # Flush to disk every 5 minutes instead of immediately (key optimization!)
  '';

  # 4. Alternative log management: Store volatile logs in tmpfs
  # Stores ALL system logs in RAM instead of SD card (biggest single write reduction)
  # Trade-off: logs don't survive reboots (acceptable for a rebuildable streaming client)
  fileSystems."/var/log/journal" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["noatime" "mode=0755" "size=64M"];
    neededForBoot = false;
  };

  # Keep systemd journal in memory (volatile) - logs still accessible via journalctl while running
  services.journald.storage = "volatile"; # 100% of log writes go to RAM, not disk

  # 5. No swap on SD card (use zram instead for compressed RAM swap)
  # Compressed swap in RAM (~2GB RAM → 4-6GB effective swap, zero SD writes, 1000x faster)
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # Fast compression algorithm
    memoryPercent = 25; # Use up to 25% of RAM (~2GB on 8GB Pi)
  };

  # Disable traditional swap (swap on SD card kills it fast with constant write cycles)
  swapDevices = lib.mkForce [];

  # 6. Chromium cache in tmpfs (browser creates lots of temporary writes)
  # Moves browser cache to RAM (web browsing = zero SD writes, thousands of cache writes → RAM)
  environment.etc."chromium-policies/policies.json".text = builtins.toJSON {
    DiskCacheDir = "/tmp/chromium-cache"; # /tmp is in RAM from setting #2
    DiskCacheSize = 52428800; # 50MB cache limit
  };

  # ===== MONITORING & HEALTH TOOLS =====
  # Essential tools to verify optimizations are working and catch problems early

  environment.systemPackages = with pkgs;
    [
      # Temperature and hardware monitoring
      libraspberrypi # vcgencmd: check temp, voltage, clocks, throttling

      # Disk health and I/O monitoring
      smartmontools # smartctl: SD card health SMART data
      iotop # Real-time I/O usage by process (verify low write activity)
      sysstat # iostat: disk I/O statistics (compare before/after)

      # Network monitoring (critical for streaming quality)
      nethogs # Network bandwidth per process (identify bandwidth hogs)
      mtr # Combined ping + traceroute (network diagnostics)
      iftop # Live network bandwidth monitor
      iw # WiFi interface information and stats
      wavemon # WiFi signal strength monitor (ensure good signal)

      # System monitoring
      lm_sensors # Hardware sensor readings
      inxi # Detailed system information overview

      # Performance testing
      sysbench # CPU/memory benchmarks
      iperf3 # Network throughput testing (test streaming readiness)
      hdparm # Disk read performance testing
    ]
    ++ [
      # ===== MONITORING SCRIPTS =====
      # Custom helper scripts for quick health checks and diagnostics

      # Comprehensive health check script
      (pkgs.writeScriptBin "pi-health-check" ''
        #!${pkgs.bash}/bin/bash

        echo "=== Raspberry Pi Health Check ==="
        echo ""

        # Temperature
        echo "Temperature:"
        ${pkgs.libraspberrypi}/bin/vcgencmd measure_temp

        # Throttling status (undervoltage, etc.)
        echo ""
        echo "Throttling Status:"
        THROTTLED=$(${pkgs.libraspberrypi}/bin/vcgencmd get_throttled)
        echo "$THROTTLED"
        if [[ "$THROTTLED" != "throttled=0x0" ]]; then
          echo "⚠️  WARNING: Throttling detected! Check power supply."
        fi

        # Clock speeds
        echo ""
        echo "CPU Clock Speed:"
        ${pkgs.libraspberrypi}/bin/vcgencmd measure_clock arm

        # Memory split
        echo ""
        echo "Memory Split:"
        ${pkgs.libraspberrypi}/bin/vcgencmd get_mem arm
        ${pkgs.libraspberrypi}/bin/vcgencmd get_mem gpu

        # Disk usage
        echo ""
        echo "Disk Usage:"
        df -h / | tail -n 1

        # System uptime and load
        echo ""
        echo "Uptime and Load:"
        uptime

        # Journal size
        echo ""
        echo "Journal Size:"
        journalctl --disk-usage

        # Check for filesystem errors
        echo ""
        echo "Recent Filesystem/MMC Errors:"
        dmesg | grep -i "mmc\|error" | tail -n 5 || echo "No recent errors"
      '')

      # Script for continuous temperature monitoring
      (pkgs.writeScriptBin "pi-temp-watch" ''
        #!${pkgs.bash}/bin/bash
        ${pkgs.procps}/bin/watch -n 2 -c "${pkgs.libraspberrypi}/bin/vcgencmd measure_temp"
      '')

      # Quick network latency check for streaming
      (pkgs.writeScriptBin "pi-streaming-check" ''
        #!${pkgs.bash}/bin/bash

        echo "=== Streaming Readiness Check ==="
        echo ""

        if [ $# -eq 0 ]; then
          echo "Usage: pi-streaming-check <host-ip>"
          echo "Example: pi-streaming-check 192.0.2.100"
          exit 1
        fi

        HOST=$1

        echo "Testing connection to $HOST..."
        echo ""

        # Ping test
        echo "Latency Test (10 pings):"
        ${pkgs.iputils}/bin/ping -c 10 "$HOST" | tail -n 2

        # Network throughput (requires iperf3 server on host)
        echo ""
        echo "To test throughput, run on your host:"
        echo "  iperf3 -s"
        echo "Then run here:"
        echo "  iperf3 -c $HOST"
      '')
    ];

  # ===== HARDWARE WATCHDOG =====
  # Automatically reboots if system freezes (hardware timer + systemd heartbeat)

  # Enable hardware watchdog (Pi's built-in hardware timer)
  boot.kernelParams = ["watchdog=1"];

  # Configure systemd to ping the watchdog (if systemd stops, watchdog triggers reboot)
  systemd.watchdog = {
    runtimeTime = "30s"; # Systemd must ping every 30s or system reboots
    rebootTime = "2min"; # Force hardware reboot after 2 min if soft reboot fails
  };

  # ===== AUTOMATIC MAINTENANCE =====

  # Periodic trim for SD card (tells card which blocks are free for better wear leveling)
  services.fstrim = {
    enable = true;
    interval = "weekly"; # Run TRIM once per week
  };

  # Automatic log cleanup (ensures journal never exceeds limits even if services misbehave)
  systemd.timers.journal-vacuum = {
    description = "Vacuum systemd journal";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  systemd.services.journal-vacuum = {
    description = "Vacuum systemd journal";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/journalctl --vacuum-time=7d --vacuum-size=100M";
    };
  };

  # ===== ALERTS FOR CRITICAL CONDITIONS =====

  # Automatic temperature monitoring (logs warning if CPU >80°C, which triggers throttling)
  systemd.services.temperature-monitor = {
    description = "Monitor CPU temperature";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeScript "temp-check" ''
        #!${pkgs.bash}/bin/bash
        TEMP=$(${pkgs.libraspberrypi}/bin/vcgencmd measure_temp | grep -oP '\d+\.\d+')
        TEMP_INT=''${TEMP%.*}
        if [ "$TEMP_INT" -gt 80 ]; then
          echo "WARNING: CPU temperature is ''${TEMP}°C (threshold: 80°C)" | \
            ${pkgs.systemd}/bin/systemd-cat -t temperature-monitor -p warning
        fi
      '';
    };
  };

  # Run temperature check every 5 minutes
  systemd.timers.temperature-monitor = {
    description = "Monitor CPU temperature regularly";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5min"; # First check 5 min after boot
      OnUnitActiveSec = "5min"; # Then every 5 minutes
    };
  };
}
