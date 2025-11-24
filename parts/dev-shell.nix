{ ...}: {
  perSystem = {
    pkgs,
    ...
  }: {
    # Development shell for working on this configuration
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        # Nix tools
        nixd # Nix LSP server
        nil # Alternative Nix LSP
        alejandra # Nix formatter
        statix # Nix linter
        deadnix # Find dead Nix code

        # Git tools
        git

        # System management tools
        home-manager

        # Documentation
        tldr
      ];

      shellHook = ''
        echo "🔧 NixOS development environment loaded"
        echo ""
        echo "📍 Available commands:"
        echo "  sudo nixos-rebuild test --flake .#overton   # Test config without switching"
        echo "  sudo nixos-rebuild switch --flake .#overton # Apply config"
        echo "  home-manager switch --flake .                # Update home-manager"
        echo ""
        echo "🛠️  Development tools:"
        echo "  alejandra . -c      # Format all Nix files"
        echo "  statix check        # Lint Nix files"
        echo "  deadnix             # Find unused code"
        echo "  nix flake update    # Update all inputs"
        echo ""
      '';
    };

    # Make formatter available via 'nix fmt'
    formatter = pkgs.alejandra;
  };
}
