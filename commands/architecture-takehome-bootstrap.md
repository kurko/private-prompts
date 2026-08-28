# Architecture Take-Home Interview Bootstrap

Write the architecture take-home interview scaffold, including the discussion questions and approach cheat sheet, into today's daily note.

This is the prep step before the "Onsite: Back-end brief presentation" interview. It delegates to the `tremendous-architecture-takehome` skill so the questions, answer key, and daily-note format stay in one place. Do NOT hardcode the questions or answer key in this command: they live in the team Notion doc and the skill. A stale copy here would drift, which already happened once with the PR review interview's answer key.

## Process

Run **Prep mode (Mode 2)** of the `tremendous-architecture-takehome` skill, end to end:

1. **Fetch the Notion doc** (the source of truth). If the fetch fails, stop and tell Alex rather than writing questions from memory.
2. **Identify the candidate**, in this order:
   - `$ARGUMENTS`, if given (a candidate name or a link to their brief)
   - the candidate already named in today's daily note
   - Alex's calendar for today
3. **Write the scaffold** into today's daily note (`journal/daily/YYYY-MM-DD.md`) using the skill's skeleton and `Q:`/`A:` format, questions and answer notes pulled from the doc. Fill in around anything Alex already started; never overwrite his lines.
4. If the candidate's brief is already available, continue into **Gap analysis mode (Mode 3)**.

Honor the skill's live-editing caution: on interview days Alex types in the daily note while it is being edited, so anchor edits on a small stable string and retry on conflict, or append with a heredoc when the target is the end of the file.

This command only bootstraps the prep. To grade afterward, use the skill's scoring mode ("score the interview").
