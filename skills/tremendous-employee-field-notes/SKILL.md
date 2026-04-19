---
name: tremendous-employee-field-notes
description: "Append entries to an employee field notes document in Notion. Use when Alex says /field-notes, asks to add/edit/update someone's field notes, shares a Notion URL with 'field notes' in the title, or asks to record key points about an employee in Notion."
argument-hint: "<notion-url>"
---

# Employee Field Notes

Maintain private, chronological field notes for employees in Notion. Field notes track
patterns of concern (missed deliverables, communication problems, repeated feedback) and
record evidence over time. They serve two audiences: Alex (coaching decisions) and
leadership (escalation).

## CRITICAL: Access Rules

- **NEVER search Notion.** Alex always provides the URL. No exceptions.
- **NEVER create Notion pages.** Alex creates them manually, then hands the URL.
- **NEVER write to Slack.** Read-only Slack access. The only write targets are Notion and Obsidian.
- **NEVER share, export, or link field note content to anyone.** No Slack posts, no email drafts, no shared links.
- **Append only.** Never edit or delete existing entries in the Notion page.
- **Always show draft before writing.** Never write to Notion without Alex's explicit approval.

## Workflow

### Step 1: Fetch the Notion page

Use `mcp__claude_ai_Notion__notion-fetch` with the provided URL. Parse to understand:

- **Person's name** from the page title.
- **Current tl;dr** (if one exists).
- **Most recent entry date** (to maintain chronological order).
- **Document structure** the page already uses.

If the page is empty (Alex just created it):
1. Confirm the person's name from the title.
2. Ask: "What triggered this note?"
3. Write the tl;dr and first entry together.
4. Set up Obsidian cross-links.

### Step 2: Gather source material

Process whatever Alex provides in the conversation:

- **URLs** (Slack, GitHub, Asana): Fetch content using the appropriate MCP tool or CLI.
  For Slack threads, use `mcp__slack__slack_get_thread_replies`. Resolve display names
  with `mcp__slack__slack_get_user_profile` (always use `real_name`, never `display_name`).
- **Free text:** Treat as Alex's direct observations or analysis.
- **Mixed input:** Separate evidence (fetched content, quotes, links) from Alex's interpretation.

If a Slack URL fails to fetch, say so and ask Alex to paste the content manually. Don't
silently skip evidence.

### Step 3: Check for recent 1:1 context (Granola)

Automatically look for recent meeting context with this person:

1. Check today's daily note (`journal/daily/YYYY-MM-DD.md`) for meeting notes mentioning
   the person. Granola notes are pulled there by an existing automation.
2. If local notes exist, use them as context. No need to call Granola.
3. If no local notes, use `mcp__granola__list_meetings` to find recent meetings with the
   person, then `mcp__granola__get_meeting_transcript` to pull the transcript.

**Granola rules:**
- Granola content is supporting context, not the entry itself. Use it to enrich Alex's
  observations, not to auto-generate entries.
- Always surface what was pulled from Granola so Alex can verify accuracy.
- Never quote Granola transcripts verbatim without Alex's confirmation (transcription
  errors are common).

### Step 4: Auto-detect entry type

Examine the input and classify using these priority rules:

1. **Explicit request wins.** If Alex says "structure this as O/I/A" or names a format, use it.
2. **Feedback language** ("observed," "impact," "I gave feedback," "I need to give feedback")
   produces an **O/I/A Feedback Block**.
3. **Multiple URLs or multiple dated events** tied to the same problem produce an
   **Evidence-Heavy Incident Entry**.
4. **Sensitive content** (tears, personal problems, mental health, family, medical) produces
   a **Personal/Sensitive Entry**.
5. **Otherwise**, produce a **Journal Observation**.

When uncertain, ask: "This looks like [type]. Should I format it that way, or did you have
something else in mind?"

### Step 5: Draft the entry

Present the draft to Alex showing:
- The date header that will be used.
- The entry content, formatted according to type.
- Any proposed tl;dr update (if applicable).

Wait for approval before proceeding.

### Step 6: Write to Notion

Use `mcp__claude_ai_Notion__notion-update-page` to append the entry. Append only.

**Notion API pitfalls (hard-won lessons):**

1. **Never use `\n` escape sequences in string parameters.** The Notion MCP tool treats
   `\n` as literal text, not newlines. Use actual newlines in the `new_str` / content
   parameters. If content renders as one giant paragraph, this is why.

2. **Never use `replace_content` to edit one entry.** It rewrites the entire page and
   risks mangling previous entries. Always use `update_content` with targeted `old_str`
   matches. If matching fails (e.g., dynamic S3 image URLs), use a smaller, unique
   substring that avoids the dynamic content.

3. **`<empty-block/>` is only for major section breaks.** Use it between date-header
   entries (`### Jan`, `### Feb`, `### April 2`). Never between subsections within an
   entry (bold labels like "My assessment:", "Action items:"). Notion's native block
   spacing handles subsection gaps. Over-using `<empty-block/>` creates visible blank
   lines that look broken.

### Step 7: Cross-link in Obsidian

See Obsidian Cross-Linking section below.

### Step 8: Propose tl;dr update (if warranted)

See tl;dr Management section below.

## Entry Types

**Header format:** always use `:` as separator, never `-`. The only place `-` appears is in
bullet points.

### 1. Journal Observation

**Format:**
```markdown
### Mar 24: [Short label]
[Narrative in Alex's voice. First-person, direct, uses contractions.]
Status: [open | resolved | monitoring]
```

### 2. Evidence-Heavy Incident Entry

**Format:**
```markdown
### Mar 24: [Short incident label]
**tl;dr** [One sentence summarizing the incident pattern.]
- **[Date]:** [Event description] [link or quote]
- **[Date]:** [Event description] [link or quote]
- **[Date]:** [Event description] [link or quote]
```

### 3. O/I/A Feedback Block

**Format:**
```markdown
### The Feedback (by Alex): Mar 24
**Observed:** [Specific, factual description. No judgment. Dates, actions, quotes.]
**Impact:** [Concrete consequence on team, project, or business. No emotional language.]
**Ask:** [Clear behavioral change. Forward-looking expectation. "Going forward, I need you to..." not "It would be great if you could..."]
```

If Alex describes how the conversation went, add below the O/I/A block:

```markdown
#### How it landed
[Narrative: Alex's voice. How the person received it, what they said, next steps agreed.]
```

### 4. Personal/Sensitive Entry

Same format as Journal Observation, but:
- Use more careful, human language.
- Don't summarize emotions reductively.
- Capture emotions factually ("she burst into tears," "he was visibly frustrated") without editorializing.
- Include what options were discussed and decisions made.
- Include what support was offered.
- If the content seems like it might create legal exposure (promises about employment,
  medical accommodations), surface a brief caution without playing lawyer.

## Writing Voice

Field notes use a hybrid voice. Load the `alex-writing-at-work` skill guidelines for
the full reference. Key points per entry type:

### Journal entries and narrative sections (including "How it landed")

Use `alex-writing-at-work` document style:
- First-person singular ("I noticed," "I gave feedback," "I validated").
- Direct, earnest, warm without being casual.
- Contractions freely ("didn't," "wasn't," "I'm").
- Medium-length sentences, mix of lengths for rhythm.
- No corporate jargon. Plain language.
- No hedging unless genuine uncertainty exists.
- Active voice throughout.

### Conciseness rules (applies to all entry types)

These are field notes, not narratives. Write for someone who already knows the people and
the org. Cut anything the reader can infer.

- **One sentence per bullet, max.** Don't elaborate inside a bullet point. If a bullet
  needs a second sentence, it's two bullets or the detail isn't needed.
- **Skip narrative setup.** Don't narrate how information reached Alex. "Magnus shared
  skip-level feedback" not "Magnus called me after completing skip-level interviews tied
  to performance reviews."
- **Self-assessment and analysis in bullets, not paragraphs.** When Alex's own take follows
  evidence, use a bulleted list under a bold label. Short, blunt lines.
- **Parenthetical status annotations.** Use inline parentheticals for follow-up status,
  corrections, or personal notes: "(never sent me anything)", "(I know he doesn't)",
  "(needs confirmation)".
- **Short assessment one-liners.** "My assessment: none of this is news to me." Direct,
  no softening, no preamble.
- **No `-` except in bullet points.** Headers, labels, and separators use `:` instead.

### O/I/A blocks

More structured and evidence-grounded:
- **Observed:** Purely factual. No interpretation. Specific dates, actions, quotes.
- **Impact:** Concrete consequences. Connect to team, project, or business outcomes. No emotional language.
- **Ask:** Clear, forward-looking. Framed as expectation: "Going forward, I need you to..."

### Sensitive entries

Same voice as journal, plus:
- More space for the other person's perspective.
- Capture emotions factually without editorializing.
- Include support offered and decisions made.

## tl;dr Management

The tl;dr sits at the top of the field note, immediately after the title. It summarizes
the overall situation, not just the latest entry.

**Rules:**
- **Propose, never auto-replace.** Draft an updated tl;dr and present it for confirmation
  before writing.
- **Material change means:** a new pattern emerged, a previous concern was resolved,
  escalation happened, or the overall trajectory shifted.
- **Not every entry warrants an update.** A single observation reinforcing an existing
  pattern doesn't change the tl;dr.
- **Format:** Bold `**tl;dr**` (lowercase, no colon) followed by dense 1-2 sentence summary.

**Example lifecycle:**

Initial:
```
**tl;dr** Filipe has a pattern of not reading shared documentation before asking
questions. Three incidents in February, feedback given March 1.
```

After feedback lands well:
```
**tl;dr** Filipe had a pattern of not reading shared documentation (three
incidents in Feb). Feedback given March 1, received well. Monitoring.
```

After resolution:
```
**tl;dr** Filipe had a pattern of not reading docs (Feb). Addressed in March 1
feedback. No recurrence since. Resolved.
```

## Obsidian Cross-Linking

Field notes are sensitive. Cross-links must be maximally discreet.

### Person file

**Location:** `people/@FirstName LastName.md`

Add a single line to the **Log** section:

```markdown
- [Private notes](https://notion.so/...)
```

- Generic label "Private notes." No year, no context, no description.
- Link points to the Notion page URL.
- Only add once per field note document. **Check if the link already exists before adding.**
- If the person's name (from the Notion page title) doesn't match any file in `people/`,
  ask Alex to confirm the correct file name. Don't create a new person file.

### Daily note

**Location:** `journal/daily/YYYY-MM-DD.md` (today's date)

Add a line under an appropriate section (or at the bottom):

```markdown
- [Notion](https://notion.so/...)
```

- **No person name.** No label beyond "Notion."
- If the daily note doesn't exist yet, create it with minimal structure matching the
  vault's daily note conventions.

### What NOT to do

- Never mention the person's name in the daily note cross-link.
- Never add context like "field notes" or "performance" in either cross-link.
- Never create a dedicated section or heading for field note links.
- Never store field note content in Obsidian. The vault only holds links.

## Multiple Entries in One Session

When Alex wants to add several entries at once (catching up on a backlog):

1. Process entries one at a time, in chronological order.
2. Ask for confirmation after each entry before proceeding to the next.
3. Propose a single tl;dr update at the end, not after each entry.

## Entry Contradicts Previous Entries

If new input suggests a pattern has reversed (e.g., the person improved after previous
entries documented problems):

1. Flag the positive change explicitly.
2. Propose updating the tl;dr to reflect the trajectory shift.

## MCP Tools Reference

| Tool | Purpose |
|------|---------|
| `mcp__claude_ai_Notion__notion-fetch` | Read existing field note content |
| `mcp__claude_ai_Notion__notion-update-page` | Append entries to the field note |
| `mcp__slack__slack_get_thread_replies` | Fetch Slack thread evidence |
| `mcp__slack__slack_get_user_profile` | Resolve Slack user display names |
| `mcp__granola__list_meetings` | Find recent 1:1 meetings |
| `mcp__granola__get_meeting_transcript` | Pull meeting transcript for context |

## Out of Scope

- Searching Notion for field note pages.
- Creating Notion pages.
- Sharing or exporting field note content.
- Performance review integration.
- Legal or HR advice.
- Editing or deleting existing entries.
