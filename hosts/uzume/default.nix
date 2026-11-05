# The `uzume` toolbox environment: which modules it uses.
# Plain data (no pkgs), so the flake can read `unfree` before building nixpkgs.
{
  # Unfree packages allowed by name, not wholesale.
  unfree = [
    "vscode"
    "claude-code"
    "obsidian"
    "postman"
  ];

  # Each module is `{ pkgs, inputs, ... }: [ package ... ]`.
  modules = [
    ../../modules/shell.nix
    ../../modules/browser.nix
    ../../modules/editors.nix
    ../../modules/dev.nix
    ../../modules/tmux.nix
    ../../modules/nix-gc.nix
  ];
}
