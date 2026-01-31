{
  inputs,
  self,
  private,
  ...
}: let
  inherit (inputs.nixpkgs) lib;

  hasNixosAspectPath = path:
    lib.hasAttrByPath (["nixos"] ++ path) self.modules;

  hasHomeAspectPath = path:
    lib.hasAttrByPath (["homeManager"] ++ path) self.modules;

  hostManifest = import (inputs.self + "/defs/hosts/manifest.nix");
  hosts = hostManifest.hosts;

  mkNixpkgsConfig = {
    nixpkgs.config.allowUnfreePredicate = self.lib.allowUnfreePredicate;
    nixpkgs.config.allowBrokenPredicate = self.lib.allowBrokenPredicate;
    nixpkgs.overlays = builtins.attrValues self.overlays;
  };

  mkHomeManager = hostname:
    let
      homeKey = "${hostname}.home";
      homeModule =
        if hasHomeAspectPath [homeKey]
        then self.modules.homeManager.${homeKey}
        else builtins.throw "Missing Home Manager aspect: flake.aspects.\"${homeKey}\"";
    in {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inherit inputs hostname private;
          outputs = self;
        };
        sharedModules = [inputs.agenix.homeManagerModules.default];
        users.jmo = {
          imports = [
            self.modules.homeManager.definitions
            self.modules.homeManager.base
            homeModule
          ];
        };
      };
    };

  # Helper function to create NixOS systems
  mkSystem = hostname:
    let
      hostKey = "${hostname}.host";
      hardwareKey = "${hostname}.hardware";
      useHostAspect = hasNixosAspectPath [hostKey];
      useHardwareAspect = hasNixosAspectPath [hardwareKey];
      hostModule =
        if useHostAspect
        then self.modules.nixos.${hostKey}
        else builtins.throw "Missing NixOS host aspect: flake.aspects.\"${hostKey}\"";
    in
    lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs hostname private;
        outputs = self;
      };
      modules =
        [
          # System configuration
          self.modules.nixos.definitions
          self.modules.nixos.base
        ]
        ++ [hostModule]
        ++ lib.optional useHardwareAspect self.modules.nixos.${hardwareKey}
        ++ [
          ({ ...}: mkNixpkgsConfig)
          inputs.agenix.nixosModules.default
          inputs.home-manager.nixosModules.home-manager
          (mkHomeManager hostname)
        ];
    };

  mkWSL = hostname:
    let
      hostKey = "${hostname}.host";
      useHostAspect = hasNixosAspectPath [hostKey];
      hostModule =
        if useHostAspect
        then self.modules.nixos.${hostKey}
        else builtins.throw "Missing NixOS host aspect: flake.aspects.\"${hostKey}\"";
    in
    lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs hostname private;
        outputs = self;
      };
      modules =
        [
          # System configuration
          self.modules.nixos.definitions
          self.modules.nixos.base
        ]
        ++ [hostModule]
        ++ [
          ({ ...}: mkNixpkgsConfig)

          inputs.nixos-wsl.nixosModules.default
          {
            system.stateVersion = "25.05";
            wsl.enable = true;
            wsl.defaultUser = "jmo";
          }

          inputs.agenix.nixosModules.default
          inputs.home-manager.nixosModules.home-manager
          (mkHomeManager hostname)
        ];
    };

  # Helper function for Raspberry Pi systems (aarch64-linux)
  mkRPiSystem = hostname:
    let
      hostKey = "${hostname}.host";
      hardwareKey = "${hostname}.hardware";
      useHostAspect = hasNixosAspectPath [hostKey];
      useHardwareAspect = hasNixosAspectPath [hardwareKey];
      hostModule =
        if useHostAspect
        then self.modules.nixos.${hostKey}
        else builtins.throw "Missing NixOS host aspect: flake.aspects.\"${hostKey}\"";
    in
    inputs.nixos-raspberrypi.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit inputs hostname private;
        outputs = self;
        inherit (inputs) nixos-raspberrypi;
      };
      modules = [
        # Host configuration first (includes RPi modules)
        # Host and hardware aspects when available
      ]
      ++ [hostModule]
      ++ lib.optional useHardwareAspect self.modules.nixos.${hardwareKey}
      ++ [

        # Import essential modules for keyboard and nix features
        (inputs.self + "/defs/nixos/localisation.nix")
        (inputs.self + "/defs/nixos/nix-setup.nix")
        (inputs.self + "/defs/nixos/nix-signing.nix")

        # Then common system configuration
        # Note: ./nixos imports are selective to avoid conflicts with RPi modules
        ({ ...}: {
          nixpkgs.config.allowUnfreePredicate = self.lib.allowUnfreePredicate;
          nixpkgs.config.allowBrokenPredicate = self.lib.allowBrokenPredicate;
          # Allow broken packages on aarch64 (many dev tools marked broken but work fine)
          nixpkgs.config.allowBroken = true;
          # Allow insecure qtwebengine for KDE Plasma (required for some apps)
          nixpkgs.config.permittedInsecurePackages = [
            "qtwebengine-5.15.19"
          ];
          nixpkgs.overlays = builtins.attrValues self.overlays;
          # Use native aarch64 builds with QEMU emulation (leverages binary cache)
          nixpkgs.hostPlatform.system = "aarch64-linux";
        })

        # Import only the specific common modules that don't conflict
        {
          networking.hostName = hostname;
          networking.networkmanager.enable = true;

          programs.nh = {
            enable = true;
            flake = "/home/jmo/nixfiles";
          };

          environment.systemPackages = with inputs.nixpkgs.legacyPackages.aarch64-linux; [
            wget
            curl
            git
            htop
            tree
            tldr
            unzip
            zip
            p7zip
            gnutar
            gzip
            bzip2
            xz
            rsync
            file
            which
            netcat
            nodejs
            home-manager
          ];

          fonts.packages = with inputs.nixpkgs.legacyPackages.aarch64-linux; [nerd-fonts.hasklug];
          programs.neovim.enable = true;
          programs.zsh.enable = true;

          users.users.jmo = {
            isNormalUser = true;
            description = inputs.private.identity.fullName;
            extraGroups = ["networkmanager" "wheel"];
            shell = inputs.nixpkgs.legacyPackages.aarch64-linux.zsh;
            packages = [];
          };
        }

        # Home-manager integration for user configurations
        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        (mkHomeManager hostname)
      ];
    };

  mkHost = hostname: host:
    if host.kind == "rpi" then
      mkRPiSystem hostname
    else if host.kind == "wsl" then
      mkWSL hostname
    else
      mkSystem hostname;
in {
  # NixOS configurations
  flake.nixosConfigurations = lib.mapAttrs mkHost hosts;
}
