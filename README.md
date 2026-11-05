# uzume

A Nix-defined toolbox environment for an atomic Fedora system (Kinoite): a writable userland
container whose contents come from a flake instead of manual installs.
The shell experience itself lives in
[zsh-prompt-evolution](https://github.com/verchalent/zsh-prompt-evolution);
this repo consumes it and adds whatever else the toolbox needs.

Layout (same idea as IsildursBane-Nix: reusable modules, per-environment selection):

```
flake.nix            # wiring only: builds one package per environment
hosts/<name>/        # an environment: which modules it uses, and which unfree packages it allows
modules/             # reusable pieces; each is { pkgs, inputs, ... }: [ package ... ]
  shell.nix          #   zsh-prompt (from the zsh-prompt-evolution flake)
  browser.nix        #   ungoogled-chromium + hash-pinned extensions (uBlock Origin Lite)
  editors.nix        #   GUI editors
scripts/bootstrap.sh # run on the host: creates the toolbox, installs Nix and the environment
```

`packages.<system>.default` is the `uzume` environment (`uzume-env`).
Bootstrap installs it and makes `zsh-prompt` the default interactive shell (a container-local
`/etc/profile.d` hook; `UZUME_NO_PROMPT=1` skips it). Nothing in the shared `$HOME` is edited;
per-container config goes in the container's `/etc`.

```sh
scripts/bootstrap.sh            # create or repair the toolbox
toolbox enter uzume             # lands in zsh-prompt
```

Change what's in the toolbox: edit a module (or the host list), push, then in the toolbox
`nix profile upgrade --all`. Rebuild from scratch: `toolbox rm uzume`, run the bootstrap again.
