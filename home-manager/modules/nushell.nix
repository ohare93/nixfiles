{
  lib,
  config,
  pkgs,
  hostname,
  ...
}: let
  cfg = config.mynix.nushell;
  sharedAliases = import ./shared-aliases.nix {inherit lib hostname;};

  # Convert attribute set of aliases to nushell alias commands
  makeNushellAliases = aliases:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "alias ${name} = ${value}") aliases);
in
  with lib; {
    options.mynix = {
      nushell = {
        enable = mkEnableOption "nushell shell";
        showAliasExpansion = mkOption {
          type = types.bool;
          default = true;
          description = "Show alias expansion before command execution for learning";
        };
      };
    };

    config = mkIf cfg.enable {
      home.packages = [pkgs.nushell];

      programs.nushell = {
        enable = true;

        extraConfig =
          ''
            $env.config.show_banner = false
            $env.config.edit_mode = 'vi'
            $env.config.cursor_shape = {
              vi_insert: line
              vi_normal: block
            }
          ''
          + lib.optionalString cfg.showAliasExpansion ''

            # Show alias/function expansion before execution (for learning)
            $env.config.hooks = {
              pre_execution: [{||
                let cmd = (commandline)
                if ($cmd | is-empty) { return }

                let first_word = ($cmd | split row ' ' | first)

                # Check if it's an alias
                let alias_matches = (help aliases | where name == $first_word)
                if ($alias_matches | is-not-empty) {
                  let expansion = ($alias_matches | get expansion | first)
                  print $"\u{001b}[2m→ ($expansion)\u{001b}[0m"
                } else {
                  # Check if it's a custom function
                  let custom_cmds = (help commands | where command_type == "custom" | where name == $first_word)
                  if ($custom_cmds | is-not-empty) {
                    let sig = ($custom_cmds | get signatures | first | values | first)
                    print $"\u{001b}[2m→ [function: ($first_word)]\u{001b}[0m"
                  }
                }
              }]
            }
          ''
          + ''

            # Shared aliases
            ${makeNushellAliases sharedAliases.commonAliases}
            ${makeNushellAliases (sharedAliases.shellSpecificAliases "nu")}

            # Nushell-specific aliases and functions
            alias docker = podman

            def nufzf [] {$in | each {|i| $i | to json --raw} | str join "\n" | fzf  | from json}

            # Complex command implementations for nushell
            # These MUST be functions because nushell aliases can't have multiple commands
            def nrs [] {
              sudo nixos-rebuild switch --flake ~/nixfiles#${hostname}
              nu
            }

            def nrt [] {
              sudo nixos-rebuild test --flake ~/nixfiles#${hostname}
            }

            def nrb [] {
              nix build ~/nixfiles#nixosConfigurations.${hostname}.config.system.build.toplevel -o /tmp/result-new
              nvd diff /run/current-system /tmp/result-new
            }

            def nixgc [] {
              nix-collect-garbage -d
              sudo nix-collect-garbage -d
            }

            def h [] {
              z ~/
              l
            }

            def beepcomplete [] {
              do -i { sox -n -t wav - synth 0.2 sine 400 | aplay o+e>| ignore }
              do -i { sox -n -t wav - synth 0.1 sine 500 | aplay o+e>| ignore }
            }

            def sshall [] {
              ^eval (ssh-agent -s | lines | parse "{name}={value}; export {name_export};" | get value | first)
              ^grep -slR "PRIVATE" ~/.ssh/ | lines | each {|f| ssh-add $f}
            }

            def prev [] {
              let current = ($env.PWD | path basename)
              let parent = ($env.PWD | path dirname)
              let dirs = (ls -D $parent | where type == dir | get name | path basename)
              let idx = ($dirs | enumerate | where item == $current | get index | first)
              if $idx > 0 {
                cd ($parent | path join ($dirs | get ($idx - 1)))
              }
            }

            def next [] {
              let current = ($env.PWD | path basename)
              let parent = ($env.PWD | path dirname)
              let dirs = (ls -D $parent | where type == dir | get name | path basename)
              let idx = ($dirs | enumerate | where item == $current | get index | first)
              if $idx < (($dirs | length) - 1) {
                cd ($parent | path join ($dirs | get ($idx + 1)))
              }
            }

            def alg [search: string] {
              help aliases | where name =~ $search
            }

            def mysudo [...command] {
              sudo -E env $"PATH=($env.PATH | str join ':')" ...$command
            }

            def toggle-monitor [] {
              let current = (hyprctl monitors -j | from json | where name == "DVI-I-1" | get width | first)
              if $current == 5120 {
                hyprctl keyword monitor DVI-I-1,preferred,0x0,1.25
                notify-send "Monitor" "Preferred (PIP mode)"
              } else {
                hyprctl keyword monitor DVI-I-1,5120x1440@59.98,0x0,1.25
                notify-send "Monitor" "5120x1440 (full width)"
              }
            }
          ''
          + (
            if config.mynix.terminal-misc.atuin.enable
            then ''

              # Atuin integration - manually added with fixed deprecation warning
              # Source: https://github.com/atuinsh/atuin/blob/main/atuin/src/shell/atuin.nu
              # Fixed: Changed 'get -i' to 'get -o' for nushell 0.106+
              source ~/.local/share/atuin/init.nu
            ''
            else ""
          );

        extraEnv =
          ''
            $env.EDITOR = 'nvim'

            # Add local bin to PATH if it exists
            if ($"($env.HOME)/.local/bin" | path exists) {
              $env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/bin")
            }

            # Source private keys if file exists
            if ("~/.nushell_private_keys.nu" | path expand | path exists) {
              source ~/.nushell_private_keys.nu
            }
          ''
          + (
            if config.mynix.terminal-misc.atuin.enable
            then ''

              # Generate atuin config with deprecation warning fixed
              if (which atuin | is-not-empty) {
                let atuin_cache = $"($env.HOME)/.local/share/atuin"
                mkdir $atuin_cache
                let atuin_config = $"($atuin_cache)/init.nu"
                # Replace ALL deprecated 'get -i' with 'get -o' for nushell 0.106+
                atuin init nu | str replace --all 'get -i' 'get -o' | save -f $atuin_config
              }
            ''
            else ""
          );
      };
    };
  }
