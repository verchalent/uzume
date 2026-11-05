{
  description = "Uzume: the toolbox environment on Fedora Kinoite (jizo), defined as a flake";

  # Pins live in flake.lock. Bump one input at a time.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # The prompt/shell experience lives in its own flake; this repo only consumes it.
    zsh-prompt = {
      url = "github:verchalent/zsh-prompt-evolution";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, zsh-prompt, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # `nix profile install github:verchalent/uzume` puts everything on PATH,
      # including `zsh-prompt` (the toolbox login shell).
      packages = forAllSystems (pkgs: {
        default = pkgs.buildEnv {
          name = "uzume-env";
          paths = [
            zsh-prompt.packages.${pkgs.stdenv.hostPlatform.system}.default
          ]
          ++ (with pkgs; [
            # Extra tools for this toolbox go here.
          ]);
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
