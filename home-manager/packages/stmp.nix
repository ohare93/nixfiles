{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  mpv,
  libGL,
  xorg,
}:
buildGoModule rec {
  pname = "stmp";
  version = "unstable-2024-10-19";

  src = fetchFromGitHub {
    owner = "wildeyedskies";
    repo = "stmp";
    rev = "2d5b0daf90f42c6f86ed23497c761ec2bd5ca07c";
    hash = "sha256-cIozKuMaAt2dlcOGCG5qYL3NShHAqYxgZVagPhM+E2U=";
  };

  vendorHash = "sha256-53Oat/48PtOXtITxU5j1VmHy0vCB6UzyqjDzkfZFrYI=";

  nativeBuildInputs = [pkg-config];

  buildInputs = [
    mpv
    libGL
    xorg.libX11
  ];

  # Skip tests
  doCheck = false;

  meta = with lib; {
    description = "A terminal-based Subsonic/Airsonic/Navidrome client";
    homepage = "https://github.com/wildeyedskies/stmp";
    license = licenses.gpl3Plus;
    mainProgram = "stmp";
    platforms = platforms.linux;
  };
}
