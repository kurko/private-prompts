#!/bin/bash
#
# List pin-feedback submissions that never reached "posted" status.
# These are candidates for retry via trigger.sh (duplicates are acceptable;
# lost content is not).
#
# Usage: pending-feedback.sh [ledger-file]
#   Defaults to tmp/submissions.jsonl relative to the repo root.

set -euo pipefail
export LC_ALL=en_US.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_LEDGER="$(cd "$SCRIPT_DIR/../../.." && pwd)/tmp/submissions.jsonl"
LEDGER_FILE="${1:-$DEFAULT_LEDGER}"

if [[ ! -f "$LEDGER_FILE" ]]; then
  echo "No ledger yet at $LEDGER_FILE (nothing has been submitted since it was introduced)."
  exit 0
fi

ruby -r json -e '
  events = File.readlines(ARGV[0], chomp: true)
    .reject(&:empty?)
    .map { |line| JSON.parse(line) rescue nil }
    .compact

  by_run = events.group_by { |e| e["run"] }
  pending = by_run.reject { |_, evs| evs.any? { |e| e["status"] == "posted" } }

  if pending.empty?
    puts "All #{by_run.size} submission(s) posted. Nothing pending."
  else
    puts "#{pending.size} submission(s) never posted (retry candidates):"
    puts
    pending.sort.each do |run, evs|
      submitted = evs.find { |e| e["status"] == "submitted" } || evs.first
      last = evs.last
      puts "run #{run} (last status: #{last["status"]}, at #{last["at"]})"
      puts "  url:     #{submitted["url"].to_s.empty? ? "<none>" : submitted["url"]}"
      puts "  comment: #{submitted["comment"]}" unless submitted["comment"].to_s.empty?
      if submitted["url"].to_s.empty? && !submitted["raw_input"].to_s.empty?
        puts "  raw input (URL parsing may have failed):"
        submitted["raw_input"].each_line { |l| puts "    #{l}" }
      end
      puts
    end
  end
' "$LEDGER_FILE"
