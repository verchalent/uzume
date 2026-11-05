# GUI editors (unfree ones must also be named in the host's `unfree` list).
{ pkgs, ... }:
[
  pkgs.vscode # testing how GUI apps behave in the toolbox
  pkgs.geany
  pkgs.obsidian
  pkgs.postman
]
