# Overlays for custom packages and modifications
{inputs, ...}: {
  # Example overlay can be added here
  # default = (final: prev: {
  #   # Your modifications here
  # });

  # Neorg overlay for proper plugin and grammar support
  neorg = inputs.neorg-overlay.overlays.default;
}
