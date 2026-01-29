{
  inputs,
  self,
  private,
  ...
}: let
  inherit (inputs.nixpkgs) lib;

  # Helper function to create NixOS systems
  mkSystem = hostname:
    lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs hostname private;
        outputs = self;
      };
      modules = [
        # System configuration
        ../nixos
        ../hosts/${hostname}
        ({ ...}: {
          nixpkgs.config.allowUnfreePredicate = self.lib.allowUnfreePredicate;
          nixpkgs.config.allowBrokenPredicate = self.lib.allowBrokenPredicate;
          nixpkgs.overlays = builtins.attrValues self.overlays;
        })

        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs hostname private;
              outputs = self;
            };
            sharedModules = [inputs.agenix.homeManagerModules.default];
            users.jmo = import ../home-manager/hosts/${hostname}.nix;
          };
        }
      ];
    };

  mkWSL = hostname:
    lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs hostname private;
        outputs = self;
      };
      modules = [
        # System configuration
        ../nixos
        ({ ...}: {
          nixpkgs.config.allowUnfreePredicate = self.lib.allowUnfreePredicate;
          nixpkgs.config.allowBrokenPredicate = self.lib.allowBrokenPredicate;
          nixpkgs.overlays = builtins.attrValues self.overlays;
        })

        inputs.nixos-wsl.nixosModules.default
        {
          system.stateVersion = "25.05";
          wsl.enable = true;
          wsl.defaultUser = "jmo";
        }

        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs hostname private;
              outputs = self;
            };
            sharedModules = [inputs.agenix.homeManagerModules.default];
            users.jmo = import ../home-manager/hosts/${hostname}.nix;
          };
        }
      ];
    };

  # Helper function for Raspberry Pi systems (aarch64-linux)
  mkRPiSystem = hostname:
    inputs.nixos-raspberrypi.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit inputs hostname private;
        outputs = self;
        inherit (inputs) nixos-raspberrypi;
      };
      modules = [
        # Host configuration first (includes RPi modules)
        ../hosts/${hostname}

        # Import essential modules for keyboard and nix features
        ../nixos/modules/localisation.nix
        ../nixos/modules/nix-setup.nix
        ../nixos/modules/nix-signing.nix

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
          nixpkgs.system = "aarch64-linux";
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
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs hostname private;
              outputs = self;
            };
            sharedModules = [inputs.agenix.homeManagerModules.default];
            users.jmo = import ../home-manager/hosts/${hostname}.nix;
          };
        }
      ];
    };
in {
  # NixOS configurations
  flake.nixosConfigurations = {
    overton = mkSystem "overton";
    hatch = mkSystem "hatch";
    aperture = mkSystem "aperture";
    loophole = mkWSL "loophole";
    rectangle = mkRPiSystem "rectangle";
    skylight = mkSystem "skylight";
  };
}
