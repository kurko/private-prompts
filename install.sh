#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_DIR="$(cd "$HOME" && pwd -P)/.private-prompts"

if [ "$SCRIPT_DIR" != "$TARGET_DIR" ]; then
  echo "Error: This repo should be cloned to ~/.private-prompts"
  echo "Current location: $SCRIPT_DIR"
  exit 1
fi

# Ensure Claude config directories exist
mkdir -p ~/.claude/commands ~/.claude/skills ~/.claude/agents

# Symlink private commands/skills/agents to Claude config
for f in "$SCRIPT_DIR"/commands/*; do
  [ -e "$f" ] && ln -nfs "$f" ~/.claude/commands/
done
for f in "$SCRIPT_DIR"/skills/*; do
  [ -e "$f" ] && ln -nfs "$f" ~/.claude/skills/
done
for f in "$SCRIPT_DIR"/agents/*; do
  [ -e "$f" ] && ln -nfs "$f" ~/.claude/agents/
done

echo "Private prompts installed at ~/.private-prompts"
echo "Symlinks created in ~/.claude/{commands,skills,agents}"
echo ""
echo "If you have public dotfiles, run 'update_dotfiles' to merge them too."
