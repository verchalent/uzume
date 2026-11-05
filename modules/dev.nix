# Dev tools for the toolbox. (age/sops are deliberately not here: see the secrets
# discussion in the project notes.)
{ pkgs, ... }:
[
  pkgs.python3
  pkgs.uv
  pkgs.nodejs
  pkgs.lazygit
  pkgs.lazydocker # talks to podman's socket
  pkgs.trippy
  pkgs.igrep
  pkgs.awscli2
  pkgs.claude-code # unfree, see hosts/uzume
]
