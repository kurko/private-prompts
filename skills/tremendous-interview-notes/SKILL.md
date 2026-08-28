---
name: tremendous-interview-notes
description: Write structured interview notes from raw bullet-point observations. Use when the user says "write interview notes", "write up the interview", "format my interview notes", or shares raw bullet-point notes from a candidate interview. Covers coding interviews, system design, PR review discussions, and any interview format.
argument-hint: "[raw notes or 'help']"
---

# Interview Notes

Write structured interview notes from raw observations. The user takes quick bullet-point notes during an interview, then this skill produces polished, structured notes ready for the hiring panel.

## Input

The user provides raw bullet-point notes from the interview. These are informal, shorthand, and may include:
- Observations about what the candidate did/said
- Timestamps or sequence markers
- Links (CoderPad, PR, etc.)
- Discussion topics and candidate responses
- Candidate questions
- The user's gut reactions

## Output Format

Generate notes following this exact structure:

```
**tl;dr** [verdict]. [One-sentence summary, capitalized like a normal sentence].

[link to exercise if applicable]

[1-2 narrative paragraphs describing what happened, key moments, and overall impression]

[If candidate asked questions, include:]
[Candidate's name]'s questions:
- [question 1]
- [question 2]

[Optional: caveats, context, or notable observations]

**Pros:**

- [pro 1]
- [pro 2]
- ...

**Cons:**

- [con 1]
- [con 2]
- ...
```

## Style Rules

These are mandatory — they reflect the user's actual writing voice.

1. **Verdict** appears in bold `**tl;dr**` followed by the verdict and a period. The sentence after the verdict is a normal sentence: capitalize it. Only the `tl;dr` label itself stays lowercase. Example: `**tl;dr** leaning Yes. Delivered comprehensive implementation with one security flaw.`

2. **Verdict options:**
   - "Strong No" — clear miss, significant concerns
   - "No" or "leaning No" — didn't meet the bar
   - "on the fence" — genuinely split
   - "Yes" or "leaning Yes" — meets the bar (use "leaning" when not a strong signal)
   - "Strong Yes" — exceptional
   - For referrals, lean toward "Yes" when on the fence

3. **Voice:** Direct, concise, first-person. No filler, no hedging. State observations as facts. Use contractions naturally.

4. **Words to avoid:** "thoughtful" as praise for the person ("she's thoughtful"); describing the manner of an action is fine ("used AI in a thoughtful way"). Also "conversationalist" (too formal), "insightful", "impressive" (too enthusiastic). Use concrete descriptions instead.

5. **Pros/Cons:** Each bullet is a specific, observable thing the candidate did — not vague impressions. Include context when it matters (e.g., "Whenever I nudged her, she immediately understood the problem and would fix the issue").

6. **Narrative paragraphs:** Describe what happened chronologically. Include key turning points. Mention specific code patterns, questions, or decisions the candidate made. Keep it to 1-2 paragraphs.

7. **Use the /alex-writing-at-work skill** for voice and tone calibration.

8. **Length:** The whole write-up fits in roughly half a page (~350 words). Don't re-describe the exercise artifact in detail; reviewers can click the link, and a detailed summary is expensive to verify against the source. Spend the words on judgment signals (how the candidate thinks, decides, communicates), not inventory.

9. **Raw notes ride along in Ashby:** Alex always pastes his raw notes at the bottom of the Ashby entry. The write-up doesn't need the full content of the meeting, only the highlights that weigh on the decision. So keep each narrative paragraph to 3-5 short sentences. Anything a reader can get from the raw notes below, or from clicking the exercise link, does not belong in the paragraph. If a paragraph is running long, the cut is almost always detail that is already sitting in the raw notes.

10. **ASD-STE100 sentence style (the standard since 2026-07):** Short sentences, roughly 20 words max. Active voice. One idea per sentence. Plain words over long ones. Alex prefers this over the looser prose of earlier write-ups; it keeps the report focused. Apply the spirit, not the aerospace dictionary.

11. **Cut redundant micro-conclusions.** Don't end a fact with a clause that only concludes what the reader just read ("At work he reviews AI-first, so the written catch rate is not his eye alone" — the second half adds no information). Keep a trailing clause only when it adds something new. Small factual asides go in parentheses: "(at work he reviews AI-first)".

12. **Name the real defect.** When a con involves a sequence of events, blame the actual problem, not the sequence. "He hand-waved what bad code is" is the defect; "he only defined it after I pushed" is not — needing a push is normal, a weak definition is the signal.

13. **Describe a directive tone; don't prescribe questions.** When a candidate's review feedback is all mandates ("We need to..."), describe that posture and contrast it with constructive framing: "felt like directives rather than constructive feedback." Never write that the candidate should have asked questions instead. A manager doesn't always need to ask; with trust built, directives land fine, and the interview can't show that relationship context. If the phrasing is hostile or disrespectful, say so plainly — that's an observation, not a prescription. (Alex's correction, 2026-08-25.)

## Placeholders

If you don't have enough information for a field, add a placeholder in brackets: `[candidate name]`, `[add-coderpad-link-here]`, `[verdict — need more context]`. The user will fill these in.

## Examples

See the interview note templates in the project file: [[Tremendous - projects - 2026 - PR Review Interview Scorecard]]

The user has shared two example pairs (raw → final) that demonstrate the expected style and depth. Match that level of specificity and directness.
