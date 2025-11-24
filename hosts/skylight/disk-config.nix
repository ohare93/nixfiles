# Disko configuration for unraid-vm
# Simple layout: 500MB ESP boot partition + rest for root
# Uses direct device paths (/dev/vdaX) for reliable boot - UUIDs and partlabels aren't available in initramfs
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vda"; # VirtIO disk
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
                device = "/dev/vda1";
              };
            };
            root = {
              priority = 2;
              name = "root";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                device = "/dev/vda2";
              };
            };
          };
        };
      };
    };
  };
}
