# ungoogled-chromium with extensions pinned in code.
#
# Extensions are fetched as release zips, checked by hash, and loaded with
# --load-extension, so they need no Chrome Web Store (which ungoogled-chromium
# disables) and never change unless this file does.
# To update one: bump `version`, fix the URL, and replace the hash
# (sha256 of the zip, as an SRI string). Only take releases >= 8 days old.
{ pkgs, ... }:
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

  chromium = pkgs.ungoogled-chromium;

  # Chromium writes an unpacked extension's indexed rulesets into <ext>/_metadata, so the
  # read-only /nix/store copy fails with "Internal error while parsing rules". The wrapper
  # copies each extension (once per version) to a writable, namespaced dir and loads that.
  wrapper = pkgs.writeShellScriptBin "chromium" ''
    ext_root="''${XDG_DATA_HOME:-$HOME/.local/share}/uzume/extensions"
    load=""
    for src in ${pkgs.lib.concatStringsSep " " extensions}; do
      dest="$ext_root/$(basename "$src")"
      if [ ! -d "$dest" ]; then
        mkdir -p "$dest.tmp"
        cp -rL --no-preserve=mode "$src"/. "$dest.tmp"
        mv "$dest.tmp" "$dest"
      fi
      load="''${load:+$load,}$dest"
    done
    exec ${chromium}/bin/chromium --load-extension="$load" "$@"
  '';
in
[
  (pkgs.lib.hiPrio wrapper) # wins the bin/chromium conflict
  chromium # desktop entry, icons
]
