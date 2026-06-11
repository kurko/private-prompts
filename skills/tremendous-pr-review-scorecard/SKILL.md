---
name: tremendous-pr-review-scorecard
description: PR review interview workflow. Preps questions into the daily note, provides the opening script, and scores the candidate afterward. Interview content (rubric, questions, answer key) lives in the team Notion doc; this skill fetches it and applies Alex's formats. During scoring it also pulls the Granola transcript of the call into the daily note. Use when the user says "pr review interview", "score PR review", "pr review scorecard", "score the interview", "interview prep", or shares a candidate's PR review link from a pr-review-interview repo. Also triggers for "grade the review", "how did they do on the PR review", "interview questions", or "pr review notion link".
argument-hint: "[candidate-name-or-pr-url]"
---

# PR Review Interview: Prep & Scorecard

This skill is a wrapper around the team's Notion doc. The doc owns the interview content: format, rubric, official discussion questions, and the answer key. This skill owns Alex's workflow: fetching that content, writing prep into the daily note, the Q:/A: format, the scoring outputs, and write-up conventions. Never duplicate doc content into this skill; an earlier version hardcoded a 12-issue answer key while the doc had grown to 15 issues, and scoring drifted.

## Source of truth: the Notion doc

https://www.notion.so/tremendous/Interview-PR-review-bf2745b48d5e4101891e7f39321e0048

Fetch it FIRST in both prep and scoring modes (Notion fetch MCP tool; load via ToolSearch if not loaded). It contains:

- **Format**: the 45-minute structure, including telling candidates AI use is welcome but we want THEIR review
- **Rubric**: 4 dimensions (prioritization, correctness, design, communication) with anchors and "In this PR, look for" pointers
- **Questions**: official discussion questions with good-signal notes
- **PR issues scorecard**: the answer key, bucketed High / Medium / Low. This is the only valid answer key; count its issues to get the catch-rate denominator.

If the fetch fails, stop and tell Alex. Never score against an answer key from memory; stale keys are the reason this skill was restructured.

After fetching, sanity-check the Opening Script below against the doc's Format section. If the doc changed, flag it and propose updating this skill.

## Candidate PRs

Each candidate gets their own repo: `tremendous-interviews/pr-review-interview--<first-last>`, and the exercise is PR #1 in that repo.

- Given a PR URL, parse repo and number from it.
- Given only a name, find the repo: `gh repo list tremendous-interviews --limit 15 --json name,createdAt`
- Do NOT confuse the candidate's PR with PR #1 in the shared `tremendous-interviews/pr-review-interview` repo. That one is the sample review whose comments flag every planted issue (linked from the doc).

## Modes

1. **Alex asks for the Notion link or instructions**: output the URL above.
2. **Prep** (candidate named, interview upcoming or in progress, no scoring asked): write the prep block into today's daily note and output the opening script in chat.
3. **Scoring** (PR link given, or Alex asks to score/grade): run the scoring workflow and append results to the daily note.

## Mode 2: Prep

1. Fetch the Notion doc. Identify the candidate (from the message, today's daily note, or the newest `pr-review-interview--*` repo).
2. Write the skeleton below into today's daily note (`journal/daily/YYYY-MM-DD.md`). If Alex already started a section for the interview, fill in around his content and never overwrite his lines (fixing an obvious typo in the header, like a misspelled name, is fine).
3. Output the opening script in chat so Alex can read it on the call.

**Questions to include**: the doc's Questions section (good-signal notes in italics), plus "In a long PR, how do you prioritize what you're going to focus on?" from the bank below (Alex's standing follow-up). About 3 total; the discussion slot is only 15 minutes.

**Q:/A: format.** During the call Alex arrows down from the Q line and types straight after `A: `; bold or quoted questions make that slower:

```
Q: The question goes here? _(Good signal: taken from the doc)_
A: 
```

- Plain `Q: ` prefix, question on a single line, signal note in italics on the same line.
- `A: ` left blank (trailing space), blank line between pairs.

**Live-editing caution.** On interview days Alex types in the daily note while you edit it. If Edit fails with "file modified", re-read and retry with a small, stable anchor. If he is actively typing and the target spot is the end of the file, append with a `cat >> file <<'EOF'` heredoc instead; an append cannot clobber his text.

Skeleton:

```markdown
## <Candidate Name> PR Review interview

Rubric: https://app.notion.com/p/tremendous/Interview-PR-review-bf2745b48d5e4101891e7f39321e0048
PR: https://github.com/tremendous-interviews/pr-review-interview--<candidate>/pull/1

### Raw notes

- 

### Call notes

Q: ...
A: 

### Post call notes

- 
```

## Opening Script

Read verbatim or paraphrased at the start of the interview. Keep aligned with the doc's Format section.

> So for this part of the interview, we're going to do a PR review exercise. I'll share a pull request with you. It's a small Rails app that fetches data from the Star Wars API and stores it locally. Someone on the team wrote this PR, and I'd like you to review it as if it landed in your queue at work.
>
> There's no trick question here. Just review it the way you normally would: leave comments, flag things, suggest improvements. Whatever you'd do on a real PR. You're welcome to use AI to help, but I want YOUR review, not the AI's. We're evaluating your judgment and technical eye.
>
> I'll give you about 15 minutes to go through it on your own. I'm going to drop off the call while you work, and you can ping me on Slack if you have any questions. After 15 minutes I'll hop back on and we'll talk through what you found. Then we'll have time for your questions at the end.
>
> Any questions before I send the link?

Then: send the PR link, drop off the call, watch Slack for questions, rejoin after 15 minutes.

## Extra question bank (not in the Notion doc)

The doc's questions come first. These fill the remaining time; pick based on what the written review surfaced. If one keeps earning its keep, suggest migrating it into the doc's Questions section so other interviewers benefit (draft the Notion edit for Alex; never edit the shared doc without his approval).

Tiers: **B1** gives the strongest signal, **B2** are strong follow-ups, **B3** if time allows.

### B1

- How do you decide whether something in a PR is a blocker vs just a suggestion? How do you communicate that difference?
- You're reviewing code in a part of the codebase you've never touched. What's your approach?
- Tell me about a time you disagreed with a PR author about your feedback. What happened?
- How much do you care about test coverage when reviewing? Would you block a PR for missing tests?

### B2

- In a long PR, how do you prioritize what you're going to focus on?
- Do you adjust your review style when reviewing code from someone more junior vs more senior? How?
- What does a healthy PR review culture look like on a team?
- When reviewing a migration, what do you look for beyond the schema change itself?

### B3

- Have you ever approved a PR you had reservations about? What made you decide to approve?
- Should code reviews enforce style, or should that be fully automated?
- What's the worst PR review practice you've seen on a team?
- How do you handle a PR that's too big? What would you say to the author?
- How do you think about backwards compatibility when reviewing API changes?

## Mode 3: Scoring

### Step 1: Fetch, in parallel

**A. The Notion doc** (if not already fetched this session). The "PR issues scorecard" section is the answer key.

**B. The candidate's PR comments:**

```bash
gh api repos/tremendous-interviews/pr-review-interview--<candidate>/pulls/1/comments --paginate
gh pr view 1 --repo tremendous-interviews/pr-review-interview--<candidate> --json reviews,comments,body
```

Capture file path, line number, and feedback text for each comment, plus the review body.

**C. Independent subagent** (Agent tool). The subagent must NOT see Alex's raw notes or the Granola transcript; it forms its own view from the written PR comments alone, which is what makes the second opinion worth having. Subagents don't inherit CLAUDE.md or this conversation, so give explicit tool commands. Don't use Haiku for it.

Prompt template (insert the candidate repo and the answer key fetched from Notion):

> You are evaluating a candidate's PR review for an interview. The candidate reviewed a deliberately flawed Rails PR. Fetch their comments with:
> `gh api repos/tremendous-interviews/pr-review-interview--<candidate>/pulls/1/comments --paginate`
> `gh pr view 1 --repo tremendous-interviews/pr-review-interview--<candidate> --json reviews,comments,body`
> Compare what they caught against the answer key below (severities High/Medium/Low). Return:
> 1. Per issue: caught (✅), partial (⚠️), or missed (❌), with a short quote when caught.
> 2. Extra findings not in the answer key.
> 3. Tone rating: Excellent / Good / Needs work / Concerning, with examples.
> 4. Independent verdict: Strong No / No / leaning Yes / Yes / Strong Yes, plus a 2-sentence rationale.
>
> ANSWER KEY (from the team Notion doc):
> [paste the fetched PR issues scorecard section]

**D. The Granola transcript of the call.** Alex records interviews with Granola. Load the Granola MCP tools via ToolSearch ("granola"). If only `mcp__granola__authenticate` appears, the server isn't connected; don't block scoring on that. Proceed without the transcript and tell Alex he can connect with `/mcp` and ask for it again.

With the MCP connected: find the call with `mcp__granola__list_meetings` (custom time range covering the interview date), match by candidate name or meeting time, then fetch the content with `mcp__granola__get_meetings`. If the server exposes a dedicated transcript tool, prefer it over the summary; tell Alex which you got (full transcript vs. Granola summary).

### Step 2: Score (main agent)

Use the candidate's PR comments, Alex's notes from the daily note section (Raw notes, Call notes answers, Post call notes), AND the Granola transcript when available. The transcript is the strongest evidence for discussion credit and for how the candidate handled questions verbally; use it to fill gaps in Alex's typed notes and to cross-check his in-the-moment impressions. Per the doc, the live discussion counts: a candidate who explains an issue verbally ("I focused on the architectural problem first to avoid overwhelming the author") gets credit even without a written comment. Mark those "raised in discussion".

Per issue: caught, partial, or missed. Extra findings count positively. Mis-aimed comments (right instinct, wrong target, like a nil-guard suggestion on a value that can't be nil) deserve a note; they show how the candidate thinks.

### Step 3: Tone

- Constructive? Suggests improvements rather than just criticizing?
- Distinguishes blockers from suggestions?
- Would you want to receive this review on your PR?
- Asks clarifying questions instead of assuming the worst?

Rate: **Excellent** / **Good** / **Needs work** / **Concerning**.

### Step 4: Outputs

Append A, B, and E to the candidate's section in the daily note (mind the live-editing caution above): A and B go after Post call notes, E goes last. If the live discussion hasn't happened yet, show A and B in chat instead and append once the call is done. C stays in chat only.

**A. Scorecard** (bullet style, matching how past scorecards read in the daily notes):

```markdown
### PR Review Scorecard

**Catch rate: X of N** (High: a/b, Medium: c/d, Low: e/f; plus partials)
**Tone: [rating]** ([one-line why])

- ✓ [High] Issue name: "short candidate quote"
- ~ [Medium] Issue name: what they got vs. what they missed
- ✗ Missed: [grouped list, Highs first]
- [extra findings, mis-aimed comments worth noting]
```

N is the issue count in the fetched doc; never hardcode it. Calibrate the signal by severity: catching most Highs is a strong signal even with Lows missed; catching mostly Lows while missing the Highs is concerning regardless of the total.

**B. Final write-up (for Ashby)**: a `### Final write-up (for Ashby)` section following `/tremendous-interview-notes` exactly: tl;dr verdict, narrative, candidate's questions, pros/cons. The scorecard informs the verdict but doesn't determine it alone; a candidate with middling catches, great tone, and a strong discussion can still be a Yes.

Keep the write-up to about half a page. The scorecard above carries the detail; the write-up carries the verdict and the signals. Don't re-describe the PR review comment-by-comment: anyone can click the PR, a detailed AI-written summary is expensive for Alex to verify against the real comments, and when the candidate used AI it reads like reviewing the AI instead of the candidate. One or two sentences on catch rate and key issues, then spend the words on how the candidate thinks, how they use AI, and how the discussion went. Alex also pastes his raw notes at the bottom of the Ashby entry, so the write-up never needs the full content of the meeting, only the highlights that weigh on the decision.

**C. Second opinion** (chat only). Compare the subagent's independent assessment with yours:

1. **Scoring disagreements**: issues you and the subagent scored differently, and why each side scored it that way.
2. **Verdict gap**: if its verdict differs from yours, explain what Alex's notes added or changed.
3. **Challenges**: if the independent read contradicts Alex's notes (notes say "struggled" but the comments are clean and well-reasoned), say so directly. Catching bias is the point; don't smooth it over.

**D.** If the live discussion is still ahead (empty `A: ` lines, no post-call notes), also output the questions and opening script.

**E. Call transcript (Granola)**: append the transcript as the final subsection of the candidate's section, after the Final write-up:

```markdown
### Call transcript (Granola)

[transcript]
```

It is reference material for Alex only. Never include the transcript or verbatim excerpts from it in the Ashby write-up; when a discussion answer matters for the report, paraphrase it the same way you would from Alex's notes. The heading folds in Obsidian, so a long transcript stays out of the way.

## Style Rules

Same as `/tremendous-interview-notes`:

- The sentence after the tl;dr verdict is capitalized like a normal sentence; only the `tl;dr` label is lowercase
- Verdict options: Strong No, No, leaning Yes, Yes, Strong Yes, on the fence
- For referrals, lean toward Yes when on the fence
- Words to avoid: "thoughtful", "conversationalist"
- No em dashes anywhere
- Use /alex-writing-at-work for voice

## Discussion Signals

Weave discussion answers into the narrative and pros/cons. Good signs:

- Distinguishes blockers from nits unprompted
- Mentions team dynamics, not just code correctness
- Has opinions about process without being rigid
- Asks the interviewer clarifying questions (they'd do the same on a real review)
