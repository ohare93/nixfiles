{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.mynix.karakeep;
  customPackages = import ./packages {inherit pkgs lib;};
in
  with lib; {
    options.mynix = {
      karakeep = {
        enable = mkEnableOption "Karakeep CLI via MCP bridge";
      };
    };

    config = mkIf cfg.enable {
      mynix.host-env.enable = true;

      home.packages = [
        customPackages.mcptools
        pkgs.nodejs
      ];

      programs.zsh.shellAliases = {
        kk-tools = "mcptools tools npx -y @karakeep/mcp@0.29.0";
      };

      programs.zsh.initContent = lib.mkOrder 200 ''
        kk() { mcptools call "$@" npx -y @karakeep/mcp@0.29.0; }
      '';
    };
  }
