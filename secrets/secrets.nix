let
  jmo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILdgGZYNs0YHP0/NA0eeqgROqq89lYla4fJpwmG3yXLX agenix secrets";
in {
  "secrets/ntfy-token.age".publicKeys = [jmo];
  "secrets/stmp-password.age".publicKeys = [jmo];
  "secrets/skylight-signing-key.age".publicKeys = [jmo];
  "secrets/overton-signing-key.age".publicKeys = [jmo];
  "secrets/jmo-password-hash.age".publicKeys = [jmo];
  "secrets/overton-env.age".publicKeys = [jmo];
}
