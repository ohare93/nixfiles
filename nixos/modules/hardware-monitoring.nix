{
  pkgs,
  ...
}: {
  # SMART disk monitoring for early warning of disk failures
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications = {
      mail = {
        enable = false; # Set to true and configure if you want email notifications
      };
      wall.enable = true; # Show notifications to all logged-in users
    };
  };

  # Systemd service to check for failed services
  systemd.services.check-failed-services = {
    description = "Check for failed systemd services";
    script = ''
      failed=$(${pkgs.systemd}/bin/systemctl --failed --no-legend --no-pager | wc -l)
      if [ "$failed" -gt 0 ]; then
        echo "WARNING: $failed failed systemd service(s) detected"
        ${pkgs.systemd}/bin/systemctl --failed --no-pager
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # Run the failed services check daily
  systemd.timers.check-failed-services = {
    description = "Daily check for failed systemd services";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Disk space monitoring
  systemd.services.check-disk-space = {
    description = "Check disk space usage";
    script = ''
      ${pkgs.coreutils}/bin/df -h | ${pkgs.gawk}/bin/awk '
        NR>1 && $5+0 >= 85 {
          print "WARNING: Disk usage high on", $6, "-", $5, "used"
        }
      '
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  # Run disk space check daily
  systemd.timers.check-disk-space = {
    description = "Daily disk space check";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Add monitoring tools to system packages
  environment.systemPackages = with pkgs; [
    smartmontools # For manual SMART checks
    lm_sensors # Hardware sensors monitoring
  ];
}
