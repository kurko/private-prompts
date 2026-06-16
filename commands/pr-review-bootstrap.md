# PR Review Interview Bootstrap

Write the PR review interview scaffold, including the discussion questions, into today's daily note.

This is the prep step before a PR review interview. It delegates to the `tremendous-pr-review-scorecard` skill so the questions, rubric, and daily-note format stay in one place. Do NOT hardcode the questions or rubric in this command: they live in the team Notion doc and the skill, and a stale copy here would drift. That exact drift already happened once, when a hardcoded answer key fell out of sync with the doc.

## Process

Run **Prep mode (Mode 2)** of the `tremendous-pr-review-scorecard` skill, end to end:

1. **Fetch the Notion doc** (the source of truth for the questions). If the fetch fails, stop and tell Alex rather than writing questions from memory.
2. **Identify the candidate**, in this order:
   - `$ARGUMENTS`, if given (a candidate name or a PR URL)
   - the candidate already named in today's daily note
   - the newest `tremendous-interviews/pr-review-interview--*` repo (`gh repo list tremendous-interviews --limit 15 --json name,createdAt`)
3. **Verify the candidate's PR** exists (`pr-review-interview--<candidate>` PR #1) so the link written into the note is live.
4. **Write the scaffold** into today's daily note (`journal/daily/YYYY-MM-DD.md`) using the skill's skeleton and `Q:`/`A:` format. The skeleton (authoritative in the skill) lays out every section up front, including the placeholders that get filled later, and orders the questions with Alex's prioritization opener and the doc's "ship fast vs. code quality" question first. Fill in around anything Alex already started; never overwrite his lines.
5. **Output the opening script** in chat.

Honor the skill's live-editing caution: on interview days Alex types in the daily note while it is being edited, so anchor edits on a small stable string and retry on conflict.

This command only bootstraps the prep. To grade afterward, use the skill's scoring mode ("score the interview").
