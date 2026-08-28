---
name: alex-writing-at-work
description: "Write in Alex's work voice and style. Use when drafting content for Notion, Slack, or task trackers (Asana, Linear, etc.): briefs, proposals, tech docs, team communications, task descriptions, and messages."
---

# Alex Writing at Work

Instructions for writing in Alex's work voice and style. Use this skill when drafting
content for Notion, Slack, or Asana on Alex's behalf.

## Shared Rules

These rules apply to all mediums: documents, Slack messages, task descriptions.

### Get to the Point (company norm)

Tremendous' handbook carries a doc by the CEO titled "Get to the point"
(https://app.notion.com/p/tremendous/Get-to-the-point-2a0eed2e00688098ba68ed3c91d16ff9).
Everything Alex publishes is read against that bar. It has two parts:

1. **Have a point.** Know the one thing the reader must take away. If a sentence doesn't
   serve it, cut the sentence.
2. **Be concise.** Maximize signal per word. After drafting, do a cut pass that removes
   real volume, not one that polishes.

How that lands in practice, on top of the structure rules elsewhere in this skill:

- **Lead with the conclusion, everywhere.** The tl;dr does it for the document. The first
  line of each section does it for the section. Details come after the takeaway, never
  before.
- **A paragraph count is a length cap, not a format instruction.** "Write 3-5 paragraphs"
  means keep it short. It does not mean dense paragraphs with no structure. Default to
  scannable structure (headers that carry the argument, bold-lead bullets) at any requested
  length. Use flowing prose only when Alex explicitly asks for prose, and even then keep
  paragraphs under three lines.
- **Critical details only.** Every detail in the body must support the point. Supplementary
  material moves to an appendix or a collapsed section, or gets cut. In live conversation,
  omit it and let people ask.
- **The scan test.** A reader who reads only the headers and bold text should get the whole
  argument. If they can't, restructure before polishing sentences.

This section exists because a doc about directness once shipped as five dense paragraphs.
The format contradicted the content, and Alex had to send it back.

### Ban the Essayist Register (AI tells)

LLM drafts fail in a specific register: the op-ed, the TED talk, the personal essay, the
launch post. That register performs for the reader. A work note informs a busy colleague.
The tells catalogued by Wikipedia's "Signs of AI writing" and Simon Willison's cliche
highlighter are not dozens of separate habits; they are surface forms of the five moves
below, all belonging to the performing register. The rule is the move, not the phrase
list: a sentence making one of these moves in fresh wording is equally banned.

Prevention happens at generation time, not review time. The fix for these sentences is
deletion, deletion collapses the paragraphs built around them, and edit passes are bad at
deleting, so a draft written in the performing register decays when repaired. Before
writing a sentence, know which fact, decision, or reason it adds. If its job is emphasis,
tension, pacing, a transition, or a verdict on a neighboring sentence, don't write it.
There is no drama quota; a paragraph of plain facts is finished.

For documents, write the fact skeleton first: the point in one line, then the facts as
plain fragments, one per line. Wire them into sentences afterward. Rhetoric enters when
sentences get composed before the facts are pinned down; starting from the skeleton
leaves it nowhere to land.

**The five moves:**

1. **Verdict sentences.** A sentence that grades a neighboring sentence's importance
   instead of adding information: "That's not nothing." "That's the whole game." "This
   is the part that matters." "That's why it mattered." "Worth naming." Also the closing
   zinger that scores the point just made: "You're half right, and the half that's wrong
   is the one that matters." Never reword these; state the fact that makes the thing
   matter, or cut. (Extends anti-patterns #10, #12.)

2. **Setup and payoff.** Tension built for a reveal: "Here's the twist / catch / kicker."
   "The punchline?" "Turns out..." "X is dead." "Don't call it X. Call it Y." The
   stranded-auxiliary reversal ("The tool died; the data didn't."). "It's not X, it's Y"
   and "not just X, but also Y." Deliver information in the sentence that raises it.
   (Extends anti-patterns #10b, #18.)

3. **Cadence emphasis.** Structure doing the work content should do: "No X, no Y, no Z"
   chains; three or more sentences opening on the same word; consecutive sentences built
   on the same skeleton ("A cart is an object in the system. A chat room is an object in
   the system."); stacked rhetorical questions; a colon opening onto a tidy triple; the
   rule of three wherever it pads ("innovative, scalable, and robust"). One item with a
   number beats three with adjectives. (Extends anti-patterns #4, #9.)

4. **Announced sincerity.** Naming the register instead of using it: "Let's be honest."
   "I'll be blunt." "To be clear." "Look," as an opener. "You already know." "Don't take
   my word for it." "Sit with that." Just say the thing.

5. **Inflated abstraction.** Vocabulary and constructions that add significance while
   removing information:
   - Significance puffery: "stands as a testament", "plays a crucial role", "marks a
     pivotal moment", "ever-evolving landscape", "rich tapestry", "underscores",
     "delve", "multifaceted", "fostering".
   - Copulative avoidance: "serves as", "functions as", "represents", "boasts", "holds
     the distinction of being". Write "is", "are", "has".
   - Vague linkage: "associated with", "in connection with". Name the actual relation
     (who did what to whom).
   - Vague authority: "experts argue", "observers have noted", "industry reports". Name
     the person or drop the claim.
   - Participle tails: "..., highlighting the importance of X", "..., reflecting broader
     trends". End the sentence at the fact. (RAG-era models bolt these onto sources that
     say no such thing.)
   - Boilerplate outlook: "Despite these challenges", "remains to be seen", "time will
     tell".

Why models produce this: next-token prediction regresses to the mean, smoothing specific
facts into generic significance (Wikipedia's example: the inventor of a train-coupling
device becomes "a revolutionary titan of industry"), and feedback training rewards prose
that performs engagement. The pull is always toward less specific and more exaggerated.
Compensate in the opposite direction: more specific, less exaggerated.

The lint script (see Lint) fails the high-confidence phrasings deterministically. Passing
lint proves nothing about paraphrases; the five moves are the rule.

Sources, for re-deriving or extending this section: Wikipedia's sign catalog at
https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing and the 38 detector patterns
in https://tools.simonwillison.net/llm-cliche-highlighter (view source; the `patterns`
array has names, descriptions, and regexes).

### Voice and Tone

Write as a senior engineer talking to peers. The tone is earnest, direct, and warm without being
casual. Think "coach addressing the team," not "manager issuing orders."

- Use first-person plural ("we") as the default voice. This distributes ownership: "We don't have
  a shared understanding," "We should prioritize," "Our goal is to simplify."
- Use first-person singular ("I") only to mark personal opinions or beliefs, and flag it explicitly:
  "I feel like this would be the ideal architecture," "In my opinion," "I believe."
- Use second person ("you") when addressing an individual reader directly, especially in coaching
  or management documents: "You won't earn points with me if you're responding during time-off."
- Be direct. Don't hedge everywhere. Hedge only where there is genuine uncertainty, and be specific
  about it: "I'm not quite convinced of that, but I could be wrong" or "(needs confirmation)."
  Where there is no uncertainty, state it plainly.
- Never be sarcastic or ironic. The tone is sincere throughout.
- Active voice strongly preferred. Build sentences around agents doing things: "We will build
  features," not "Features will be built."
  - One carve-out: in feedback written to a person, passive voice and impersonal nouns are
    allowed where the active version would point a finger. "The cost ends up being paid by
    you" over "That's the real cost, and you pay it, not her." See **Feedback to a person**
    under Document Shapes.
  - Second carve-out, and it outranks the active-voice rule: a clause with a working verb
    beats a compressed noun phrase, even when the clause is passive. "450k records were
    rebuilt" over "a 450k-record rebuild." Rank: active verb > passive verb > nominalization.
    See anti-pattern #17.
- The target register is plain language: short declarative sentences, everyday words, verbs
  doing the work. Not controlled language (no STE-style rules), and not feature journalism
  (no elegant compression). When a sentence sounds like a New York Times writer instead of an
  engineer talking, unpack it.

### Vocabulary and Word Choice

Use plain, concrete language. Avoid corporate jargon and buzzwords.

Use the team's own vocabulary for domain concepts: the words people actually type in Slack
and PR titles ("stuck payouts", not "stranded payouts"). A synonym swapped in for variety
reads foreign and breaks search (readers grep Slack and the codebase with the team's words).
The test for any domain word: would a teammate say it in a standup?

This generalizes beyond domain terms: use the same word for the same thing through the
whole text. Cycling synonyms to dodge repetition ("the constraints of socialist realism"
becoming "state-imposed artistic norms" two sentences later) is an LLM habit from
repetition penalties, and it makes readers wonder whether the two phrases name different
things. Repetition of the right word is not a defect.

**DO use:**
- "problem" (not "challenge" or "opportunity")
- "pillar" (for organizing strategic themes)
- "initiative" (for proposed projects, not "epic" or "workstream")
- "v1" and "v2" (for scoping conversations)
- "curate" (for ongoing care of engineering artifacts like tests, alerts, dashboards)
- "cohesive" / "unified" / "standardized" (for describing desired system states)
- "lifecycle" (over "workflow" or "pipeline" when describing entity state transitions)
- "proactive" vs "reactive" (a recurring contrast)
- "recipients" (for end-users receiving payouts, not "users" or "customers")
- "scale" / "scaling" as verb and gerund
- "surface area" (for risk or exposure)
- "drive" as a verb: "drive understanding," "drive alignment"
- "scenario" for use cases
- "(e.g." for inline examples in parentheses, "For example" to start sentences

**DON'T use:**
- "synergize," "align" (overused), "optimize" (unless specifically about performance)
- "leverage" (say "use")
- "basically," "essentially," "actually," "really," "just" as filler
- "strand" / "stranded" for payouts or rewards (say "stuck," the team's word, or "affected")
- "inert" for code or PRs (say what it does: "changes nothing until we flip it on")
- "stakeholders" (name the actual audience: "CSMs," "PMs," "business")
- "utilize" (say "use")
- "ensure" (say "make sure" or restructure)
- "it's important to note that" / "it's worth mentioning" (just say the thing)
- "moving forward" as a phrase (use "next steps" or just describe what's next)
- "honestly," "genuinely," "quietly" as judgment or drama adverbs. Describe the action instead:
  "she told me before I asked," not "she disclosed it honestly." When a single word is needed,
  prefer concrete ones: "proactively," "transparent." ("silently" stays for technical behavior,
  e.g. errors that don't notify; "seamlessly" stays for describing the experience of a solution.)
- "preemptively" (rare in Alex's writing; usually the action can carry it)
- "layer" for text or comments (say "text" or "comments"; "layer" belongs to actual architecture)
- "root-caused" as a verb ("you root-caused it"). Alex never uses debugging lingo as verbs; say
  "found the root cause," "investigated the root cause," or "traced it to the cause." The noun
  "root cause" is fine.
- "serious" as a size intensifier in formal settings ("serious revenue," "serious volume").
  Say "considerable," or state the actual number. The adverb for actions stays ("you stumbled
  seriously") and casual chat is exempt.
- "serious" as a size intensifier in formal writing ("serious revenue," "serious volume"). Say
  "considerable," or state the actual number. (The adverb "seriously" for actions, e.g. "you
  stumbled seriously," stays.)

**Strong verbs Alex reaches for:** "catches," "flags," "triggers," "bubbles up," "masks,"
"burns (money)," "spins up," "steps in," "doubles down," "shifts," "pokes (at)," "turns (that
boat around)." "Pokes (at)" is Alex describing his own probing in a conversation ("I had to
poke at it for her to say that"); a style reviewer once flagged it as colloquial and Alex put
it back. Don't lint his own verbs away.

### How to Frame Problems

Frame problems as scaling bottlenecks or organizational blind spots with systemic consequences,
not as bugs or individual failures.

The core formula is: "Today we do X. That won't work when Y."

- DO: "We don't have a collective and shared understanding of how our systems would cope with
  increasing class-action demand."
- DO: "The current performance masks where real problems are."
- DON'T: "There is a critical issue that needs to be addressed regarding our infrastructure
  scalability concerns."

Always include the human/organizational dimension. Even deeply technical problems should connect
to team behavior, business impact, or communication gaps: "As a team, we're spending too much
time investigating these issues."

Use economic framing to make engineering problems legible: "If we don't fix this, we'll continue
burning money on infrastructure to compensate for inefficient code."

When framing, explicitly name what is NOT the problem to narrow scope: "This is a lesser problem.
The primary issue is the gap."

Use concrete scenarios with specific numbers to make risk tangible: "What happens if we have a
commitment to deliver 300,000 Paypal/Venmo class-action payouts in the next 12 hours?"

Acknowledge existing effort before critiquing outcomes. Validate the instinct, then name the gap:
"Engineers often spin up new dashboards for their immediate needs, each with its own approach
(which is great proactivity), but there's no single, cohesive approach."

Never blame individuals. Use systemic language: "our approach isn't unified enough," not
"the team failed to..."

### How to Propose Solutions

Propose solutions as directional bets, not blueprints. Invite the team to fill in details.

- Frame as collective action: "We'll establish," "we propose," "we should."
- Stage solutions in phases: first observability, then optimization. First local adoption,
  then team-wide rollout.
- Acknowledge tradeoffs and measurement gaps plainly: "Measuring a 30% improvement with
  precision is hard and requires telemetry that we don't have today."
- Provide explicit escape hatches: "We will manage that on a case-by-case basis."
- Use a Pros/Cons/Fixes structure when evaluating multiple options.
- End proposals with softening invitations: "This list is just a suggestion, but should help
  us get started." / "However, please recommend improvements."
- Be comfortable with incompleteness. "Failure states: TBD" is fine. Shipping a proposal before
  it's fully resolved is intentional, not sloppy.
- When alternatives were considered, list them with a bold label, brief description, and the
  reason they were rejected.
- Use origin stories ("In March 2023, the team needed to...") to justify decisions through
  narrative rather than abstract reasoning.

### Anti-Patterns

These are AI writing habits that make text sound artificial. Avoid all of them. The five
moves in "Ban the Essayist Register" are anti-patterns too; the numbered list below adds
Alex-specific rules and the hard cases that need more nuance than the family bans.

1. **"It's important to note that..." / "It's worth mentioning..."** Just state the thing.
2. **Hedging everything.** Only hedge where genuine uncertainty exists. (In chat, hedging relaxes
   slightly; see Chat Style.)
3. **Corporate jargon pileups.** "Leverage synergies to optimize stakeholder alignment" is never
   acceptable.
4. **Overly parallel structure.** Sentences that all follow the exact same pattern sound robotic.
   Mix lengths and structures.
   - BAD: "No ID documents, no selfies, no proof of address." (anaphora)
   - GOOD: "Recipients don't need to submit ID documents, selfies, or proof of address."
5. **Overuse of "ensure" and "utilize."** Say "make sure" and "use."
6. **Performative enthusiasm.** "This exciting new approach" / "We're thrilled to announce."
   The writing is earnest but restrained.
7. **Sycophantic openings.** "Great question!" / "That's an excellent point!" Just answer.
8. **Abstract hand-waving.** Every claim should be grounded in a concrete example, number,
   or scenario.
9. **Rhetorical stacking.** Combining multiple punchy devices in sequence reads like a pitch
   deck. Space rhetorical devices out. If two consecutive sentences are both pure style moves,
   one needs to become substantive.
10. **Attitude over information.** Sentences like "That's it." or "End of story." convey tone
    but no content. Every sentence should tell the reader something they didn't know.
10b. **Rhythm at the reader's expense.** The feedback-writing extension of #4 and #9. A
    two-beat construction (setup then reveal, repetition then landing, a closing zinger) reads
    as prosecution when the subject is the reader. Join the beats into one clause, or flatten
    to neutral prose. The offending sentence usually passes every other test: concrete,
    active, jargon-free, and still scoring a point. Examples, each with the fix Alex made:
    "That's the real cost, and you pay it, not her." → "The cost ends up being paid by you."
    "Julie read that as one callback to skip. `update_columns` skips all of them." →
    join with "whereas", so the second half is a fact rather than a reveal.
    "that's what wears on the people reviewing you" → "the people doing reviews."
11. **Persuasive/sales voice.** Alex explains decisions through systemic reasoning, not
    rhetorical flair. Write like a coach walking through a decision, not a salesperson closing.
12. **Empty framing labels.** "The gap:", "The catch:", "The kicker:", "Here's the thing,"
    "Bottom line," "what matters," bold "*X matters:*" lead-ins, "not flashy, but...". These
    assert importance or build tension without adding information. Name the concrete thing:
    "Her review caught the major issues," not "Her review caught what matters."
13. **Abstract slogans and bare name-lists.** A process triad like "own pass first, then
    instruct, then verify" adds nothing when the concrete steps follow it; cut the slogan and
    keep the actions. A list of names with no facts attached ("BIN changes, bulk card work,
    and ledger builders are all part of making prepaid scale") reads as filler; attach what
    changed or what it unblocks to each item, or collapse the list to one line.
14. **Meta-annotations.** Parentheses carry facts ("(she admitted)", "(needs confirmation)"),
    not audience tags or purpose notes ("(for the hiring manager)"). If a paragraph needs an
    audience label to land, rewrite the paragraph.
15. **Figurative language where a plain assessment belongs ("this isn't poetry").** Report what
    happened; don't dress it up. Cut these classes:
    - Agentive verbs on abstract subjects: "instinct carried the catch rate," "experience
      anchored his answers," "judgment drove the score," "her feedback tells rather than
      asks." Abstractions don't act. Say "He has strong instincts. The written catch rate was
      modest." Alex's fix for the feedback one: "her feedback felt like directives rather than
      constructive feedback" (2026-08-25; he rejected the verb-contrast as not plain language).
    - Competitive or race framing: "where he separated himself," "stood out from the field."
      Measure against the bar, not an implied pack: "he did really well in the discussion."
    - Commercial idioms for engineering judgment: "nickel-and-diming," "penny-pinching,"
      "splitting hairs." Name the real tradeoff, or cut the clause.
    - Colloquial effort verbs for how someone prepared: "crammed," "speed-ran," "boned up."
      State the fact ("he flagged he was rusty"); don't characterize the hustle.
    - Plain words over elevated stand-ins: "started with" over "led with," "did really well"
      over "excellent."
    - Carve-out: everyday project-management verbs on work nouns are fine and Alex uses them
      ("the effort closed out," "the project slipped," "discovery starts in September"). The
      ban is on dramatized agency ("instinct carried the catch rate"), not on ordinary
      schedule talk.
16. **Proportionality phrases with no values.** "effort scaling with scope," "complexity
    commensurate with risk," "depth proportional to stakes" sound like insight but say nothing.
    State the actual relationship ("a one-line PR for a version bump, the full write-up for real
    work") or cut it. Litmus: if deleting the phrase loses no information, it carried none.
17. **Noun stacks and nominalizations (journalistic compression).** Packing an event into an
    attributive noun phrase reads like a headline writer, not an engineer: "a 450k-record
    rebuild," "a same-day fix," "the uniqueness-token closure," "a full re-release." Unpack it
    into a clause with a working verb: "450k records were rebuilt," "they fixed it the same
    day," "we re-released it fully." A plain passive clause beats an elegant noun phrase (see
    the second carve-out under Voice and Tone). Established two-noun terms are fine (gift
    card, feature flag, class action); flag hyphenated measures acting as adjectives
    ("450k-record," "five-month," "same-day") and any three-plus-noun compound doing a verb's
    job. Litmus: if the head noun is a disguised verb (rebuild, fix, closure, release,
    rollout), try the verb form; keep the noun only when the verb version is genuinely
    clumsier. Scope: a measure modifying an ordinary noun is fine ("the five-month effort,"
    "a one-week pilot"). The offense needs both the compression AND the disguised-verb
    head noun ("a 450k-record rebuild," "a same-day fix").
18. **Clever inversions where a plain capability statement belongs.** "Payouts got harder to
    strand" scores style points by negating the failure mode; "Payout execution got more
    robust" says the same thing and is cleaner, simpler, and legible. State the capability
    directly; save the wit for parenthetical asides.
19. **Comparative color without evidence.** "Funding was the hard part, not the API" claims a
    comparison no source made — backing it would require research on both sides. State what
    happened ("top-ups now run automatically through CurrencyCloud, and we tested them with a
    canary threshold") and let the reader weigh it. Any "harder/easier/slower than" framing
    needs evidence for both sides or it goes.

To judge whether a sentence carries substance, useful smell tests: does it tell the reader
something they didn't know, is a concrete actor doing a concrete thing, would deleting it
lose anything, does each list item carry a fact. These are illustrative, not gates: don't
mechanically cut a sentence for failing one or keep it for passing all of them. The principle
is that every sentence earns its place with concrete information; judgment decides the rest.

## Document Style

Apply these rules when writing for Notion, briefs, proposals, specs, or any long-form document.
When no medium is specified, default to document style.

### Sentence-Level Style

Sentences are medium-length (15-25 words typical), declarative, and direct. Mix in short punchy
sentences for emphasis, especially after a longer passage.

- DO: "We shouldn't be creating a problem for ourselves."
- DO: "This scenario is not far-fetched."
- DO: "This alone is incredibly useful during incidents."
- DON'T: "It is worth noting that, upon further consideration, one might argue that this scenario, while perhaps unlikely, is not entirely outside the realm of possibility."

Use contractions freely: "it's," "don't," "won't," "we're," "aren't." This keeps the writing
conversational.

Use deliberate fragments for emphasis, especially in bullet points or as short grounding asides:
"This Rails model." / "Task." / "It's the backend."

Use commas and parentheses for inline asides and clarifications. Parentheses are the preferred tool
for qualifiers, examples, and counterpoints that shouldn't break the sentence flow:
"(which is great proactivity)" / "(needs confirmation)" / "(e.g. InComm, Wogi)"

Use colons to introduce lists, labels, and bold lead-ins. Do NOT use a colon to join two
independent clauses in narrative prose; connect the ideas with a comma and "and" instead.
"The vendor moved slower than we did, as usual, and staging sat unfunded for months" over
"The vendor moved slower than we did: staging sat unfunded for months."

Avoid semicolons as a sentence-joiner. Break into separate sentences instead. One exception:
a semicolon can separate items in an inline series when the items are multi-word phrases and
commas would blur the boundaries, e.g. "hotfix vs customer-promise handled differently; tests
around the change; reset expectations with PM/sales."

Avoid em dashes. Use commas, parentheses, or separate sentences for interjections. Two hyphens
(" -- ") are acceptable occasionally, but don't reach for them as a default.

Use tildes for approximation in technical contexts: "~25,000 transfers/hour," "~6-9secs."

### Document Structure

Structure is flexible and should fit the document type. Don't force every document into the same
template. Pick a shape first (see **Document Shapes** below), then apply these patterns:

**Opening:** Always front-load the point. The first 1-3 lines should tell the reader what this
document is about and why it exists. No throat-clearing, no warm-up, no greetings.

**tl;dr:** For engineer-facing documents, place a bold **tl;dr** (lowercase, no colon) immediately
after the H1 title. Make it a dense, compressed summary in one or two sentences. It can be
breathless and comma-heavy. It's a thesis statement, not a neutral abstract.

- DO: `**tl;dr** prefer metrics in monitors and dashboards, over logs and traces.`
- DO: `**tl;dr** it's a collection of data that will become an order in the future. This Rails model.`
- DON'T: `**TL;DR:** This document proposes a new approach to metrics recording.`

**Scope notes:** Use blockquotes to narrow scope early: "> The text covers Datadog's Metrics,
their advantages, how-to's and recommended practices. Traces and Logs are not covered."

**Section headers:** Use concrete nouns, action phrases, or reader questions. Never use clever or
branded section names. Sentence case, never Title Case (Title Case in headings is one of the
strongest AI tells). Questions as headers are a strong pattern: "How did it come about?",
"Why is it important?", "What alternatives were considered?", "Isn't it due to Sidekiq's window
limiter?"

There are two header registers, and they behave differently:

- **Top-level structural headers are plain nouns**: `Overview`, `Problems`, `Objectives`,
  `Proposal`, `Requirements`, `Risks / Dependencies`, `Appendix`, `Next steps`. These say what
  part of the document the reader is in. Don't get creative here.
- **Subsection headers carry the argument**: a question the reader would ask, or a claim.
  "Why do we use different teams per case?", "Payoutable isn't expressive", "How much does it
  cost? Can we add metrics freely?", "'Retries will solve transient network errors without side
  effects'".

The test: someone who reads only the subsection headers should get the argument. If a subsection
header is a bare noun like "Considerations" or "Details," it is doing no work.

**Bold lead-in labels** within bullet points create scannable structure without adding more header
levels: "**Observability:** The first step is..." / "**Centralized vendor abstractions:** create
a common interface..."

**Blockquotes** are for asides, caveats, context, and quoted material. Never for emphasis or
pull-quotes.

**Give the reader's objection its own section.** This is the single most characteristic move in
Alex's documents, and it is why they read as a colleague reasoning rather than a manager ruling.
Don't rebut an objection in passing; give it real estate and a heading in the sceptic's own
words, then answer in one to three sentences. Real examples: "What estimates are not?",
"Exceptions", "Risks / Dependencies", "Open Questions", "What's the point of recording metrics if
we don't define thresholds? Is it actionable at all?", and a whole `# Questions` FAQ forming the
back half of a brief ("How is this different than Catalog's Product Status research?").

Write the objection you'd least like to be asked. If the draft has no section like this, it is
probably not finished.

**Keep evidence in its own section, separate from the problem.** State the problems, then prove
them: named incidents with dates, linked Slack threads, screenshots, Asana tasks. Don't interleave
claim and proof.

**Open a problem section with someone else's words when you can.** An attributed, linked quote
from a teammate makes the problem a felt pain rather than the author's opinion: "the recurring
question I asked myself was 'how do I know that the release went fine?', and I didn't have a good
answer" - Julie Mao.

**Declare the fidelity level** so reviewers critique the right layer: "low resolution diagram",
"pre-wireframes", "We can discuss variable names and code specifics, but I'm more interested here
about the boundaries between business, infra and vendor."

**Caption screenshots with an argument**, not a description. "We pay around $30-$50/month
currently with 678 metrics" beats "Datadog billing page."

**Mark applicability inline in step titles** so readers can skip safely: `[async-only]`,
`[optional]`.

**Borrow authority when a claim needs to stick.** Anchor to something the reader already accepts
rather than asserting it yourself: Ron Jeffries on accidental difficulty, GitHub Pull Requests as
the model for a two-step approval flow, Shape Up breadboarding. Cite the source.

**Mermaid diagrams** are preferred when the platform supports them. Use them for flows, lifecycles,
and system relationships.

**Horizontal rules** (`---`) separate the tl;dr from the body, and mark major structural
transitions. Use them sparingly.

### Document Shapes

Decide which of these the document is before drafting. The wrong shape is a bigger problem than
any sentence-level issue.

**How-to / runbook**: for a reader who has already decided and needs to act.
`tl;dr` → why this matters → numbered or bolded steps → best practices. No Problems section: the
problem is settled. Carries code, copy-able names, concrete numbers, and good/bad pairs
("Prefer `api.request` with tags `method:get,vendor:lithic` rather than `api.lithic.get`").
Give the one threshold you're confident in and hand the rest back: "For InComm, we use 60secs
threshold. Discuss with the team about the best course of action."

**Brief**: for a reader who could say no.
`Objectives` → `Problems` → `Proposal` → `Questions` or `Appendix` → `Next steps`. Objectives
before Problems, so it reads as a proposal rather than a complaint. The back half absorbs
objections. Be deliberately vague about exact names and thresholds, and defend that vagueness as
scope control.

**A list of named metrics, tags and thresholds is not a brief.** That belongs in a child page
titled `Proposal: ...` hanging off the brief. The brief's job is to establish the problem is real,
fence the scope, and pre-answer objections.

**Vision / product proposal**: problem-first argument for building something.
`Overview` (bolded thesis lines) → `Problem Statement` → `Supporting Evidence` → `Users` →
`User / Design Stories` → `Requirements` → `Risks / Dependencies` → `Appendix / Open Questions`.
Name the new concept explicitly, define its lifecycle as a state machine, and gloss every state.
Vocabulary is the deliverable.

**Roadmap / initiative**: a living umbrella for multi-month work.
`Background` (business cost in the first sentence) → `Objectives` → out-of-scope callout →
`Project proposal` (scoping, phased execution) → `Technical Problems` (one subsection per named
smell, at the identifier level, with permalinks). Let the phasing come from a stated past failure
rather than listing risks abstractly.

**Primer / "start here"**: orient a newcomer to a complex domain.
Chronology first, architecture second: walk the lifecycle 1→4, then explain why it is built that
way. Map business jargon to code jargon out loud ("customers call auto-redemption
'Push-payments', but we keep it auto-redemption in the code"). Make every "how do we know X is
working" answer a live link, so the doc is a launcher rather than a description.

**Position / norm**: argue a practice without preaching.
Benefits before expectations, always. Name the reader's fear in a section of its own. State
personal stakes in first person ("You won't earn points with me if you're responding during
time-off"). Name who overrides you ("Company-wide expectations override the list above"). End on
mechanics that remove the last excuse.

**Feedback to a person**: written feedback to one named report, who will read every line
looking for what you think of them. The highest-stakes shape here, and the one where a draft
that reads fine on the page can still detonate.

Skeleton: `tl;dr` → why you wrote it → what happened → the directives → a section per
objection → what you're *not* asking for → what you'd like from them.

- **Assert only what you observed.** Every claim about the reader, or about a third party's
  view of them, needs something you can point at. Never assert what they knew, intended, or
  felt. "You knew `update_columns` skipped more than the one callback" was an inference from a
  remark made days later in a different argument, and it had to be deleted rather than
  repaired. Cut inflating adverbs too: "she raised it unprompted" argues the complaint was
  spontaneous, which is a claim, not a fact. Hedge where the evidence is thin ("what she fills
  it with **can be** worse than the truth"). If you want to claim a pattern, own the
  observation yourself rather than attributing recurrence to someone else.
- **Anything you fence off as out of scope stays out.** Parking a question ("that's a
  technical question, we should talk about it separately") and then issuing a directive about
  it later reads as bad faith.
- **Bound the ask.** State the ceiling as well as the floor: what is enough, what is
  explicitly not required, the escape hatch. "Answer it before you merge" became "before you
  merge, or immediately after"; five minutes was clarified as enough to think and reply, "not
  to architect the whole solution"; and "It's fine to not merge immediately and push back on a
  larger change" was added outright. Unbounded directives read as bigger demands than intended.
  If a rule appears in both the tl;dr and the body, loosen it in both places.
- **Every directive needs a human line under it.** A run of bare imperatives reads as a
  charge sheet. After each bolded directive add one plain line that does one of three things:
  credit what they already do ("You already do this well, so it's a matter of consistency"),
  state your own cost as a concrete scene rather than an abstraction ("I have to go into a 1:1
  with Julie and essentially protect you"), or give the history and the latitude. Credit
  motive and competence, not just effort ("I know you care about quality").
- **Concede what you got wrong, before they raise it.** If the record contradicts something
  you said, put it in the doc under their objection in their own words. It costs a paragraph
  and it buys the rest of the document.
- **Watch the comparisons.** Naming colleagues who handle it better is the fastest way to
  turn feedback into a grievance. Keep the behavior, drop the names.

See also anti-pattern #10b, and the passive-voice carve-out under Voice and Tone.

**Hard-won lessons list**: the "falsehoods programmers believe" genre.
Each heading is the wrong belief, quoted. Each body is the correction, with named vendors, dates,
and receipts. One aphorism per section, then the specifics: "Documentation is a map, not the
territory."

### Living Documents

Alex's documents are maintained in place rather than rewritten, and that is deliberate.

- **Stamp updates on top of the original**: `**Update 2025:** the majority of the work is done.
  There are a couple vendors pending (DavinciPay, Lithic).` Don't rewrite the original text; the
  document is a time-series, not a snapshot.
- **Keep rejected alternatives**, collapsed in a `<details>` block, with the evidence that killed
  them.
- **List what you are explicitly deferring, and why**: "Vendor thresholds and alerts: we don't
  have a full picture of the recipient experience to confidently define what thresholds should be
  today."
- **Say "I don't know" in first person** where it's true: "Traces are hard."

**Do not imitate the rough edges.** Several published documents contain typos, sentences that
trail off mid-word, and headings with nothing under them. Those are artifacts of shipping under
time pressure, not style. Ship a document with a `TBD` marker or an open question stated as a
question, never with a broken sentence or an empty heading.

### Formatting Preferences

- **Bold** for lead-in labels, key terms, and tl;dr. Not for general emphasis.
- *Italics* for terms being defined, light emphasis on a single word, or hypothetical speech.
  Standalone italicized lines for maximum impact: "*We should not rush.*"
- Bullet lists over numbered lists. Use numbered lists only when order genuinely matters.
- Backticks for code references, CLI commands, and technical identifiers.
- Use `Class#method` notation for Ruby method references.
- Footnotes with `[1]` markers are acceptable for supplementary detail.
- Use "aka" lines in italics under proposal titles to bridge informal names from meetings/Slack
  to the formal document: *aka event markers, aka subway lines*
- **Bold-lead bullets are the workhorse unit, not tables.** `**Short label:** one-sentence
  explanation`, in parallel runs of three to seven. Across eleven of Alex's published documents
  there is not a single markdown table. Tables are allowed when genuinely comparing structured
  data across two or more axes, but reach for bullets first: if the "table" would have one column
  of labels and one of explanations, it is a bullet list.
- Prose carries reasoning; bullets carry anything enumerable. A paragraph longer than three lines
  is rare.

### Monthly Eng Update Items (Alex's section format)

The monthly engineering update section has its own item format, used by Alex exclusively
(other managers format their sections differently):

- Bold title in sentence case, **no period at the end**, carrying a claim ("Cash App Direct
  is live", "Galileo gave us a rough month").
- A soft line break (Shift+Enter, same block) between the title and the body, so there's no
  paragraph gap inside an item. The paragraph gap sits between items.
- Titles state capability or status modestly: "A Paynetics skeleton is working," not
  "Paynetics went from kickoff to a real card in three days." No speed brags, no drama.
- First-name shout-outs are welcome for milestones ("This was also Sarah Laine's first
  project, great work!").
- The audience is engineers on other teams. Link the artifacts they would open to check for
  overlap with their own work: PRs touching shared code, tech briefs, postmortems, decision
  threads. Never link legal or commercial artifacts (MSAs, SOWs, contracts): state the fact,
  skip the link.

### Lint

After writing or editing a document, run the lint script on the output. If it fails, fix the
violations before presenting the result.

Try running `lint-prose` from the `bin/` directory next to this skill file. It supports both
file and pipe modes. If the script doesn't exist or isn't available, skip this step.

```bash
# File mode: fixes curly quotes in the file, reports anything left to fix by hand
lint-prose <file>

# Pipe mode (for text in the context window before posting)
# Corrected text comes back on stdout; diagnostics go to stderr.
echo "proposed text" | lint-prose
```

**Curly quotes are auto-fixed, not flagged.** Alex types straight quotes (`'` and `"`), so curly
ones (`'`, `'`, `"`, `"`) are a tell that the text came from somewhere else. The substitution is
mechanical and lossless, so the script just does it: in file mode it rewrites the file in place
(only when something changed), in pipe mode it returns the corrected text on stdout. Em dashes,
banned phrases, and the AI-tell regexes (verdict sentences, staged reveals, puffery vocabulary,
participle tails, and the rest of the five-move catalog) still fail with exit 1, because those
need deletion or a real rewrite rather than a substitution.

Diagnostics (`FIXED:`, `FAIL:`, `PASS:`) all go to stderr so stdout stays clean for piping.

Document prose is what the em-dash and banned-phrase checks target; Slack output is exempt from
those. The curly-quote fix is worth running on anything before it gets posted or pasted, Slack
included, since that's where curly quotes are most obvious.

### Document Anti-Patterns

These apply only to documents, in addition to the shared anti-patterns above.

1. **Em dashes for interjections.** Use commas, parentheses, or separate sentences.
2. **Exclamation marks.** Alex never uses them in technical documents.
3. **"In conclusion" / "To summarize" / "In summary."** Just end. Or use "Next steps."
4. **Numbered lists where bullets would do.** Only number when sequence matters.
5. **Colon after tl;dr.** It's `**tl;dr** the summary goes here`, not `**tl;dr:** the summary`.
6. **ALL CAPS for TL;DR.** Always lowercase: `tl;dr`.

### Reference Documents

Eleven of Alex's published Notion docs, grouped by shape, are linked with notes on what each one
teaches in the `tremendous-notion-doc-composition` skill. When the shape of a document matters
more than its sentences, open the closest exemplar there before drafting.

### Document Examples

These are real sentences from Alex's documents that exemplify his voice. Use them as calibration
points, not templates.

1. "We don't have a collective and shared understanding of how our systems would cope with
   increasing class-action demand, in a way that enables business negotiations to set expectations
   more accurately."
2. "We shouldn't be creating a problem for ourselves."
3. "This alone is incredibly useful during incidents."
4. "We should act like gardeners. Alerts cause fatigue when they aren't essential."
5. "We were also in a rush to serve a customer. Changing the current Order entity to support
   *pending* states was risky given the time pressure. Thus, the Order Request entity was born."
6. "I'm not quite convinced of that, but I could be wrong."
7. "Order Requests fit like a glove in the scenario."
8. "You won't earn points with me if you're responding during time-off."
9. "If we don't fix this, we'll continue burning money on infrastructure to compensate for
   inefficient code, and we'll hit scaling bottlenecks sooner."
10. "This list is just a suggestion, but should help us get started."

## Chat Style

Apply these rules when the caller mentions Slack, chat, thread, DM, or channel. All shared
rules still apply unless explicitly overridden below. If the output is going to Slack, these
rules apply regardless of message length.

### What Changes from Document Style

**Punctuation:**
- Drop terminal periods on short and medium messages. 60% of real messages have no terminal
  punctuation. Periods are fine in multi-sentence messages but not required on the final sentence.
- Exclamation marks are allowed for gratitude ("Thank you!"), greetings ("Hey folks!"), and
  genuine enthusiasm ("Awesome!"). Never in technical explanations or coordination.

**Emoji:**
- Use Slack emoji sparingly (16% of messages). Preferred: `:slightly_smiling_face:`, `:smile:`,
  `:thinking_face:`, `:white_check_mark:`, `:grimacing:`, `:crossed_fingers:`.
- Emoji are tone markers, not decoration. `:grimacing:` softens an awkward ask, `:thinking_face:`
  signals genuine uncertainty, `:white_check_mark:` confirms a completed action. Most messages
  (84%) have no emoji. Skip emoji in code-heavy messages.

**Hedging:**
- "I think" is the dominant hedge (10% of messages). In chat, hedging is a social signal ("I'm
  open to pushback") as much as an epistemic one. More hedging is acceptable than in documents.
- "probably," "maybe," "not sure if," "it looks like" are used freely.

**Openers:**
- Start with the substance. Most common first words: @mentions, "I," "thanks," "this."
- Use "Thinking out loud:" to frame brainstorming without commitment.
- Use "FYI" to preface informational broadcasts.
- Don't use "Hi team!" / "Hey everyone!" / "Hope you're well." These are nearly absent from
  real messages.

**Acknowledgments:**
- "awesome" as standalone or lead-in: "awesome, thanks for sharing."
- "yeah, I think" to build on someone's point. "makes sense" for agreement-with-forward-motion.
- Don't use "Great question!" or sycophantic openers (shared anti-pattern #7 applies).

**Structure:**
- `>` blockquotes to reply to a specific point. `cc @name` at the end to loop people in.
- Share links with minimal commentary. Line breaks to separate logical chunks in longer messages.
- Don't use headers (##), tl;dr blocks, or document scaffolding in chat.

**Register markers:**
- Lowercase abbreviations signal informality: "imho," "wrt," "afaik," "tbqh," "nbd."
- Transparent motive statements: "Asking so I can update the doc," "just a guess, no precision
  needed." One-word invitation closers after stating a position: "Objections?" / "Thoughts?"

### Message Shapes

**Informational broadcast:**
FYI [fact or update]. [optional link] cc @person

**Technical opinion:**
[I think / yeah, I think] [position]. [reasoning in 1-2 sentences]
[optional: "Thinking out loud:" prefix for less-committed ideas]

**Request or question:**
@person [can you / could you / do you] [specific ask]? [optional context]

**Acknowledge + build:**
awesome[, / .] [follow-up thought or next action]

### Chat Examples

**Anonymized real messages:**

> This should remove ambiguity [link]. I added labels for delivery method and inactivity fees.
> We can keep adding more labels as soon as we find new clashing names

> Thinking out loud: these flows have caused quite a few headaches. I think we're at a point
> where we need to start thinking about what would be an ideal architecture, and then figure
> out how to get to that desired end state

> [link] We had a disclaimer removed from the checkout flow (probably by mistake) which broke
> compliance. [link to fix], but I'm thinking on how to prevent this from happening again in
> the future cc @maya

**Do/don't pairs:**

| DO | DON'T |
|----|-------|
| `@maya can you review the migration plan when you have a sec? No rush` | `Hi Maya! Hope you're doing well. When you get a chance, would you mind taking a look at the migration plan? Thanks so much!` |
| `Yeah, I think we should go with option B. The latency numbers are better and it looks simpler to operate` | `Great point! I completely agree. Option B is definitely the way to go -- it offers superior latency characteristics and simplified operational overhead.` |
| `FYI we merged changes to the embed controller. We don't expect any issues but surfacing it as reference "just in case" :crossed_fingers: cc @victor` | `Hey team! Just wanted to let everyone know that we've merged some exciting changes to the embed controller. Everything should be fine, but please keep an eye out for any issues!` |

## Review

After writing or editing text, spawn a subagent to review the output against this skill's
guidelines. The review must be independent: the subagent reads all the guidelines and the output
text, then flags violations. This catches issues the writing agent rationalizes away.

**How to run the review:**

1. Use the Agent tool to spawn a subagent. Copy the full contents of this skill file inline
   into the prompt so the subagent has every guideline without needing to locate any files.
   Use a prompt like:

   > You are a writing style reviewer. The text below was written for **[document | chat]**
   > output. Review it against the Shared Rules and the **[Document Style | Chat Style]**
   > section. Ignore the other style section. For each violation found, quote the offending
   > text, name the specific rule it breaks, and suggest a concrete fix. If no violations
   > are found, say "PASS."
   >
   > Pay special attention to the five moves in "Ban the Essayist Register." Flag any
   > sentence making one of those moves even when its wording matches no listed phrase;
   > the move is the violation, not the phrase. For those findings, the suggested fix
   > must be a deletion or the underlying fact stated plainly, never a reworded version
   > of the same move.
   >
   > CRITICAL: If you spot a potential violation, REPORT IT. Do not withdraw findings.
   > Do not rationalize why a violation is "actually fine" or "borderline acceptable."
   > You are a linter, not a defense attorney. False positives are cheap; missed
   > violations get published. When in doubt, flag it.
   >
   > <style-guide>
   > [paste the full skill contents here]
   > </style-guide>
   >
   > <text-to-review>
   > [paste the full output text here]
   > </text-to-review>

2. If the subagent flags violations, fix them before presenting the result to the user.
   Fix flagged rhetoric by deleting the sentence or replacing it with the underlying fact,
   never by rewording the same move. A correct fix pass makes the text shorter; if the
   word count didn't drop, the move survived in new clothes.
3. If the subagent says "PASS," proceed.

Do not skip this step. The review is mandatory.

**Rewriting a draft that arrived from outside this skill** (another model, another session,
a draft written before the skill loaded): don't edit it sentence by sentence. Extract the
facts into a skeleton (one plain fragment per fact), drop everything that fails the
sentence test in "Ban the Essayist Register," and write fresh from the skeleton. Editing
in place preserves the draft's structure, and the structure is where the performing
register lives; this is why review-and-rewrite passes on essayist drafts decay instead
of improving.

The review covers only the text the subagent saw. Wording added afterward (a fix for a
finding, a user-requested vocabulary swap, a new sentence) has not been reviewed: check it
against this guide before presenting, and re-run the subagent when the change is more than a
line or two. "Her feedback tells rather than asks" landed in a final report exactly this way
on 2026-08-24 — it was written after the review pass, so no reviewer ever saw it.
