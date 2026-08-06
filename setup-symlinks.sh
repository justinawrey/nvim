#!/usr/bin/env bash
#
# Idempotent symlink setup for this config repo.
#
# This repo is the single source of truth for nvim, ghostty and lazygit
# configs. Ghostty and lazygit read from fixed locations outside the repo,
# so this script points those locations back here via symlinks.
#
# Safe to run repeatedly: correct links are left alone, wrong links are
# repaired, and pre-existing real files are backed up rather than clobbered.
#
#   ./setup-symlinks.sh

set -euo pipefail

# Resolve the repo from this script's own location, so the links work
# regardless of username or checkout path.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

changed=0

link() {
  local src="$1" dst="$2" current backup

  if [[ ! -e "$src" ]]; then
    printf 'MISSING  %s (source does not exist)\n' "$src" >&2
    return 1
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" ]]; then
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      printf 'OK       %s\n' "$dst"
      return 0
    fi
    printf 'RELINK   %s (was -> %s)\n' "$dst" "$current"
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup"
    printf 'BACKUP   %s -> %s\n' "$dst" "$backup"
  fi

  ln -s "$src" "$dst"
  printf 'LINKED   %s -> %s\n' "$dst" "$src"
  changed=1
}

# nvim itself is not symlinked; it is expected to live at ~/.config/nvim.
if [[ "$REPO_DIR" != "$HOME/.config/nvim" ]]; then
  printf 'WARNING  repo is at %s, but nvim expects ~/.config/nvim\n' "$REPO_DIR" >&2
fi

# ghostty
link "$REPO_DIR/ghostty/config" "$HOME/.config/ghostty/config"

# lazygit (macOS uses Application Support; elsewhere XDG)
case "$(uname -s)" in
  Darwin) lazygit_dst="$HOME/Library/Application Support/lazygit/config.yml" ;;
  *)      lazygit_dst="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/config.yml" ;;
esac
link "$REPO_DIR/lazygit.yml" "$lazygit_dst"

if [[ "$changed" -eq 0 ]]; then
  printf '\nAll symlinks already correct.\n'
else
  printf '\nDone.\n'
fi
