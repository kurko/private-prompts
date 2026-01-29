#!/usr/bin/env bash
#
# Trigger the pin-feedback skill from Alfred/Shortcuts.
#
# Usage (arguments):
#   trigger.sh <url> [comment]
#   trigger.sh "https://slack.com/archives/..." "Great work on the PR"
#
# Usage (stdin - safer for special characters):
#   echo "URL: https://slack.com/...
#   Comment: He said \"great work\" on this" | trigger.sh
#
# Environment setup:
#   - Sources ~/.secrets for API keys (SLACK_BOT_TOKEN, GSHEET_*)
#   - Uses direct node path to avoid nodenv shim issues in Shortcuts
#   - Runs from ~/work/core for MCP plugin context

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Support both argument and stdin input
if [[ $# -gt 0 ]]; then
  # Arguments provided
  URL="${1:-}"
  COMMENT="${2:-}"
else
  # Read from stdin (safer for special characters from Shortcuts)
  # Expected format:
  #   URL: https://...
  #   Comment: whatever text with "quotes" etc
  INPUT=$(cat)
  URL=$(echo "$INPUT" | head -1 | sed 's/^URL: //')
  COMMENT=$(echo "$INPUT" | tail -n +2 | sed 's/^Comment: //')
fi

if [[ -z "$URL" ]]; then
  echo "Error: URL required" >&2
  echo "Usage: trigger.sh <url> [comment]" >&2
  echo "   or: echo 'URL: ...\nComment: ...' | trigger.sh" >&2
  exit 1
fi

# Environment setup for non-interactive shell (Shortcuts/Alfred)
source ~/.secrets

# Get nodenv version dynamically (shims don't work without full shell init)
NODE_VERSION=$(cat ~/.nodenv/version 2>/dev/null || echo "22.9.0")
export PATH="$HOME/.nodenv/versions/${NODE_VERSION}/bin:$HOME/.dotfiles/bin:/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

# Build the prompt
# Note: "Post automatically" tells the skill to skip confirmation
if [[ -n "$COMMENT" ]]; then
  PROMPT="/tremendous-pin-feedback ${URL}

Comment: ${COMMENT}

Post automatically without asking for confirmation."
else
  PROMPT="/tremendous-pin-feedback ${URL}

Post automatically without asking for confirmation."
fi

# Pre-approved tools for this workflow
# Note: no whitespace/newlines - claude parses these strictly
# IMPORTANT: Slack tools are READ-ONLY - no post_message, reply_to_thread, or add_reaction
ALLOWED_TOOLS="Read(*),mcp__slack__slack_get_thread_replies,mcp__slack__slack_get_channel_history,mcp__slack__slack_get_users,mcp__slack__slack_get_user_profile,mcp__asana__asana_get_task,mcp__asana__asana_get_stories_for_task,mcp__asana__asana_typeahead_search,Bash(gh:*),Bash(curl*https://slack.com/api/search*),Bash(${SKILL_DIR}/scripts/post-feedback.sh:*),Bash(~/.private-prompts/skills/tremendous-pin-feedback/scripts/post-feedback.sh:*)"

# Run from a project directory that has MCP plugins configured
cd ~/work/core

echo "$PROMPT" | claude -p --allowedTools "$ALLOWED_TOOLS"
