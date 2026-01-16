#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_DIR="$(cd "$HOME" && pwd -P)/.private-prompts"

if [ "$SCRIPT_DIR" != "$TARGET_DIR" ]; then
  echo "Error: This repo should be cloned to ~/.private-prompts"
  echo "Current location: $SCRIPT_DIR"
  exit 1
fi

echo "Private prompts installed at ~/.private-prompts"
echo "Run 'update_dotfiles' to merge with Claude config"
