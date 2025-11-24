{
  pkgs,
  ...
}: {
  # WireGuard VPN support
  networking.wireguard.enable = true;

  # Enable WireGuard tools in system packages
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  # Open firewall port for WireGuard (if needed)
  # networking.firewall.allowedUDPPorts = [ 51820 ];
}
