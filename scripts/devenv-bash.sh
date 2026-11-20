#!/usr/bin/env bash
DOTFILES=/mnt/dotfiles
MARKER="$HOME/.dotfiles-installed"

# Nothing mounted, or already done: skip
[ -d "$DOTFILES" ] || exit 0
[ -e "$MARKER" ] && exit 0

rcup -f -v -d "$DOTFILES" -B devenv
touch "$MARKER"
