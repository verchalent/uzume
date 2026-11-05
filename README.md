# uzume

A Nix-defined toolbox environment for an atomic Fedora system (Kinoite): a writable userland
container whose contents come from a flake instead of manual installs.
The shell experience itself lives in
[zsh-prompt-evolution](https://github.com/verchalent/zsh-prompt-evolution);
this repo consumes it and adds whatever else the toolbox needs.

- `flake.nix`: `packages.<system>.default` = `uzume-env` (zsh-prompt plus extra tools).
- `scripts/bootstrap.sh`: run on the Kinoite host. Creates the toolbox, installs Nix inside
  it, installs `uzume-env`, and makes `zsh-prompt` the container's login shell.
  Nothing in the shared `$HOME` is edited; per-container config goes in the container's `/etc`.

```sh
scripts/bootstrap.sh            # create or repair the toolbox
toolbox enter uzume             # lands in zsh-prompt
```

Change what's in the toolbox: edit `flake.nix`, push, then in the toolbox
`nix profile upgrade --all`. Rebuild from scratch: `toolbox rm uzume`, run the bootstrap again.
