# ungoogled-chromium with extensions pinned in code.
#
# Extensions are fetched as release zips, checked by hash, and loaded with
# --load-extension, so they need no Chrome Web Store (which ungoogled-chromium
# disables) and never change unless this file does.
# To update one: bump `version`, fix the URL, and replace the hash
# (sha256 of the zip, as an SRI string). Only take releases >= 8 days old.
{ pkgs }:
let
  ublockLite =
    let
      version = "2026.1026.1812";
    in
    pkgs.runCommand "ublock-origin-lite-${version}"
      {
        nativeBuildInputs = [ pkgs.unzip ];
        src = pkgs.fetchurl {
          url = "https://github.com/uBlockOrigin/uBOL-home/releases/download/${version}/uBOLite_${version}.chromium.zip";
          hash = "sha256-03iOrJ8KRMZ/N0WkPD/URu8z1WsRIfRpsZ4PoKg2wrU=";
        };
      }
      ''
        mkdir -p $out
        unzip -q $src -d $out
      '';

  extensions = [ ublockLite ];
in
pkgs.ungoogled-chromium.override {
  commandLineArgs = "--load-extension=${pkgs.lib.concatStringsSep "," extensions}";
}
