{
  hostname,
  ...
}: {
  # Simple aliases that work identically in both zsh and nushell
  commonAliases = {
    # Shortcuts
    pip = "pip3";
    python = "python3";
    l = "eza --long --icons --all";

    # Git
    gitbranch = "git rev-parse --abbrev-ref HEAD";
    gitbranches = ''git for-each-ref refs/heads/ "--format=%(refname:short)"'';

    # Kanata keyboard remapping controls
    kon = "sudo systemctl start kanata-laptop";
    koff = "sudo systemctl stop kanata-laptop";
    kstatus = "sudo systemctl status kanata-laptop";

    # Audio/pipewire restart
    audio-restart = "systemctl --user restart wireplumber pipewire pipewire-pulse";
  };

  # Shell-specific aliases that need different implementations
  # Note: Nushell can't use multi-command aliases (semicolons are statement separators!)
  # All nushell multi-command aliases must be functions instead
  shellSpecificAliases = shell:
    if shell == "nu"
    then {
      # Empty for nushell - use functions instead
    }
    else {
      nrs = "sudo nixos-rebuild switch --flake ~/nixfiles#${hostname} && ${shell}";
      nrt = "sudo nixos-rebuild test --flake ~/nixfiles#${hostname}";
      nrb = "nix build ~/nixfiles#nixosConfigurations.${hostname}.config.system.build.toplevel -o /tmp/result-new && nvd diff /run/current-system /tmp/result-new";
      nixgc = "nix-collect-garbage -d && sudo nix-collect-garbage -d";
      beepcomplete = "(sox -n -t wav - synth 0.2 sine 400 | aplay; sox -n -t wav - synth 0.1 sine 500 | aplay) 2>/dev/null";
    };

  # Zsh-specific complex aliases (keep these in zsh.nix)
  zshComplexAliases = {
    sshall = ''eval "$(ssh-agent -s)" && grep -slR "PRIVATE" ~/.ssh/ | xargs ssh-add'';
    prev = ''cd ../"$(ls -F .. | grep '/' | grep -B1 -xF "''${PWD##*/}/" | head -n 1)"'';
    next = ''cd ../"$(ls -F .. | grep '/' | grep -A1 -xF "''${PWD##*/}/" | tail -n 1)"'';
    alg = ''alias | grep -i "$@"'';
    l2 = "fc -s -2 && fc -s -2";
    mysudo = ''sudo -E env "PATH=$PATH"'';
  };
}
