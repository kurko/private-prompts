---
name: adversarial-ai-review
description: >-
  Get a second opinion from another provider AI CLI on architectural decisions
  or code reviews. Use when the user wants an adversarial review, a second
  opinion, a design challenge, or says "ask codex", "ask claude", "get another
  opinion", "adversarial review", "challenge this design", "have codex review
  this". Works for both architecture decisions and code/PR reviews.
allowed-tools: Bash, Read, Grep, Glob, Agent
---

# Adversarial AI Review

Get a critical second opinion from a different AI CLI on architectural decisions
or code reviews. The value is in getting a fundamentally different model to
challenge assumptions, surface blind spots, and find bugs that familiarity
with the codebase might cause you to miss.

## Available AIs

| CLI | Exec mode | Output |
|-----|-----------|--------|
| Codex | `codex exec --dangerously-bypass-approvals-and-sandbox -o FILE PROMPT` | Writes to `-o` file |
| Claude Code | `claude -p --dangerously-skip-permissions PROMPT` | Stdout (redirect to file) |

**Rule**: Never run instances of the same AI you are. If you are Claude Code,
run Codex. If you are Codex, run Claude Code.

## Input Processing

Parse these from the user's message:

| Parameter | Source | Default |
|-----------|--------|---------|
| **Mode** | "review my PR" → Code Review; "challenge this design" → Architecture | Ask if ambiguous |
| **Context** | File path, PR URL, pasted text, or "my current changes" | Build context in the mode's gather step |
| **Adversarial AI** | Explicit ("ask codex", "ask claude") or auto-detect | The other CLI (not the one you are) |
| **Topic slug** | Derived from the decision or PR description | Generate a short hyphenated slug |

If the user provides a file path, read it. If they provide a PR URL, extract
context with `gh pr view`. If they say "my changes", use the git working tree.

## Modes

| Signal | Mode |
|--------|------|
| User asks about an architectural decision, design question, or tradeoff | **Architecture** |
| User asks to review a PR, diff, or specific code changes | **Code Review** |
| Ambiguous | Ask the user |

## Pre-Flight Checks

Before running the adversarial AI, verify:

| Check | Command | On failure |
|-------|---------|------------|
| Target CLI installed | `which codex` or `which claude` | Tell the user to install it. Codex: `npm install -g @openai/codex`. Claude Code: `npm install -g @anthropic-ai/claude-code` |
| Git repo (code review) | `git rev-parse --is-inside-work-tree` | Required for code review mode. Tell the user to navigate to a git repo |

## Architecture Mode

### 1. Gather Context

Before running the CLI, you need a thorough context document. Either:

- **User provides one**: A markdown file with the decision, tradeoffs, and
  approaches. Read it and proceed.
- **You build one**: Draft a context document that includes:
  - System architecture overview (what the app does, key patterns)
  - The specific decision or question
  - All approaches being considered, with tradeoffs for each
  - Constraints (performance, cost, operational complexity, team size)
  - What the user is leaning toward and why, if present
- **A git diff or PR link**: If the decision is tied to specific code changes,
  include a diff or PR link and summarize the changes, including original
  intent and/or plan document.

### 2. Identify Key Files

List 5-15 files that the adversarial AI should read to understand the relevant code:

- The code most directly affected by the decision
- Related models, services, or controllers
- Existing tests that show current behavior
- Configuration files if relevant

### 3. Build the Prompt

Construct a prompt with this structure and write it to
`/tmp/adversarial-prompt-{topic}.md`:

```
## Context

[Paste the context document or a concise summary]

## Key Files to Read

Read these files to understand the codebase before forming an opinion:

- path/to/file1 — [why it matters]
- path/to/file2 — [why it matters]
...

## The Question

[The specific architectural decision or design question]

## Approaches

### Approach A: [Name]
[Description, tradeoffs]

### Approach B: [Name]
[Description, tradeoffs]

## Your Task

1. Read all the key files listed above. Understand the actual code, not just
   the descriptions.
2. Challenge the assumptions in BOTH approaches. What are the authors missing?
3. Identify edge cases and failure modes for each approach.
4. Flag any bugs, inconsistencies, or debt in the existing code that would
   affect this decision.
5. Evaluate against these criteria: [list criteria relevant to the decision,
   e.g., scalability, cost, operational complexity, extensibility, testability]
6. Give a clear recommendation. Do NOT hedge. Take a position and defend it.
   If you think both approaches are wrong, say so and propose an alternative.
7. If you find bugs or issues in the existing code, list them explicitly.
```

### 4. Run the Adversarial AI

Generate a topic slug from the decision (e.g., `separate-classification-from-detection`).

#### Running Codex

```bash
codex exec \
  --dangerously-bypass-approvals-and-sandbox \
  -o "/tmp/adversarial-review-{topic}.md" \
  - < /tmp/adversarial-prompt-{topic}.md
```

#### Running Claude Code

```bash
claude -p --model opus \
  --allowed-tools "Read Grep Glob Bash(git:*)" \
  --dangerously-skip-permissions \
  < /tmp/adversarial-prompt-{topic}.md \
  > /tmp/adversarial-review-{topic}.md
```

### 5. Present Results

1. Read the output file at `/tmp/adversarial-review-{topic}.md`.
2. Present a summary to the user with:
   - The adversarial AI's recommendation and key reasoning
   - Any bugs or issues it found
   - Points where it disagrees with your current thinking
   - Anything surprising or that you hadn't considered
3. Tell the user the file path for full review.

## Code Review Mode

### 1. Determine What to Review

| Signal | Action | Git command |
|--------|--------|-------------|
| PR URL | Extract branch and description | `gh pr view <url> --json headRefName,baseRefName,body` |
| "review my changes" | Uncommitted changes | `git diff` + `git diff --staged` |
| Specific commit SHA | That commit | `git show <sha>` |
| Branch name | Branch vs main | `git diff main...<branch>` |

### 2. Gather Context

Collect two things:

1. **The diff**: Use the appropriate git command from the table above. Write
   it to `/tmp/adversarial-diff-{topic}.txt`.
2. **Coder intent**: What are the changes trying to accomplish? Sources:
   - PR description (from `gh pr view`)
   - The user's explanation
   - Commit messages on the branch
   - Any linked task or plan context

For PRs, also extract linked task URLs from the PR description and fetch
their details if available.

### 3. Build the Prompt

Instruct the adversarial AI to use the `/code-review` skill with adversarial
framing. Write this prompt to `/tmp/adversarial-prompt-{topic}.md`:

```
Use the /code-review skill to review the following changes.

## Coder Intent

[What the changes are trying to accomplish — from PR description, user
explanation, or commit messages]

## Diff

Run this command to get the diff:

    [the appropriate git diff command]

Or read the diff directly from: /tmp/adversarial-diff-{topic}.txt

## Additional Instructions

Review with an adversarial mindset. Beyond the standard code review:
- Challenge design decisions. Is there a simpler way?
- Find bugs the author missed. Off-by-one, nil risks, race conditions.
- Identify edge cases that will break in production.
- If something is bad, say so directly. Do NOT hedge.
- Give a clear verdict: APPROVE, REQUEST_CHANGES, or NEEDS_DISCUSSION.
```

### 4. Run the Adversarial AI

#### Running Codex

```bash
codex exec \
  --dangerously-bypass-approvals-and-sandbox \
  -o "/tmp/adversarial-review-{topic}.md" \
  - < /tmp/adversarial-prompt-{topic}.md
```

#### Running Claude Code

```bash
claude -p --model opus \
  --allowed-tools "Read Grep Glob Bash(git:*)" \
  --dangerously-skip-permissions \
  < /tmp/adversarial-prompt-{topic}.md \
  > /tmp/adversarial-review-{topic}.md
```

### 5. Present Results

Same as Architecture Mode step 5: read the output, summarize key findings,
tell the user the file path.

## Long Prompts

If the prompt exceeds ~500 words (common for architecture reviews with full
context documents), write it to `/tmp/adversarial-prompt-{topic}.md` and
pipe it in rather than passing it as a CLI argument.

**Codex:**

```bash
codex exec \
  --dangerously-bypass-approvals-and-sandbox \
  -o "/tmp/adversarial-review-{topic}.md" \
  - < /tmp/adversarial-prompt-{topic}.md
```

**Claude Code:**

```bash
claude -p --model opus \
  --allowed-tools "Read Grep Glob Bash(git:*)" \
  --dangerously-skip-permissions \
  < /tmp/adversarial-prompt-{topic}.md \
  > /tmp/adversarial-review-{topic}.md
```

## Error Handling

| Failure | Action |
|---------|--------|
| Adversarial CLI not installed | Fail with installation instructions (see Pre-Flight Checks) |
| CLI exits with non-zero status | Show the error output to the user. Common causes: missing API key, network issue, rate limit. Suggest they check and retry |
| CLI takes longer than 10 minutes | Kill the process. Tell the user the prompt may be too long or complex. Suggest breaking the review into smaller pieces |
| Output file is empty | Tell the user the review produced no output. Suggest refining the prompt with more specific context |
| Output is shallow (< 200 words) | Warn the user: "The review seems shallow — this usually means the prompt lacked sufficient context." Offer to re-run with a refined prompt |
| Output references files not listed or makes factual claims about code | Spot-check 2-3 specific claims against the actual code before presenting. The adversarial AI is cold-starting without codebase context, so hallucinated references are common. Warn the user about any claims that don't match |
| PR URL cannot be fetched | Fall back to asking the user to provide the diff or branch name directly |

## Guidelines

- **Don't filter or soften the adversarial AI's output.** Present findings directly, even
  if they are critical of code you wrote. The whole point is adversarial review.
- **Flag disagreements.** If you disagree with the adversarial AI's assessment, say so and
  explain why. The user benefits from seeing the tension between two models.
- **Iterate if needed.** If the review is shallow or misses the point,
  refine the prompt and run again. A bad prompt produces a bad review.
  Common fixes: add more context files, clarify the question, include
  specific concerns you want challenged.
- **Never skip the context document for architecture reviews.** The quality of
  the review is directly proportional to the quality of the context provided.
- **Time budget.** The adversarial CLI can take 2-5 minutes. Set expectations
  with the user before running it.
