{inputs, ...}: {
  flake.overlays =
    import ../overlays {inherit inputs;}
    // {
      claude-code = inputs.claude-code.overlays.default;
      zjstatus = _final: prev: {
        zjstatus = inputs.zjstatus.packages.${prev.system}.default;
      };
      jujutsu = _final: prev: {
        jujutsu = inputs.jj.packages.${prev.system}.default;
      };
    };
}
