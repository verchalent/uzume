#!/usr/bin/env bash
# Create (or repair) the Uzume toolbox: Nix inside, environment from this flake,
# zsh-prompt as the default shell.
# Run on the Fedora Kinoite HOST, not inside a toolbox:  scripts/bootstrap.sh [name]
#
# $HOME is shared between the host and every toolbox, so this never touches
# dotfiles there (no installer profile edits, no ~/.config/nix). Everything that
# must differ per toolbox lives in the container's own /etc.
set -euo pipefail

NAME="${1:-uzume}"
NIX_VERSION="2.35.4" # pinned installer; bump deliberately
FLAKE="github:verchalent/uzume"

command -v toolbox >/dev/null || { echo "toolbox not found: run this on the Kinoite host" >&2; exit 1; }

if podman container exists "$NAME"; then
  echo "==> Toolbox '$NAME' exists; re-applying setup"
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
  nix profile install "$FLAKE"
fi

shell="$HOME/.nix-profile/bin/zsh-prompt"
echo "==> Making $shell the login shell for $user in this container"
grep -qxF "$shell" /etc/shells || echo "$shell" | sudo tee -a /etc/shells >/dev/null
sudo usermod --shell "$shell" "$user"
INNER_EOF

toolbox run -c "$NAME" env NIX_VERSION="$NIX_VERSION" FLAKE="$FLAKE" bash -c "$INNER"

echo "==> Done. Enter with: toolbox enter $NAME"
