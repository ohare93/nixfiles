{inputs, ...}: {
  # Package outputs for x86_64-linux (build machine)
  flake.packages.x86_64-linux = {
    # Pre-built RPi5 installer from nixos-raspberrypi (downloads from cache)
    rpi5-installer = inputs.nixos-raspberrypi.installerImages.rpi5;
  };
}
