let
  jmo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILdgGZYNs0YHP0/NA0eeqgROqq89lYla4fJpwmG3yXLX agenix secrets";
in {
  "ntfy-token.age".publicKeys = [jmo];
  "stmp-password.age".publicKeys = [jmo];
  "skylight-signing-key.age".publicKeys = [jmo];
  "overton-signing-key.age".publicKeys = [jmo];
}
