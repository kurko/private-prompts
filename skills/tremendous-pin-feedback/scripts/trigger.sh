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
#
# Logs:
#   Each run is logged to tmp/YYYY-MM-DD_HHMMSS.log (relative to repo root)
#   (stdout + stderr combined)
#
# Ledger (never lose a submission):
#   Every submission is appended to tmp/submissions.jsonl as a "submitted"
#   event BEFORE any posting is attempted, and a "posted" or "failed" event
#   is appended when the run ends. A run with no "posted" event needs a
#   retry; list those with scripts/pending-feedback.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Shortcuts/Alfred shells run with the C locale, which makes Ruby's JSON
# encoding crash on non-ASCII text (em dashes, accents) in this script and
# in every child process (post-feedback.sh, the claude session).
export LC_ALL=en_US.UTF-8

# --- Logging setup ---
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_DIR="${REPO_ROOT}/tmp"
RUN_ID="$(date '+%Y-%m-%d_%H%M%S')"
LOG_FILE="${LOG_DIR}/${RUN_ID}.log"
LEDGER_FILE="${LOG_DIR}/submissions.jsonl"

# Tee all output (stdout + stderr) to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== pin-feedback trigger $(date '+%Y-%m-%d %H:%M:%S') ==="

# Append an event to the ledger. Ruby handles JSON-escaping of arbitrary
# comment text. A ledger problem must never abort the run: posting the
# feedback matters more than recording it, and the run log is the backup.
record_event() {
  EVENT_STATUS="$1" RUN_ID="$RUN_ID" EVENT_URL="${URL:-}" \
    EVENT_COMMENT="${COMMENT:-}" EVENT_RAW="${INPUT:-}" \
    ruby -r json -e '
      puts({
        run: ENV["RUN_ID"],
        at: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
        status: ENV["EVENT_STATUS"],
        url: ENV["EVENT_URL"],
        comment: ENV["EVENT_COMMENT"],
        raw_input: ENV["EVENT_RAW"]
      }.to_json)' >> "$LEDGER_FILE" || true
}

# Success marker: post-feedback.sh writes "posted" here on confirmed success.
# We can't grep the log for post-feedback.sh's output because claude -p only
# prints the model's final message, not tool output.
export PIN_FEEDBACK_STATUS_FILE="${LOG_FILE%.log}.status"
rm -f "$PIN_FEEDBACK_STATUS_FILE"

# Every exit path (including early set -e deaths) must record an outcome in
# the ledger and notify on failure. A silent death loses feedback content.
finish() {
  # Close the tee fds so it flushes, then wait for it to exit
  exec 1>&- 2>&- || true
  wait 2>/dev/null || true

  if [[ -f "$PIN_FEEDBACK_STATUS_FILE" ]] && grep -q '^posted$' "$PIN_FEEDBACK_STATUS_FILE"; then
    echo "=== STATUS: posted ===" >> "$LOG_FILE"
    record_event "posted"
  else
    echo "=== STATUS: failed ===" >> "$LOG_FILE"
    record_event "failed"
    terminal-notifier \
      -title 'Pin feedback FAILED' \
      -message "$(basename "$LOG_FILE") - URL: ${URL:-<none>}" \
      -ignoreDnD -sound Basso >/dev/null 2>&1 || true
  fi
}
trap finish EXIT

# Support both argument and stdin input
if [[ $# -gt 0 ]]; then
  # Arguments provided
  URL="${1:-}"
  COMMENT="${2:-}"
  INPUT=""
else
  # Read from stdin (safer for special characters from Shortcuts)
  # Expected format:
  #   URL: https://...
  #   Comment: whatever text with "quotes" etc
  INPUT=$(cat)
  URL=$(echo "$INPUT" | head -1 | sed 's/^URL: //')
  COMMENT=$(echo "$INPUT" | tail -n +2 | sed 's/^Comment: //')
fi

# URLs never contain whitespace; strip it all (Shortcuts has passed URLs
# with a trailing newline, which pollutes the prompt and the ledger).
URL="${URL//[$'\t\r\n ']/}"

echo "URL: $URL"
echo "Comment: ${COMMENT:-<none>}"
echo "---"

# Capture the submission NOW, before anything else can fail. Whatever
# happens after this point, the content is recoverable from the ledger
# (raw_input is kept too, in case the URL/Comment parsing ever mangles it).
record_event "submitted"

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
ALLOWED_TOOLS="Agent,Read(*),Grep,Glob,WebFetch,mcp__slack__slack_get_thread_replies,mcp__slack__slack_get_channel_history,mcp__slack__slack_get_users,mcp__slack__slack_get_user_profile,mcp__asana__asana_get_task,mcp__asana__asana_get_stories_for_task,mcp__asana__asana_typeahead_search,Bash(gh:*),Bash(curl*https://slack.com/api/search*),Bash(${SKILL_DIR}/scripts/post-feedback.sh:*),Bash(~/.private-prompts/skills/tremendous-pin-feedback/scripts/post-feedback.sh:*)"

# Run from a project directory that has MCP plugins configured
cd ~/work/core

echo "$PROMPT" | claude -p --allowedTools "$ALLOWED_TOOLS" || true

# The finish() EXIT trap records the outcome and notifies on failure.
