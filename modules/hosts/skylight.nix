{ inputs, lib, pkgs, config, self, ... }:
{
  flake.aspects."skylight.host" = {
    nixos = { ... }: {
      system.stateVersion = "25.05";

      # Binary cache for nixos-raspberrypi
      nix.settings = {
        substituters = [
          "https://nixos-raspberrypi.cachix.org"
        ];
        trusted-public-keys = [
          "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        ];
        # Allow jmo to use binary caches and be trusted for remote builds
        trusted-users = ["root" "jmo"];
      };

      # SSH for remote access and remote builds
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };

      # User configuration
      users.users.jmo = {
        isNormalUser = true;
        extraGroups = ["wheel"]; # Enable sudo
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdg83O1jDEsYgBAvjJCYwC1KQhzYW32gG4Tap85JtbZ4R85AWXnUu/VjkGJ15sRGkaPmhdGmplTRasISLHz6lb6g4EXOw3A39r84Ujz+G/iLnZ6eqoXbCE7NqBSe0YEohtiucULJFdutsxzOnQljZYn41smxpkIoJMpjzk5HnP1WZWQFv/jNivr9W8B2TXBycKghZ25+8Hd+1nxh9X5NcwlZ4mSJtsfILV6ed2GfvLi7Fs2ecB/zaojktV1yXvFJX2pEWU0DfheJlcSSkAqXkDl/902TtU2efeyPFfTkWH9vQSdJ80pBkZ+TmxvokxxJOUEnnyd10e/OUW9gPs/XIegwtg8/z/2NR7j+1eDgZ6sUjDQop8j+L5lIk8KHbxzVfX4Ru1lCj+Lmy6N+NNdk788CMZTaqUiO75kjQcqg5sBUQBuL973dKfZ1ySOx/sMeQKiPxehaIk8nWpgPOjzOM5IfEU3Vs4btQnz7+WM2EcyzQ1SFGppXTGJyuA60oxzagGSn06eD6wIehmZBsxRyZBAunpGS+8Zybx57eBoLRAFLi4CEOixGUEbX32sGTuRXrqdIRDdzgv78wQCA9/6s+TvWjIVV0OuJhb0zfggQFfAZrfhmOfajFSX0jCDUR8jUSqJz+CxlbTJ8iwO1pdnGifX/PLz6RP3azt0yUgRn4lyw== jmo@overton"
        ];
      };

      # Allow wheel group to use sudo without password
      security.sudo.wheelNeedsPassword = false;

      # Disable SMART monitoring - doesn't work with VirtIO disks
      services.smartd.enable = lib.mkForce false;

      # Basic tools for a build/test VM
      environment.systemPackages = with pkgs; [
        git
        htop
        tmux
        neofetch
      ];

      # Enable nix-ld for running dynamically linked executables (e.g., signal-cli)
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          stdenv.cc.cc.lib  # libstdc++
          zlib              # commonly needed
        ];
      };

      # Agenix configuration
      age.identityPaths = ["/home/jmo/.ssh/agenix"];
      age.secrets.skylight-signing-key = {
        file = inputs.self + "/secrets/skylight-signing-key.age";
        mode = "400";
      };

      mynix = {
        # Enable any common modules you want on the VM
        # This VM is primarily a headless build machine

        # Sign all built paths so other machines can receive them
        nix-signing = {
          enableSigning = true;
          signingKeyFile = config.age.secrets.skylight-signing-key.path;
        };
      };
    };
  };

  flake.aspects."skylight.home" = {
    homeManager = { lib, pkgs, inputs, ... }: {
      imports = [
        self.modules.homeManager.hm-shells
      ];

      home.packages = [
        inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.jujutsu
      ];

      programs.jujutsu.enable = lib.mkForce false;

      mynix = {
        nushell.enable = false;

        terminal-misc = {
          zoxide.enable = true;
          zellij.enable = true;
          atuin.enable = true;
          fzf.enable = false;
          carapace.enable = false;
          claude.enable = false;
          devbox.enable = false;
          comma.enable = false;
          nvd.enable = false;
          gren.enable = false;
          poetry.enable = false;
          opencode.enable = false;
        };

        devbox.enable = false;
        television.enable = false;
        yazi.enable = false;
        ssh.enable = true;
        gui-software.enable = false;
        hyprland.enable = false;
        syncthing.enable = false;
        notes.zk.enable = false;
        qutebrowser.enable = false;
      };

      programs.nvf.enable = lib.mkForce false;

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        extraConfig = ''
          set number
          set expandtab
          set tabstop=2
          set shiftwidth=2
        '';
      };
    };
  };
}
