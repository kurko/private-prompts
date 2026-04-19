#!/usr/bin/env python3
"""
Slack search helper for monthly eng updates.
Parses slack-readonly-cli JSON output into readable summaries.

Usage:
  # Run multiple searches
  python3 slack-search.py search "in:#team-catalog after:2026-03-01" --count 30
  python3 slack-search.py search "venmo after:2026-03-01" --count 10

  # List channels matching a pattern
  python3 slack-search.py channels "project-galileo"

  # Batch mode: pass a JSON file with multiple queries
  python3 slack-search.py batch queries.json
"""

import json
import subprocess
import sys
from datetime import datetime


def run_cli(args):
    result = subprocess.run(
        ["slack-readonly-cli"] + args,
        capture_output=True, text=True, timeout=30
    )
    if result.returncode != 0:
        print(f"  ERROR: {result.stderr.strip()}", file=sys.stderr)
        return None
    return json.loads(result.stdout)


def format_search(data, label=""):
    if not data or not data.get("ok"):
        print(f"  Search failed or returned no data")
        return

    messages = data.get("messages", {})
    total = messages.get("total", 0)
    matches = messages.get("matches", [])

    if label:
        print(f"\n{'='*60}")
        print(f"  {label} ({total} total, showing {len(matches)})")
        print(f"{'='*60}")
    else:
        print(f"\n({total} total, showing {len(matches)})")

    for m in matches:
        ts = float(m.get("ts", 0))
        dt = datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M")
        user = m.get("username", "unknown")
        text = m.get("text", "")[:300]
        permalink = m.get("permalink", "")
        is_thread = "?thread_ts=" in permalink
        thread_marker = " (thread)" if is_thread else ""
        channel = m.get("channel", {}).get("name", "")

        # Flag leadership
        user_id = m.get("user", "")
        leadership_marker = ""
        if user_id == "U01SDCLCT9C":
            leadership_marker = " [MAGNUS]"
        elif user_id == "U02FZS3HH":
            leadership_marker = " [KAPIL]"

        print(f"\n[{dt}] @{user} #{channel}{thread_marker}{leadership_marker}")
        print(f"  {text}")


def format_channels(data):
    if not data or not data.get("ok"):
        print("  Channel lookup failed")
        return

    channels = data.get("channels", [])
    for ch in channels:
        name = ch.get("name", "")
        members = ch.get("num_members", 0)
        archived = ch.get("is_archived", False)
        status = " (archived)" if archived else ""
        print(f"  #{name} ({members} members){status}")


def cmd_search(args):
    """Run a single search query."""
    query = args[0] if args else ""
    count_args = []
    if "--count" in args:
        idx = args.index("--count")
        count_args = ["--count", args[idx + 1]]
        # Remove count from query parts
        query = args[0]

    data = run_cli(["search", query] + count_args)
    format_search(data, label=query)


def cmd_channels(args):
    """List channels matching a pattern."""
    pattern = args[0] if args else ""
    data = run_cli(["channels", pattern])
    print(f"\nChannels matching '{pattern}':")
    format_channels(data)


def cmd_batch(args):
    """Run multiple queries from a JSON file.

    JSON format:
    {
      "searches": [
        {"label": "Team catalog", "query": "in:#team-catalog after:2026-03-01", "count": 30},
        ...
      ],
      "channels": [
        {"label": "Galileo channels", "pattern": "project-galileo"},
        ...
      ]
    }
    """
    filepath = args[0] if args else ""
    with open(filepath) as f:
        config = json.load(f)

    for s in config.get("searches", []):
        query = s["query"]
        label = s.get("label", query)
        count = s.get("count", 20)
        data = run_cli(["search", query, "--count", str(count)])
        format_search(data, label=label)

    for c in config.get("channels", []):
        pattern = c["pattern"]
        label = c.get("label", pattern)
        data = run_cli(["channels", pattern])
        print(f"\n{label}:")
        format_channels(data)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    command = sys.argv[1]
    rest = sys.argv[2:]

    commands = {
        "search": cmd_search,
        "channels": cmd_channels,
        "batch": cmd_batch,
    }

    if command in commands:
        commands[command](rest)
    else:
        print(f"Unknown command: {command}")
        print(f"Available: {', '.join(commands.keys())}")
        sys.exit(1)
