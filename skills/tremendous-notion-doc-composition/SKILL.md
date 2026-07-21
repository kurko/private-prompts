---
name: tremendous-notion-doc-composition
description: "Compose a document in Alex's private Notion Documents database. Use when Alex says /tremendous-notion-doc-composition, or asks to write, draft, or start a doc in Notion — for example 'write a doc about X in Notion', 'draft this in Notion', 'put this in my docs database'. Also use when he asks where a doc should live, or shares a page from the Documents database."
argument-hint: "<doc topic or source material>"
---

# Notion Doc Composition

Alex writes his working documents in one private Notion database. This skill puts new docs
in that database, with the right properties, in his voice.

## Where docs go

| Item | Value |
|---|---|
| Database | **Documents** — https://app.notion.com/p/3cbb8d8d6d4d4a11b387807ad7e1787e |
| Data source | `collection://1f280be5-fa2e-4d39-94d1-c155edd39d08` |
| Parent page | Alex Private Notes |

Create the page with `notion-create-pages`, and pass the data source above as the parent.
Do not create the page anywhere else. Do not create a new database.

## Properties

Set these on every new doc.

**Status: `drafting`.** Always. This is the whole point of the database: a doc starts as a
draft that Alex then edits. Never set `drafted`, `in review`, or `done` yourself. Those
states record his judgement of the work, not yours.

The full list, so you recognise the states when you read an existing doc:

| Group | Values |
|---|---|
| To-do | `not started`, `paused`, `next` |
| In progress | `drafting`, `in progress`, `drafted`, `in review` |
| Complete | `done`, `archived` |

**Name.** A short, specific title. Say what the doc is about, not what kind of doc it is.
"How to write to vendors" beats "Vendor communication document".

**Tags.** A multi-select. Pick from this fixed list only; do not invent a new tag:

`review-cycle`, `research`, `direction`, `people`, `retrospective`, `decision-tracking`,
`report`, `alignment`, `feedback`

Pick one or two. If none fits, leave Tags empty and say so.

## Voice

**Load the `alex-writing-at-work` skill before you write the body.** The doc must read as
his writing, not as generic AI prose. The database template is intentionally blank, so
there is no fixed structure to follow: pick a shape from the exemplars below.

## How his docs actually read

These rules come from reading eleven of his published docs. They hold across every doc
type, from a four-hundred-word Slack style guide to an eighteen-hundred-word roadmap.

**Give away the conclusion first.** Nearly every doc opens with a literal `tl;dr` line or a
one-sentence statement of what the doc does. Nothing opens with background, scene-setting,
or "as we all know". *Recording Datadog Metrics* opens `tl;dr prefer metrics in monitors and
dashboards, over logs and traces.`

**Headings are questions or claims, never nouns.** "Why do we use different teams per
case?", "Payoutable isn't expressive", "'Retries will solve transient network errors without
side effects'". A reader who reads only the headings must still get the argument. Avoid
"Overview", "Background", "Considerations" as headings unless the content really is that.

**Use bold-lead bullets, not tables.** None of his docs uses a markdown table. The workhorse
unit is `**Short label:** one-sentence explanation`, in parallel runs of three to seven.
Prose carries reasoning; bullets carry anything enumerable. Paragraphs longer than three
lines are rare.

**Give the reader's objection its own section.** This is the most transferable move he makes,
and it is why the docs read as a colleague reasoning rather than a manager ruling. See
"What estimates are not?", "Exceptions", "Risks / Dependencies", "Open Questions", and the
`# Questions` FAQ that forms the back half of *Catalog Monitoring*. Write the sceptic's
question verbatim as a heading, then answer it in one to three sentences.

**Fence the scope near the top, usually in a callout.** "Traces and Logs are not covered."
"State management is outside the scope of this project… However, we might make opportunistic
modifications where necessary." Fence it, then leave the escape hatch.

**Anchor every general claim to a specific.** A vendor name, a class name, a dated incident, a
SHA-pinned GitHub permalink with line numbers, a Datadog dashboard, a Slack thread, a real
number. Authority comes from specificity, not from position. Where there is no anchor, say
so — he ships "(can't find the message right now, sorry)" rather than quietly dropping the
claim.

**Why before how, always.** The motivation section precedes the instruction section in every
single doc.

**Own opinions in first person.** "I generally dislike subtasks on the main top-level view in
Asana, but…", "Traces are hard.", "I will call you on your mobile phone." Policy has no
author; his docs do. Mark which parts are judgement.

**State the failure mode, not just the rule.** "If we don't specify it, people will interpret
as live." The reason to comply is always visible.

**Borrow authority when a claim needs to stick.** Ron Jeffries on estimates, GitHub Pull
Requests as the model for case-run approval, Shape Up breadboarding. Anchor to something the
reader already accepts rather than asserting.

**Docs are living and openly unfinished.** Progress is stamped on top as `UPDATE June 2025:`
callouts rather than rewriting the original. Rejected alternatives stay in collapsed
`<details>` blocks with the screenshots that killed them. Stub headings ship. Optimise for
the doc existing and staying current over the doc being finished.

**Never write a conclusion.** Every doc ends in something actionable or something unresolved:
tips, a screenshot of the menu, next steps, open questions, an appendix of raw notes.

**Register is light and dry, never jokey or corporate.** Emoji in the page icon and sometimes
prefixing H2s. "Yeah, that might not be true." "Those pesky Net::ReadTimeout." "Trivia:".

## Reference docs — pick a shape before you write

Read the one or two closest to the request before drafting. Match the shape; do not copy the
content.

**How-to / runbook** — for a reader who has already decided and needs to act. Shape:
`tl;dr` → why → numbered or bolded steps → best practices. No Problems section, because the
problem is settled. Contains code, copy-able names, concrete numbers, good/bad pairs.

- [Recording Datadog Metrics](https://app.notion.com/p/tremendous/Recording-Datadog-Metrics-13a03136bd8c4ba6b218967de820279c) — the model how-to. Good/bad naming pairs, a blunt prohibition ("`tag:#{payout_id}` is a big-red no"), and cost treated as a design constraint with a real number.
- [Catalog vendor delays and Datadog metrics](https://app.notion.com/p/tremendous/Catalog-vendor-delays-and-Datadog-metrics-100eed2e0068808fa6d0ebd8aab498dc) — the narrow applied sibling. Note the `[async-only]` and `[optional]` prefixes on step titles so readers can skip safely, and how he refuses to over-prescribe thresholds.
- [Writing a #tremendous-releases message in Slack](https://app.notion.com/p/tremendous/Writing-a-tremendous-releases-message-in-Slack-e934b8adc6044d269bf2ac95a3981c7f) — house style guide. Every rule carries its consequence; examples are bare links, not prose.

**Brief** — for a reader who could say no. Shape: `Objectives` / `Problems` / `Proposal` /
`Questions` or `Appendix` / `Next steps`. Cites Slack threads and teammate quotes as evidence
that the problem is real, spends its back half absorbing objections, and ends by handing off.

- [Catalog Monitoring: Metrics and Alerts for Disruption](https://app.notion.com/p/tremendous/Catalog-Monitoring-Metrics-and-Alerts-for-Disruption-ef02483f601a4038a1af57e886b21a71) — tactical brief (2024). Objectives *before* Problems, so it never reads as a complaint. The `# Questions` FAQ is the model for absorbing objections.
- [Catalog redemption monitoring brief](https://app.notion.com/p/tremendous/Catalog-redemption-monitoring-brief-1b2eed2e006880aebb90d3789c62bf51) — strategy brief (2025), one level up from the above. Opens Problems with a teammate's attributed quote, not his own claim. The Appendix gives the sharpest objection its own heading and answers it.

**Important:** a list of named metrics, tags and thresholds is **not** a brief. In his usage
that is a child page titled `Proposal: ...` hanging off a brief. The brief's job is to
establish the problem is real, fence the scope, and pre-answer objections.

**Vision / proposal** — problem-first product argument. Shape: `Overview` (bolded thesis
lines) → `Problem Statement` → `Supporting Evidence` → `Users` → `Stories` → `Requirements` →
`Risks / Dependencies` → `Appendix / Open Questions`.

- [Class-Action Case-Runs Vision](https://app.notion.com/p/tremendous/Class-Action-Case-Runs-Vision-62df7ee8ed534d61b6e108b3fee6988e) — evidence kept in its own section, separate from the problem. Names the new concept (`CaseRun`), defines its state machine, and borrows GitHub PRs as a mechanism the audience already trusts. Declares fidelity ("low resolution diagram") so reviewers critique the right layer.

**Roadmap / initiative** — a living umbrella doc for multi-month work.

- [Roadmap: vendor refactoring (2025)](https://app.notion.com/p/tremendous/Roadmap-vendor-refactoring-2025-11beed2e006880929436c3744c76848a) — opens on business cost in the first sentence. A non-goals callout, `UPDATE:` stamps layered over the original, rejected alternatives collapsed with the screenshots that killed them, and problems named at the identifier level with permalinks.

**Primer / "start here"** — orient a newcomer to a complex domain.

- [Class-Action 101 for engineers](https://app.notion.com/p/tremendous/Class-Action-101-for-engineers-start-here-169eed2e00688031a4e4dc68c5b30d1a) — teaches chronology first (walk the lifecycle 1→4), architecture second. Maps business jargon to code jargon explicitly. Every "how do we know X works" answer is a live link, so the doc is a launcher rather than a description.

**Position / norm / culture** — argue a practice without preaching.

- [Estimates: the why, the how, the what](https://app.notion.com/p/tremendous/Estimates-the-why-the-how-the-what-4ad510d640e14bc9981ef08b1edc3300) — the title is the outline. A whole section named for the reader's fear ("What estimates are not?"). Symmetric failure analysis, so reflection reads as diagnostic rather than accusatory.
- [Disconnecting from Work](https://app.notion.com/p/tremendous/Disconnecting-from-Work-19031a65c7454f4083f7d934ea6e60cc) — benefits before expectations, always. First-person stakes ("You won't earn points with me if you're responding during time-off") instead of institutional voice. Ends on four clicks and a screenshot, removing the last excuse.

**Hard-won lessons list** — the "falsehoods programmers believe" genre, in-house.

- [Falsehoods about vendor integrations](https://app.notion.com/p/tremendous/Falsehoods-about-vendor-integrations-5b44f18df98941fbb8a91b56de73a8ca) — each heading is the *wrong* belief in quotes; each body is the correction. Skimming the headings alone gives the whole doc. Receipts in collapsed `<details>` blocks. One aphorism per section, then the specifics: "Documentation is a map, not the territory."

## Drafting is not posting

The vault rule says never post to Notion unless Alex says "send it" or "post it". This
database is the exception, and only this database. It is his private drafting space, so
writing here **is** the draft. Creating the page is the deliverable.

The rule still holds for everything else:

- Do not move the doc out of this database.
- Do not share it, add collaborators, or publish it to the web.
- Do not copy its content into a team space, a Slack channel, or an Asana task.
- Do not change the Status past `drafting`.

If Alex wants the doc somewhere else, he will say so.

## Steps

1. Gather the source material. Open every link he gives you first.
2. Pick a shape from **Reference docs** above, and open the one or two closest exemplars.
   Say which shape you picked and why before you draft.
3. Load `alex-writing-at-work`.
4. Draft the body against that shape and the rules in **How his docs actually read**. Check
   before you finish: is there a `tl;dr`? Is every heading a question or a claim? Did you use
   a table where bold-lead bullets belong? Does a section host the reader's objection? Is
   every general claim anchored to a name, a number, or a link? Did you end with a
   conclusion instead of something actionable or unresolved?
5. Create the page in the Documents data source, with `Status: drafting`, a specific Name,
   and one or two Tags.
6. Give him the page URL, the Name, the shape you followed, and the Tags you chose. Name any
   tag you considered and rejected, so he can correct you in one line.

## Reporting

State plainly what you created and where. For example:

> Created **How to write to vendors** in Documents, `Status: drafting`, tagged `alignment`.
> https://app.notion.com/p/...
> I considered `research` as well, but the doc argues a position rather than reporting findings.
