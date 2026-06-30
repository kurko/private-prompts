#!/bin/bash
set -euo pipefail

# Post feedback to Google Sheets via Apps Script
# Usage: post-feedback.sh <note> <member> <url>
#
# Required environment variables:
#   GSHEET_PUSH_APP_URL    - Google Apps Script web app URL
#   GSHEET_PUSH_APP_SECRET - Secret key for authentication

if [[ -z "${GSHEET_PUSH_APP_URL:-}" ]] || [[ -z "${GSHEET_PUSH_APP_SECRET:-}" ]]; then
  echo "Error: Required environment variables not set" >&2
  echo "  GSHEET_PUSH_APP_URL    - Google Apps Script web app URL" >&2
  echo "  GSHEET_PUSH_APP_SECRET - Secret key for authentication" >&2
  exit 1
fi

NOTE="$1"
MEMBER="$2"
URL="$3"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Post to Apps Script (curl handles redirect with -L)
PAYLOAD=$(NOTE="$NOTE" MEMBER="$MEMBER" URL="$URL" TIMESTAMP="$TIMESTAMP" SECRET="$GSHEET_PUSH_APP_SECRET" ruby -r json -e '
puts({
  secret: ENV["SECRET"],
  date: ENV["TIMESTAMP"],
  note: ENV["NOTE"],
  member: ENV["MEMBER"],
  url: ENV["URL"]
}.to_json)')

RESPONSE=$(curl -sS -L \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "$GSHEET_PUSH_APP_URL")

if echo "$RESPONSE" | ruby -r json -e 'exit JSON.parse(STDIN.read)["success"] ? 0 : 1' 2>/dev/null; then
  echo "Posted successfully"
else
  echo "Error: $RESPONSE" >&2
  exit 1
fi

# Show macOS notification on success
terminal-notifier -title 'Pin feedback' -message "Posted feedback for $MEMBER" -ignoreDnD
