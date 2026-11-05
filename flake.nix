{
  description = "Uzume: the toolbox environment on Fedora Kinoite, defined as a flake";

  # Pins live in flake.lock. Bump one input at a time, and only to a revision at least
  # 8 days old (supply-chain cooldown, same rule as zsh-prompt-evolution), e.g.:
  #   nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/<rev>
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
      # Unfree packages are allowed one by one, not wholesale.
      unfree = [ "vscode" ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) unfree;
            }
          )
        );
    in
    {
      # `nix profile install github:verchalent/uzume` puts everything on PATH,
      # including `zsh-prompt` (the toolbox login shell).
      packages = forAllSystems (pkgs: {
        default = pkgs.buildEnv {
          name = "uzume-env";
          paths = [
            zsh-prompt.packages.${pkgs.stdenv.hostPlatform.system}.default
            (import ./modules/browser.nix { inherit pkgs; })
          ]
          ++ (with pkgs; [
            # Extra tools for this toolbox go here.
            vscode # testing how GUI apps behave in the toolbox
          ]);
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
