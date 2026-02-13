{
  lib,
  buildGoModule,
  inputs,
}:
buildGoModule {
  pname = "jj-workspace-helper";
  version = "unstable";

  src = builtins.path {
    path = "${inputs.private.paths.development}/active/tools/jj-workspace-helper";
    name = "jj-workspace-helper-src";
  };

  vendorHash = "sha256-g+yaVIx4jxpAQ/+WrGKxhVeliYx7nLQe/zsGpxV4Fn4=";

  doCheck = false;

  meta = with lib; {
    description = "Workspace manager for jj workspaces";
    mainProgram = "jjw";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
