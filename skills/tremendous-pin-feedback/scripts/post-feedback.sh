#!/bin/bash
set -euo pipefail

# Post feedback to Google Sheets via Apps Script
# Usage: post-feedback.sh <note> <member> <url>
#
# Required environment variables:
#   GSHEET_PUSH_APP_URL    - Google Apps Script web app URL
#   GSHEET_PUSH_APP_SECRET - Secret key for authentication
#
# Optional environment variables:
#   PIN_FEEDBACK_STATUS_FILE - if set, "posted" is written here on confirmed
#                              success (used by trigger.sh to detect outcome)

# Shortcuts/Alfred shells run with the C locale; Ruby's to_json then crashes
# on any non-ASCII character (em dashes, accents) with
# Encoding::UndefinedConversionError.
export LC_ALL=en_US.UTF-8

NOTE="$1"
MEMBER="$2"
URL="$3"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Direction gate: a [Positive] pin must not carry unrequested improvement
# notes. Alex feeds these rows to an AI at review time without re-reading
# each one; an unmarked "for next time" inside a praise row becomes feedback
# he never gave. The marker below is the only accepted way to include one.
MARKER="NOT REQUESTED BY ALEX"
if grep -qi "^\[positive" <<<"$NOTE" && ! grep -qiF "$MARKER" <<<"$NOTE"; then
  for phrase in "for next time" "next time," "room for improvement" "area for improvement" "one thing to improve" "one area to improve" "could have done"; do
    if grep -qiF "$phrase" <<<"$NOTE"; then
      echo "Error: positive pin contains improvement-style language (\"$phrase\") without the [NOT REQUESTED BY ALEX; OPTIONAL/MINOR] marker." >&2
      echo "If Alex did not ask for this, remove that sentence and post again." >&2
      echo "If Alex asked for it, post it as its own [Constructive; Pn] pin instead." >&2
      echo "Do not reword the note to get past this check. When unsure, stop and ask Alex." >&2
      exit 1
    fi
  done
fi

if [[ -z "${GSHEET_PUSH_APP_URL:-}" ]] || [[ -z "${GSHEET_PUSH_APP_SECRET:-}" ]]; then
  echo "Error: Required environment variables not set" >&2
  echo "  GSHEET_PUSH_APP_URL    - Google Apps Script web app URL" >&2
  echo "  GSHEET_PUSH_APP_SECRET - Secret key for authentication" >&2
  exit 1
fi

# Post to Apps Script (curl handles redirect with -L)
PAYLOAD=$(NOTE="$NOTE" MEMBER="$MEMBER" URL="$URL" TIMESTAMP="$TIMESTAMP" SECRET="$GSHEET_PUSH_APP_SECRET" ruby -r json -e '
puts({
  secret: ENV["SECRET"],
  date: ENV["TIMESTAMP"],
  note: ENV["NOTE"],
  member: ENV["MEMBER"],
  url: ENV["URL"]
}.to_json)')

RESPONSE=$(curl -sS -L --max-time 30 \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "$GSHEET_PUSH_APP_URL")

if echo "$RESPONSE" | ruby -r json -e 'exit JSON.parse(STDIN.read)["success"] ? 0 : 1' 2>/dev/null; then
  echo "Posted successfully"
  if [[ -n "${PIN_FEEDBACK_STATUS_FILE:-}" ]]; then
    echo "posted" > "$PIN_FEEDBACK_STATUS_FILE"
  fi
else
  echo "Error: response was not recognized as success: $RESPONSE" >&2
  echo "The row MAY have been posted to the sheet anyway." >&2
  echo "Do NOT retry posting. Stop and report this response to the user." >&2
  exit 1
fi

# Show macOS notification on success. Never let a notifier problem fail the
# script: the row is already posted, and a nonzero exit here invites a retry
# (and a duplicate row).
terminal-notifier -title 'Pin feedback' -message "Posted feedback for $MEMBER" -ignoreDnD || true
