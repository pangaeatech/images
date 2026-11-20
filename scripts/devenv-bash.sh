#!/usr/bin/env bash
DOTFILES=/mnt/dotfiles
MARKER="$HOME/.dotfiles-installed"

if [ -e "$MARKER" ]; then
  echo "Dotfiles already installed. Skipping."
elif [ ! -d "$DOTFILES" ]; then
  echo "Dotfiles directory not found. Skipping."
else
  echo "Installing dotfiles..."

  rcup -f -v -d "$DOTFILES" -B devenv
  touch "$MARKER"
fi
