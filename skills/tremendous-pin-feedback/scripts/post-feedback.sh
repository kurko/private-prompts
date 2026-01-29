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

# Post to Apps Script and follow redirect with GET
ruby -r net/http -r uri -r json -e '
uri = URI(ARGV[0])
data = {
  secret: ARGV[1],
  date: ARGV[2],
  note: ARGV[3],
  member: ARGV[4],
  url: ARGV[5]
}

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri.request_uri)
request["Content-Type"] = "application/json"
request.body = data.to_json

response = http.request(request)

if response.is_a?(Net::HTTPRedirection)
  redirect_uri = URI(response["location"])
  http2 = Net::HTTP.new(redirect_uri.host, redirect_uri.port)
  http2.use_ssl = true
  request2 = Net::HTTP::Get.new(redirect_uri.request_uri)
  response = http2.request(request2)
end

result = JSON.parse(response.body) rescue { "error" => response.body }
if result["success"]
  puts "Posted successfully"
else
  STDERR.puts "Error: #{result}"
  exit 1
end
' "$GSHEET_PUSH_APP_URL" "$GSHEET_PUSH_APP_SECRET" "$TIMESTAMP" "$NOTE" "$MEMBER" "$URL"

# Show macOS notification on success
terminal-notifier -title 'Pin feedback' -message "Posted feedback for $MEMBER" -ignoreDnD
