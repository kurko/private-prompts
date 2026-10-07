---
name: tremendous-architecture-takehome
description: Architecture take-home interview workflow (Onsite Back-end brief presentation, the multi-tenancy brief). Preps questions and scaffold into the daily note, runs a gap analysis of the candidate's brief before the call, and scores afterward. Interview content (approach answer key, questions, evaluation criteria) lives in the team Notion doc; this skill fetches it and applies Alex's formats. Use when the user says "architecture take home", "back-end brief", "brief presentation interview", "analyze the brief", "gaps in the brief", "score the architecture interview", or shares a candidate's technical brief about adding multi-tenancy.
argument-hint: "[candidate-name-or-doc-link]"
---

# Architecture Take-Home Interview: Prep, Gap Analysis & Scorecard

This skill is a wrapper around the team's Notion doc for the "Onsite: Back-end brief presentation" interview. The doc owns the interview content: format, the approach answer key, the discussion questions, and the evaluation criteria. This skill owns Alex's workflow: fetching that content, writing prep into the daily note, analyzing the candidate's brief for gaps, the question order and format, and the write-up conventions. Never duplicate doc content into this skill; the sibling `tremendous-pr-review-scorecard` skill once hardcoded an answer key that drifted from its doc, and scoring drifted with it.

## The interview

The candidate received the Peer Reviews codebase in advance and wrote a technical brief on adding multi-tenancy to it. The interview is 30 minutes: ~5 minutes putting the candidate at ease, ~25 minutes discussing their doc. There is no exercise during the call; the signal comes from the pre-read of the brief and the discussion.

## Source of truth: the Notion doc

https://app.notion.com/p/tremendous/Onsite-Back-end-brief-presentation-94f1d261073b4a06a4aec37742f1b2c7

Fetch it FIRST in every mode (Notion fetch MCP tool; load via ToolSearch if not loaded). It contains:

- **Context and format**: what the candidate received, the 5 + 25 minute structure
- **Approach answer key**: the three multi-tenancy approaches (multiple DBs, multiple schemas, row-level scoping) with which are bad signs and why, including the `acts_as_tenant` / `default_scope` sub-case. Steering guidance: nudge candidates off the dispreferred approaches and see if they take the feedback.
- **Things to look for in the brief**: the pre-read criteria (clarity, skimmability, approach quality, pros/cons)
- **Questions to ask**: topic-grouped questions with the correct answers noted inline
- **Evaluating candidates**: the "What we're looking for" criteria and a "what good looks like" example (Dan Hilton's notes, linked from the doc)

If the fetch fails, stop and tell Alex. Never prep questions or score against an answer key from memory.

## The candidate's brief

The brief arrives however the candidate sent it: a Notion link (notion-fetch), a Google Doc (`gog docs`), a PDF or file (Read), or text pasted into chat. Get the full text before analyzing. If a link fails to load, ask Alex to paste the content rather than analyzing from a summary.

## Modes

1. **Alex asks for the Notion link or instructions**: output the URL above.
2. **Prep** (candidate named, interview upcoming, no brief shared yet): write the scaffold into today's daily note.
3. **Gap analysis** (Alex shares the candidate's brief before the call): analyze the brief against the doc, fill the gap analysis section, reprioritize the questions.
4. **Scoring** (after the call, or Alex asks to score/grade): run the scoring workflow and fill the remaining sections.

Modes 2 and 3 often run back to back in one session: scaffold first, gap analysis when the brief lands.

## Mode 2: Prep

1. Fetch the Notion doc. Identify the candidate (from the message, today's daily note, or Alex's calendar).
2. Write the skeleton below into today's daily note (`journal/daily/YYYY-MM-DD.md`). If Alex already started a section for the interview, fill in around his content and never overwrite his lines (fixing an obvious typo in the header, like a misspelled name, is fine).

**Questions to include**, in this order. The 25-minute discussion fits about five core questions with follow-ups, so the strongest ones go first and Alex never has to reorder live. (On 2026-10-01 the scaffold followed the doc's order: the migration question sat fifth, behind four roles questions he skipped, and he reordered during the call.)

Core:

1. **Migration walk-through.** One end-to-end prompt: walk me through the migrations, where the code lives, how you'd run them in production, and how we avoid downtime. It merges the doc's data migration questions with its rollout question, so one answer shows the whole sequence and leaves room for follow-ups. Seed FQs from the doc's sub-questions the candidate may skip (e.g. records created while the backfill runs, which tests the order of operations).
2. **Approach and default scopes.** Ask why they chose their scoping mechanism over the alternative, in the candidate's terms. The question works either way:
   - **They rejected `acts_as_tenant` / `default_scope`:** "You rejected acts_as_tenant, why?" The answer confirms they know the downsides. Keep it short.
   - **They chose it:** "Why acts_as_tenant over scoping explicitly in policies or queries?" Seed FQs from the doc's default-scope questions: first the downsides, then a steer away from it. The italic note on the steer FQ names the signal: do they take the feedback or defend the choice?
   - **The brief doesn't mention it:** ask how they keep every query scoped to the org, and whether they considered a default scope.

   When the brief lands on a dispreferred approach (multiple DBs, schemas, default scopes), move this question first: steering needs time to see whether the candidate takes the feedback.
3. **Scale.** Frame the doc's big-tables question as scale: "what if we had 1MM users, what would you do differently?" The open framing lets the candidate bring up locking on their own.
4. **Locks.** Ask directly about table locks during the migration and backfill on big tables, even when the scale answer was good. Always ask it: locking is the doc's correct answer for big tables, and the open scale question doesn't reliably bring it up (on 2026-10-01 the candidate answered scale with Sidekiq batches and never mentioned locks). Use the doc's answer-key points (batching, `strong_migrations`, adding a column with a default) as the italic note.
5. **Notifications.** Use the doc's admin-panel question: starting a cycle from the admin panel sends emails and Slack notifications, so what do you watch out for? The signal is whether the candidate makes it async with Sidekiq on their own. Ask it in the candidate's terms when the brief moves cycle launch or notifications into the UI.

If time: the remaining doc topics in the doc's order (roles, which models get the org, testing), under a plain `If time` line. Drop any topic the gap analysis marks as covered by the brief.

Pull the correct-answer notes from the doc's "Questions to ask" section and put them in italics on the Q line, so Alex can check answers live without flipping to Notion. When the brief is in hand, word each question in the candidate's terms ("You rejected acts_as_tenant, why?") rather than the doc's generic text. Reference questions by topic here; never paste their text into this skill. If the doc's topics change, keep the principle (migration walk-through, then approach, then scale, then locks, then notifications) and tell Alex.

**Approach cheat sheet**: condense the doc's answer key into a few bullets inside the scaffold (which approaches are bad signs and why, what good looks like, the steering guidance). This is fetched content written into the note instance, which is fine; only the skill file itself must stay content-free. It lives below the `***`, with the other AI/reference sections, so it never rides along when Alex copies his notes into Ashby.

**Question format.** During the call Alex arrows down from the Q line and types straight after the `- `; bold or quoted questions make that slower:

```
Q: (Topic) The question goes here? _(correct answer / good signal, from the doc)_
- 
FQ: A likely follow-up? _(what it probes)_
- 
```

- Plain `Q: ` prefix, question on a single line, answer note in italics on the same line.
- The answer is a bullet list under the question: one empty `- ` (trailing space), blank line between pairs. Alex presses enter to add bullets and split the answer into parts, so a bare `A: ` line would fight him.
- `FQ: ` marks a follow-up question, answered the same way. Alex adds his own during the call. Seed at most one or two per core question, so the list stays short enough to scan live.
- Text in `[brackets]` inside an answer is Alex's own aside (e.g. "[how?]" for a probe he wanted to make), not the candidate's words.

**Live-editing caution.** On interview days Alex types in the daily note while you edit it. If Edit fails with "file modified", re-read and retry with a small, stable anchor. If he is actively typing and the target spot is the end of the file, append with a `cat >> file <<'EOF'` heredoc instead; an append cannot clobber his text.

Skeleton (lay out every section up front, so each has a home before the call). The gap analysis, approach cheat sheet, and transcript sit below Post call notes and the `***` on purpose: Alex copies Final report, Raw notes, and Post call notes into Ashby, and nothing below the `***` should ride along:

```markdown
# <Candidate Name> Architecture take-home interview

Interview instructions: https://app.notion.com/p/tremendous/Onsite-Back-end-brief-presentation-94f1d261073b4a06a4aec37742f1b2c7
Brief by candidate: <candidate doc link, when known>

## Final report

tl;dr

## Raw notes

### Pre-call notes

Pros
- 

Cons
- 

### Call notes

- 

Q: ...
- 

If time

Q: ...
- 

Their questions
- 

### Post call notes

Went well
- 

Fell short
- 

### Brief Gap Analysis (AI)

***

### Approach cheat sheet

- [condensed answer key from the doc]

### Meeting transcripts (Granola)
```

The header labels are explicit because "Brief" alone reads as the candidate's brief: `Interview instructions` is the team's Notion doc, `Brief by candidate` is theirs.

`### Pre-call notes` is Alex's own initial read of the brief, jotted before the call (he writes it as Pros and Cons). The doc asks interviewers to base part of their feedback on this pre-discussion impression, so it stays separate from the AI gap analysis and never gets filled by Claude.

`### Post call notes` has `Went well` and `Fell short` prompts so Alex covers both sides while the call is fresh. The final report's pros and cons draw from them.

## Mode 3: Gap Analysis

Run when the candidate's brief is in hand, ideally before the call. The goal is to tell Alex where to push in 25 minutes.

1. Read the full brief. Fetch the Notion doc if not already fetched this session.
2. **Classify the approach** against the doc's answer key: which of the three approaches did they choose, did they discuss alternatives and pros/cons, and did they land on anything the doc flags as a bad sign (multiple DBs, schema-per-tenant, `acts_as_tenant`/`default_scope`).
3. **Evaluate the brief itself** against the doc's "Things to look for in the brief" criteria.
4. **Map coverage of the doc's questions**: for each question topic, does the brief already answer it, partially answer it, or not touch it? Gaps and partial answers are where the discussion time goes; questions the brief nails can be quick confirmations.
5. Write the result into the `### Brief Gap Analysis (AI)` section of the scaffold (mind the live-editing caution):

```markdown
### Brief Gap Analysis (AI)

**Approach: [chosen approach]** ([good / bad sign per the doc, one line])
**Brief quality: [one line against the pre-read criteria]**

Ask first (gaps):
- [question topic]: [what the brief left open]

Covered (confirm quickly):
- [question topic]: [what they said, one line]

Red flags to steer on:
- [anything matching the doc's bad-sign list, with where it appears in the brief]
```

6. Apply the analysis to the questions only while Alex hasn't started typing in Call notes (e.g. when the scaffold and the gap analysis go out in the same pass): word the questions in the candidate's terms, swap an `If time` topic into the core set when the brief leaves it wide open, and move the approach question first on a red flag. Once he has started typing, leave the questions alone; the "Ask first" list carries the priority.

Chat output: the same summary, short. Alex is usually reading the brief in parallel; the analysis is a second pair of eyes, not a replacement for his pre-read.

## Mode 4: Scoring

### Step 1: Fetch, in parallel

**A. The Notion doc** (if not already fetched this session). The "What we're looking for" and "Things to look for in the brief" sections are the rubric.

**B. The Granola transcript of the call.** Same pattern as `tremendous-pr-review-scorecard`: load the Granola MCP tools via ToolSearch ("granola"). If only `mcp__granola__authenticate` appears, the server isn't connected; don't block scoring on that. Proceed without the transcript and tell Alex he can connect with `/mcp` and ask again. With the MCP connected: find the call with `mcp__granola__list_meetings` (custom range covering the interview date), match by candidate name or meeting time, then pull the verbatim transcript with `mcp__granola__get_meeting_transcript` (pass the meeting UUID). Use the transcript, not `get_meetings` summaries: the discussion is the main signal in this interview and the AI summary drops the exact wording that scoring turns on (whether he said "foreign key", whether he reached the batched-backfill answer himself). The transcript is a rough auto-transcription; recover garbled names and jargon from context.

**C. Independent subagent** (Agent tool). The subagent must NOT see Alex's notes or the transcript; it forms its own view from the brief alone, which is what makes the second opinion worth having. Subagents don't inherit CLAUDE.md or this conversation, so paste the brief text and the fetched criteria into the prompt. Don't use Haiku for it.

Prompt template:

> You are evaluating a candidate's take-home technical brief for a senior back-end interview. The exercise: add multi-tenancy to a small Rails app. Evaluate the brief below against the criteria below. Return:
> 1. Which approach they chose and whether the criteria consider it a good or bad sign.
> 2. Brief quality: clarity, skimmability, pros/cons discussion.
> 3. Strongest and weakest sections, with short quotes.
> 4. Independent verdict: Strong No / No / leaning Yes / Yes / Strong Yes, plus a 2-sentence rationale.
>
> CRITERIA (from the team Notion doc):
> [paste the answer key + "Things to look for in the brief" + "What we're looking for"]
>
> BRIEF:
> [paste the candidate's brief]

### Step 2: Score (main agent)

Use the gap analysis, Alex's notes (Pre-call notes, Call notes answers, Their questions, Post call notes), and the transcript when available. The discussion is most of the signal in this interview: the doc's questions have correct answers noted, so check the answer bullets (under each `Q:` and `FQ:` line) and the transcript against them. A candidate who wrote a weak brief but corrected course when steered (took the feedback on a dispreferred approach) is showing exactly what the steering guidance tests for; say so. The reverse, defending a bad approach after a nudge, weighs heavily.

**Weight the brief as a work sample, not just a warm-up for the discussion.** A strong live discussion does not fully rescue a thin brief. The brief is how the candidate communicates in writing, unsupervised, which is a direct predictor of on-the-job behavior. The panel has rejected on exactly this ("imagine seeing him post a brief like that and then having to coach him") even when the candidate clearly knew his stuff live. Score the discussion on its merits, but don't round the verdict up to a Strong Yes on the strength of the live chat when the artifact was under-prepared. When the two diverge, say so plainly and let the divergence carry weight.

**This is one station in a full onsite.** Your write-up is for this interview only; the panel's decision integrates the coding round and the other stations, and a solid Yes here can still net to a reject. Frame your verdict as your read of the brief and the discussion, not as the hire decision.

### Step 3: Outputs

Fill the scaffold sections (mind the live-editing caution; match close heading variants rather than creating duplicates):

- **A. Final report** fills `## Final report`, replacing the `tl;dr` placeholder. Follow `/tremendous-interview-notes` exactly: tl;dr verdict, narrative, candidate's questions, pros/cons. This is what Alex pastes into Ashby. Include a line on the pre-read impression of the brief (the doc asks for it) and how the discussion confirmed or changed it. Keep it to about half a page; the gap analysis carries the detail. Spend the words on how the candidate thinks and how they responded to steering, not on re-describing the brief.
- **B. Second opinion** (chat only). Compare the subagent's independent assessment with yours: scoring disagreements, verdict gap, and direct challenges if the independent read contradicts Alex's notes. Catching bias is the point; don't smooth it over.
- **C. Meeting transcripts** fills `### Meeting transcripts (Granola)` with the verbatim transcript from `get_meeting_transcript`. Reference material for Alex only; never quote the transcript in the Ashby write-up, paraphrase instead. The heading folds in Obsidian, so a long transcript stays out of the way.

**Compare-notes flow.** When Alex says he'll write his post-call notes first and compare after: fill C immediately, present the scorecard-level findings and the subagent's second opinion in chat, and HOLD the final report until he's done writing, so it reflects the comparison instead of anchoring him. If his verdict and the independent read disagree, name the disagreement explicitly.

For calibration, the doc links a "what good looks like" example (Dan Hilton's interview notes); fetch it when drafting the final report if unsure of pitch or depth.

## Style Rules

Same as `/tremendous-interview-notes` and the PR review skill:

- The sentence after the tl;dr verdict is capitalized like a normal sentence; only the `tl;dr` label is lowercase
- Verdict options: Strong No, No, leaning Yes, Yes, Strong Yes, on the fence
- For referrals, lean toward Yes when on the fence
- Words to avoid: "thoughtful", "conversationalist"
- No em dashes anywhere
- Use /alex-writing-at-work for voice

**The readers wrote the rubric.** Never explain the interview's own machinery back to them: no "the doc says multiple schemas is a bad sign", no citing the criteria bullets back. Name the finding and move on; they built the scale.

**One line per pro and per con, one claim each.** If a con needs a paragraph to defend, it belongs in the gap analysis or the second opinion, not in the write-up.

## Discussion Signals

Weave discussion answers into the narrative and pros/cons. Good signs:

- Discusses trade-offs between approaches unprompted, or picks the right one directly and can defend it
- Takes steering: updates their position when nudged off a dispreferred approach
- Thinks about operational reality: locking, batching, zero-downtime rollout, background jobs
- Asks clarifying questions about business context, not just technical detail
