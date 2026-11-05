# The `uzume` toolbox environment: which modules it uses.
# Plain data (no pkgs), so the flake can read `unfree` before building nixpkgs.
{
  # Unfree packages allowed by name, not wholesale.
  unfree = [ "vscode" ];

  # Each module is `{ pkgs, inputs, ... }: [ package ... ]`.
  modules = [
    ../../modules/shell.nix
    ../../modules/browser.nix
    ../../modules/editors.nix
  ];
}
