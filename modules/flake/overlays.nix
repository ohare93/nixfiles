{inputs, ...}: {
  flake.overlays =
    import ../../overlays {inherit inputs;}
    // {
      llm-agents = _final: prev: {
        llm-agents = {
          claude-code = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.claude-code;
          codex = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.codex;
          gemini-cli = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.gemini-cli;
          opencode = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.opencode;
        };
      };
      zjstatus = _final: prev: {
        zjstatus = inputs.zjstatus.packages.${prev.stdenv.hostPlatform.system}.default;
      };
      jujutsu = _final: prev: {
        jujutsu = inputs.jj.packages.${prev.stdenv.hostPlatform.system}.default;
      };
      hyprmon = _final: prev: {
        hyprmon = inputs.hyprmon.packages.${prev.stdenv.hostPlatform.system}.default;
      };
      nur = inputs.nur.overlays.default;
    };
}
