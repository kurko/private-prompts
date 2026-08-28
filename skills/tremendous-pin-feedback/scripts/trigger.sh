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
# Self pins (evidence about Alex's own work):
#   Prefix the comment with "self:" and the rest of the comment is stored
#   VERBATIM under Alex's own name, with no ladder mapping.
#   trigger.sh "<url>" "self: the runbook is what made this fast"
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

# Resolve symlinks before locating the repo. The skill is symlinked into
# ~/.claude/skills, and deriving the path from an unresolved BASH_SOURCE makes
# the ledger location depend on which path invoked the script: through the
# symlink it lands on ~/.claude/tmp, through the real path on the repo's tmp/.
# A split ledger reports "no ledger yet" while unposted submissions sit in the
# other one - a false all-clear on lost feedback.
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
  LINK_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$LINK_DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Shortcuts/Alfred shells run with the C locale, which makes Ruby's JSON
# encoding crash on non-ASCII text (em dashes, accents) in this script and
# in every child process (post-feedback.sh, the claude session).
export LC_ALL=en_US.UTF-8

# PATH must be set BEFORE the EXIT trap is installed. The trap's failure branch
# calls terminal-notifier, which is not on a Shortcuts-spawned PATH; if the
# script dies before this point (e.g. on `source ~/.secrets`), the notifier
# would silently fail to resolve and the failure would go unreported.
# Get nodenv version dynamically (shims don't work without full shell init)
NODE_VERSION=$(cat ~/.nodenv/version 2>/dev/null || echo "22.9.0")
export PATH="$HOME/.nodenv/versions/${NODE_VERSION}/bin:$HOME/.dotfiles/bin:/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

# --- Logging setup ---
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LOG_DIR="${REPO_ROOT}/tmp"
RUN_ID="$(date '+%Y-%m-%d_%H%M%S')"
LOG_FILE="${LOG_DIR}/${RUN_ID}.log"
LEDGER_FILE="${LOG_DIR}/submissions.jsonl"

# Save the real stdout/stderr before redirecting. finish() writes a one-line
# verdict back to these. Shortcuts shows "Shell Script Result" in a
# notification, so it must receive a verdict, not the entire run log.
exec 3>&1 4>&2

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
    echo "Pin posted (run ${RUN_ID})" >&3 || true
  else
    echo "=== STATUS: failed ===" >> "$LOG_FILE"
    record_event "failed"
    terminal-notifier \
      -title 'Pin feedback FAILED' \
      -message "$(basename "$LOG_FILE") - URL: ${URL:-<none>}" \
      -ignoreDnD -sound Basso >/dev/null 2>&1 || true
    # Exit non-zero so the Shortcuts "Run Shell Script" action registers an
    # error. Shortcuts stops the shortcut and surfaces it, using stderr as the
    # message. Without this the script exits 0 on failure (the `|| true` on the
    # `claude -p` line below guarantees it), so a pin that never reached the
    # sheet is indistinguishable from one that did.
    echo "PIN FAILED - nothing was written to the sheet. Log: ${LOG_FILE}" >&4 || true
    exit 1
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
# (PATH is exported near the top, before the EXIT trap is installed.)
source ~/.secrets

# A "self:" prefix on the comment routes this to the self-pin branch. Detecting
# it here (rather than hoping the model infers "this one is mine" from the
# wording) is what makes the Alfred/Shortcuts path reliable: the same phrasing
# always produces the same branch.
SELF_PIN=""
if [[ "$COMMENT" =~ ^[[:space:]]*[Ss][Ee][Ll][Ff]:[[:space:]]* ]]; then
  SELF_PIN="yes"
  COMMENT="$(echo "$COMMENT" | sed -E 's/^[[:space:]]*[Ss][Ee][Ll][Ff]:[[:space:]]*//')"
  echo "Self pin: yes"
fi

# Build the prompt
# Note: "Post automatically" tells the skill to skip confirmation
if [[ -n "$SELF_PIN" ]]; then
  PROMPT="/tremendous-pin-feedback ${URL}

This is a SELF pin. The target is Alex Oliveira. Follow the Self Pins section of
the skill: skip the career ladder entirely, write one short headline, and store
the commentary below VERBATIM. Post with post-self-note.sh.

Comment: ${COMMENT}

Post automatically without asking for confirmation."
elif [[ -n "$COMMENT" ]]; then
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
ALLOWED_TOOLS="Agent,Read(*),Grep,Glob,WebFetch,mcp__slack__slack_get_thread_replies,mcp__slack__slack_get_channel_history,mcp__slack__slack_get_users,mcp__slack__slack_get_user_profile,mcp__asana__asana_get_task,mcp__asana__asana_get_stories_for_task,mcp__asana__asana_typeahead_search,Bash(gh:*),Bash(curl*https://slack.com/api/search*),Bash(${SKILL_DIR}/scripts/post-feedback.sh:*),Bash(~/.private-prompts/skills/tremendous-pin-feedback/scripts/post-feedback.sh:*),Bash(${SKILL_DIR}/scripts/post-self-note.sh:*),Bash(~/.private-prompts/skills/tremendous-pin-feedback/scripts/post-self-note.sh:*)"

# Run from a project directory that has MCP plugins configured
cd ~/work/tremendous/core

echo "$PROMPT" | claude -p --allowedTools "$ALLOWED_TOOLS" || true

# The finish() EXIT trap records the outcome and notifies on failure.
