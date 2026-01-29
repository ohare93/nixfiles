{inputs, ...}: {
  flake.overlays =
    import ../overlays {inherit inputs;}
    // {
      llm-agents = _final: prev: {
        llm-agents = {
          claude-code = inputs.llm-agents.packages.${prev.system}.claude-code;
          codex = inputs.llm-agents.packages.${prev.system}.codex;
          gemini-cli = inputs.llm-agents.packages.${prev.system}.gemini-cli;
          opencode = inputs.llm-agents.packages.${prev.system}.opencode;
        };
      };
      zjstatus = _final: prev: {
        zjstatus = inputs.zjstatus.packages.${prev.system}.default;
      };
      jujutsu = _final: prev: {
        jujutsu = inputs.jj.packages.${prev.system}.default;
      };
      hyprmon = _final: prev: {
        hyprmon = inputs.hyprmon.packages.${prev.system}.default;
      };
      nur = inputs.nur.overlays.default;
    };
}
