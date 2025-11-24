# AI and agent development tools module
# This module provides packages and configurations needed for AI-assisted development
# and agent coding workflows, including tools required by various Claude plugins

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mynix.agentic-coding;
in
{
  options.mynix.agentic-coding = {
    enable = mkEnableOption "AI and agent development tools";
  };

  config = mkIf cfg.enable {
    # System packages required for AI/agent development workflows
    environment.systemPackages = with pkgs; [
      # Basic calculator - required for ContextBricks status line plugin cost calculations
      bc

      # Additional tools commonly needed for agent workflows
      jq          # JSON processing
      yq          # YAML processing
      ripgrep     # Fast text search
      fd          # Fast file finder
      bat         # Better cat with syntax highlighting
      eza         # Better ls
      sd          # Better sed for find-and-replace

      # Development tools for agent integrations
      gh          # GitHub CLI for PR operations
      glab        # GitLab CLI
      tea         # Gitea CLI

      # Image processing tools that agents might need
      imagemagick

      # Network tools for agent testing
      httpie      # Better curl for API testing
      websocat    # WebSocket client
    ];
  };
}