#!/usr/bin/env bash
# Create (or repair) the Uzume toolbox: Nix inside, environment from this flake,
# zsh-prompt as the default interactive shell.
# Run on the Fedora Kinoite HOST, not inside a toolbox:  scripts/bootstrap.sh [--replace|--update] [name]
#
# $HOME is shared between the host and every toolbox, so this never touches
# dotfiles there (no installer profile edits, no ~/.config/nix). Everything that
# must differ per toolbox lives in the container's own /etc.
set -euo pipefail

MODE=ask # ask | replace | update
NAME=uzume
for arg in "$@"; do
  case "$arg" in
    --replace) MODE=replace ;;
    --update)  MODE=update ;;
    -h|--help) echo "usage: $0 [--replace|--update] [name]"; exit 0 ;;
    -*)        echo "unknown option: $arg" >&2; exit 2 ;;
    *)         NAME="$arg" ;;
  esac
done
NIX_VERSION="2.35.4" # pinned installer; bump deliberately
FLAKE="github:verchalent/uzume"

command -v toolbox >/dev/null || { echo "toolbox not found: run this on the Kinoite host" >&2; exit 1; }

if podman container exists "$NAME"; then
  if [ "$MODE" = ask ]; then
    if [ -t 0 ]; then
      echo "Toolbox '$NAME' already exists."
      read -r -p "[u]pdate it in place, [r]eplace it (deletes it and its /nix), or [c]ancel? [u/r/c] " ans
      case "$ans" in
        r|R) MODE=replace ;;
        u|U|"") MODE=update ;;
        *) echo "Cancelled."; exit 0 ;;
      esac
    else
      echo "Toolbox '$NAME' exists and no terminal to ask: updating in place (use --replace to recreate)"
      MODE=update
    fi
  fi
  if [ "$MODE" = replace ]; then
    echo "==> Removing toolbox '$NAME'"
    toolbox rm --force "$NAME"
  fi
fi

if podman container exists "$NAME"; then
  echo "==> Updating toolbox '$NAME' in place"
else
  echo "==> Creating toolbox '$NAME' (stock Fedora toolbox image)"
  toolbox create --assumeyes "$NAME"
fi

# Runs inside the container as the normal user (sudo is passwordless in toolbox).
read -r -d '' INNER <<'INNER_EOF' || true
set -euo pipefail
user="$(id -un)"

echo "==> Nix config (container-local /etc)"
sudo install -d /etc/nix
printf 'experimental-features = nix-command flakes\n' | sudo tee /etc/nix/nix.conf >/dev/null
# zsh reads /etc/zshenv for every invocation, so nix is on PATH without touching ~/.z*
printf 'export PATH="$HOME/.nix-profile/bin:$PATH"\n' | sudo tee /etc/zshenv >/dev/null

if [ ! -x "$HOME/.nix-profile/bin/nix" ]; then
  echo "==> Installing Nix $NIX_VERSION (single-user, no profile edits)"
  sudo install -d -o "$user" -g "$(id -gn)" /nix
  curl -fsSL "https://releases.nixos.org/nix/nix-$NIX_VERSION/install" \
    | sh -s -- --no-daemon --no-modify-profile --yes
fi
export PATH="$HOME/.nix-profile/bin:$PATH"

echo "==> Installing the Uzume environment from $FLAKE"
if nix profile list 2>/dev/null | grep -q uzume; then
  nix profile upgrade --all
else
  # --no-write-lock-file: a remote flake cannot be re-locked on the client. Until flake.lock
  # is committed in the repo, this resolves inputs unpinned (with a warning).
  nix profile add --no-write-lock-file "$FLAKE"
fi

echo "==> Handing interactive shells over to zsh-prompt (container-local /etc/profile.d)"
# toolbox enter starts the HOST user's login shell (it ignores the container's passwd),
# so bash is only a trampoline: interactive login shells exec zsh-prompt.
# Escape hatch: UZUME_NO_PROMPT=1 toolbox enter ...
sudo tee /etc/profile.d/zz-uzume.sh >/dev/null <<'PROFILE_EOF'
# Host terminfo (e.g. xterm-ghostty) is visible under /run/host in toolbox.
export TERMINFO_DIRS="${TERMINFO_DIRS:+$TERMINFO_DIRS:}/run/host/usr/share/terminfo"
case $- in
  *i*)
    if [ -z "${UZUME_NO_PROMPT:-}" ] && [ -z "${ZSH_PROMPT_STATE:-}" ] \
       && [ -x "$HOME/.nix-profile/bin/zsh-prompt" ]; then
      exec "$HOME/.nix-profile/bin/zsh-prompt"
    fi
    ;;
esac
PROFILE_EOF
INNER_EOF

toolbox run -c "$NAME" env NIX_VERSION="$NIX_VERSION" FLAKE="$FLAKE" bash -c "$INNER"

echo "==> Done. Enter with: toolbox enter $NAME"
