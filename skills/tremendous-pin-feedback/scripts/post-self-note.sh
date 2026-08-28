#!/bin/bash
set -euo pipefail

# Post a SELF pin (evidence about Alex Oliveira) to the same Google Sheet.
#
# Usage: post-self-note.sh <headline> <my-words> <url>
#
#   headline  One line of context. Max one sentence. NOT a summary of the work.
#   my-words  Alex's own commentary, VERBATIM. Never rewritten, never polished.
#   url       Source URL.
#
# Why this wrapper exists (do not route self pins through post-feedback.sh):
#   1. The member name is fixed. It cannot be resolved wrong.
#   2. Alex's words are stored verbatim under a fixed marker, so the review-time
#      pass can tell capture from composition.
#   3. Ladder tags ([Positive; P5]) are REJECTED. Alex is in management; the
#      engineering ladder does not apply to his own evidence.
#   4. An empty commentary is REJECTED. A self pin with no words of his own is
#      just a bookmark, and the point of the system is his words.
#
# Everything above is enforced here, in code, because a prompt-level rule about
# "keep it short and skip the ladder" is exactly the kind of rule a model drops
# under context pressure.

export LC_ALL=en_US.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SELF_MEMBER="alex oliveira"
VERBATIM_MARKER="My words:"
MAX_HEADLINE_CHARS=200

if [[ $# -ne 3 ]]; then
  echo "Error: expected 3 arguments" >&2
  echo "Usage: post-self-note.sh <headline> <my-words> <url>" >&2
  exit 1
fi

HEADLINE="$1"
MY_WORDS="$2"
URL="$3"

trimmed() { echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

HEADLINE="$(trimmed "$HEADLINE")"
MY_WORDS="$(trimmed "$MY_WORDS")"
URL="${URL//[$'\t\r\n ']/}"

if [[ -z "$MY_WORDS" ]]; then
  echo "Error: no commentary from Alex was passed." >&2
  echo "A self pin stores HIS words. Do not compose them." >&2
  echo "Stop and ask the user what they want recorded." >&2
  exit 1
fi

if [[ -z "$URL" ]]; then
  echo "Error: URL required for a self pin." >&2
  echo "Stop and ask the user for the source link." >&2
  exit 1
fi

# Reject an engineering-ladder tag on the headline, e.g. "[Positive; P5]".
# Alex is in management. Self evidence is never ladder-mapped.
if echo "$HEADLINE" | grep -Eq '^\[[^]]*[Pp][3-6][^]]*\]'; then
  echo "Error: self pins are not mapped to the engineering ladder." >&2
  echo "Remove the [ ...; P4 ] style tag. Use a plain [Self] headline about impact." >&2
  exit 1
fi

if [[ ${#HEADLINE} -gt $MAX_HEADLINE_CHARS ]]; then
  echo "Error: headline is ${#HEADLINE} chars, limit is ${MAX_HEADLINE_CHARS}." >&2
  echo "Self entries are short. Put the detail in Alex's own words, not in the headline." >&2
  exit 1
fi

if [[ "$HEADLINE" != \[Self\]* ]]; then
  HEADLINE="[Self] $HEADLINE"
fi

NOTE="$HEADLINE

$VERBATIM_MARKER $MY_WORDS"

exec "$SCRIPT_DIR/post-feedback.sh" "$NOTE" "$SELF_MEMBER" "$URL"
