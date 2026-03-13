---
name: tremendous-vendor-api-assessment
description: "Assess vendor APIs for integration fitness. Use when asked to evaluate a vendor's API, do a vendor assessment, review API docs, or check if a vendor's API has concerns. Also triggers for 'vendor assessment', 'API assessment', or 'take a look at their API docs'."
argument-hint: "[vendor-name] [docs-url] [--mode quick|deep] [--category prepaid-cards|crypto|monetary|merchant-cards]"
---

# Vendor API Assessment

Orchestrate a multi-level sub-agent assessment of vendor APIs and vendor capabilities for Tremendous integration.

## CRITICAL: Read-Only

**NEVER write to Slack, Asana, or Notion during assessment.** This skill only reads external sources and writes local files.

## Input Processing

The user may provide any combination of:
- Vendor name
- API docs URL
- Slack thread URL (for context on why the assessment is needed)
- Vendor category
- Assessment mode (quick or deep)
- Additional context or pasted doc content

### Step 0: Parse Input and Clarify

1. Parse whatever the user provided from the arguments.
2. If a Slack thread URL is provided, fetch it using `slack-readonly-cli message <url>` to understand the context and extract any docs URLs mentioned.
3. Use `AskUserQuestion` to clarify anything missing:

```
questions:
- question: "What type of vendor is [name]?"
  header: "Category"
  options:
  - label: "Prepaid cards"
    description: "Card issuance, lifecycle, PCI compliance (e.g. Paynetics, Galileo)"
  - label: "Crypto / Stablecoin"
    description: "Blockchain, wallets, conversions (e.g. BVNK)"
  - label: "Monetary / Transfers"
    description: "FX, bank transfers, corridors (e.g. Nium, Payoneer)"
  - label: "Merchant gift cards"
    description: "Catalog, ordering, fulfillment (e.g. Smash)"

- question: "What depth of assessment do you need?"
  header: "Mode"
  options:
  - label: "Quick (API quality check)"
    description: "Surface-level: API quality, auth, webhooks, red flags, KYB/KYC. Good for initial screening."
  - label: "Deep (full vendor assessment)"
    description: "Full requirements evaluation with category-specific domain investigation, confidence ratings, and verification layer."
```

Skip questions the user already answered in their input.

4. Attempt to access the vendor docs URL via WebFetch.
   - If docs are inaccessible (auth required, paywall, PDF-only): flag it, ask the user if they can provide content manually, continue with whatever is available.
   - **SPA detection**: If WebFetch returns mostly JavaScript, empty body, or a page that says "enable JavaScript" with minimal actual content, flag the page as "SPA-rendered, content not accessible via WebFetch." Record which pages were affected. This is a documentation quality finding (Concern) and means some findings may have lower confidence.

### Step 1: Load Configuration

Read the following config files from this skill's directory:

1. `config/shared-criteria.md` - Universal API quality criteria and severity definitions
2. `config/tremendous-domain.md` - Tremendous domain model for mismatch detection
3. The category-specific config file (e.g. `config/prepaid-cards.md`)

If the current directory is the Tremendous `core` repository (check for `Gemfile` containing "tremendous" or a `CLAUDE.md` mentioning "Ruby on Rails"), spawn a sub-agent to scan existing vendor integration patterns:

```
Scan the codebase for existing vendor integration patterns. Look in:
- app/services/ for client classes
- app/models/ for vendor-related models
- app/workers/ or app/jobs/ for webhook handlers
- lib/ for vendor libraries

Report:
1. Common client class structure (initialize, auth, error handling)
2. Webhook handler patterns
3. Error mapping conventions
4. How vendor responses are stored/processed
Be concise. Return patterns, not full code.
```

If NOT in the `core` repo, log: "Running outside the core repository, skipping codebase pattern analysis." and continue.

## Sub-Agent Rules (Apply to ALL Sub-Agents)

Every sub-agent prompt MUST include these instructions:

### Severity Calibration

Use the severity definitions from `config/shared-criteria.md` as your calibration baseline. The baseline tiers are:

- Rate limits undocumented = **Concern** (not Red Flag)
- Changelog missing = **Concern** (not Red Flag; it's a documentation gap, not a blocker)
- No error documentation at all = **Red Flag**
- Poor/inconsistent errors but they exist = **Concern**

If you believe a finding warrants a tier HIGHER than the baseline, you MUST explicitly state:
"Escalated from [baseline tier] to [actual tier] because [specific reason]."
The orchestrator will review all escalations. Do not silently deviate from the calibration.

### Confidence Indicator

Every finding MUST include a confidence level:
- **High**: Direct quote or explicit documentation found. You can link to the exact page.
- **Medium**: Inferred from related documentation, error codes, or indirect evidence.
- **Low**: Based on absence of documentation, a single indirect reference, or a page that was SPA-rendered and couldn't be fully accessed.

### Evidence Trail

For every finding, document:
1. Which URLs you WebFetched
2. What you found (quote the relevant text when possible)
3. How you arrived at the tier (your reasoning chain)
4. If a page was inaccessible or SPA-rendered, say so explicitly

This evidence trail is included in the agent's output and will be used by the verification layer.

### WebFetch SPA Detection

After every WebFetch call, check the response:
- If the body is <500 characters of actual content, or contains "enable JavaScript", "Loading...", or is mostly `<script>` tags: mark the page as **SPA-rendered / inaccessible**
- Record this in your output: "Page [URL] was SPA-rendered and returned no usable content"
- Lower your confidence on any finding that depended on this page
- The orchestrator will aggregate SPA-blocked pages as a Documentation Quality finding

### Jargon Definition

When using financial/technical terms that a non-specialist might not know (e.g. "omnibus custody", "Travel Rule", "VASP", "MCC restrictions"), include a brief parenthetical definition on first use. The assessment report is read by engineering managers, not just domain specialists.

### Batch Operations: Category-Aware Severity

Batch/bulk API support has different severity depending on the vendor category:
- **Prepaid cards**: Red Flag if missing (Tremendous has a "bulk prepaid card" product where customers order boxes with hundreds/thousands of physical cards)
- **All other categories** (crypto, monetary, merchant cards): Concern if missing, NOT Red Flag. Tremendous can decompose orders into individual API calls via async job queues. It adds latency but is workable.

Do NOT grade missing batch operations as Red Flag unless the vendor is a prepaid cards vendor.

## Quick Assessment Mode

Spawn these Level 2 sub-agents **in parallel**. Each agent receives the vendor docs URL and the Sub-Agent Rules above.

### Sub-agents to spawn (all in parallel)

**1. API Quality Agent**

```
You are assessing [Vendor]'s API quality. WebFetch their docs at [URL] and evaluate:

[Include Sub-Agent Rules here]

IDEMPOTENCY:
- Do mutation endpoints accept idempotency keys?
- What happens on duplicate requests? (Industry standard: return original response. Anti-pattern: return error.)
- If the vendor returns an error on duplicate: note that a properly-built client can handle this by catching the duplicate error and doing a GET lookup, so it's a developer experience concern, not necessarily a double-payment risk.
- RED FLAG if: No idempotency mechanism on payment/financial endpoints

PAGINATION:
- Cursor vs offset? Consistent across endpoints?
- RED FLAG if: No pagination on list endpoints

ERROR RESPONSES:
- Structured error codes (machine-readable)?
- Consistent format across endpoints? (Multiple incompatible formats = Concern)
- HTTP status codes correct?
- RED FLAG if: No error documentation at all
- CONCERN if: Poor/inconsistent errors but they exist
- Note: Most vendor API docs have poor clarity on errors. The bar is "they exist and are structured," not "they're comprehensive."

RATE LIMITS:
- Documented? Per-endpoint or global?
- Response headers for rate limit status?
- CONCERN if: Undocumented rate limits (baseline tier -- do not escalate without strong justification)

VERSIONING:
- URL vs header versioning? Deprecation policy?
- CONCERN if: No versioning strategy

For each finding, provide: Tier + Confidence (High/Medium/Low) + Evidence + Source URL + Reasoning.
Also generate questions you could not answer from the docs, tagged as Blocker/Important/Nice-to-know.
```

**2. Async Flow & Webhooks Agent**

```
You are assessing [Vendor]'s async patterns and webhook system. WebFetch their docs at [URL] and evaluate:

[Include Sub-Agent Rules here]

ASYNC FLOW RESILIENCE:
- Do POST requests return an ID for later retrieval?
- Is there a GET endpoint to poll for results (webhook fallback)?
- RED FLAG if: POST doesn't return ID or no GET fallback exists
  (Example of what bad looks like: Compliancely doesn't return IDs we can query later)

WEBHOOK SYSTEM:
- Event catalog: what events are available? How complete?
- Retry policy: documented? How many retries? Backoff strategy?
- Signature verification: HMAC or other mechanism?
  NOTE: If HMAC/signature verification exists, that is sufficient for security. Do NOT generate questions about "webhook source IP lists for firewall rules" -- Tremendous does not whitelist vendor IPs; signature verification is the security mechanism.
- Delivery guarantees: at-least-once, exactly-once?
- CONCERN if: No retry policy or signature verification documented

For each finding, provide: Tier + Confidence (High/Medium/Low) + Evidence + Source URL + Reasoning.
Generate unanswered questions tagged as Blocker/Important/Nice-to-know.
```

**3. Auth & Security Agent**

```
You are assessing [Vendor]'s authentication and security model. WebFetch their docs at [URL] and evaluate:

[Include Sub-Agent Rules here]

- Auth mechanism: API key vs OAuth vs HMAC vs other?
- Token rotation: Is there a mechanism to rotate credentials?
- IP allowlisting: Supported?
- Environment separation: Separate sandbox vs production keys/endpoints?
- Permissions/scoping: Can API keys be scoped to specific operations?

For each finding, provide: Tier + Confidence (High/Medium/Low) + Evidence + Source URL + Reasoning.
Generate unanswered questions tagged as Blocker/Important/Nice-to-know.
```

**4. Documentation Quality Agent**

```
You are assessing [Vendor]'s API documentation quality. WebFetch their docs at [URL] and evaluate:

[Include Sub-Agent Rules here]

- Endpoint coverage: Are all endpoints documented?
- Code samples: Available? Multiple languages?
- OpenAPI/Swagger spec: Available for download?
- Up-to-date: Any stale references, broken links, outdated examples?
- Changelog: Published? How often updated?
  NOTE: A missing changelog is a CONCERN (documentation gap), not a Red Flag. It does not block integration.
- Getting started guide: Clear onboarding path?
- SPA rendering: Did any doc pages fail to return content via WebFetch? List all affected pages.

For each finding, provide: Tier + Confidence (High/Medium/Low) + Evidence + Source URL + Reasoning.
Generate unanswered questions tagged as Blocker/Important/Nice-to-know.
```

**5. KYB/KYC & Compliance Agent**

```
You are assessing [Vendor]'s KYB/KYC and compliance capabilities. WebFetch their docs at [URL] and evaluate:

[Include Sub-Agent Rules here]

- Onboarding flow: Programmatic or manual?
- KYB (Know Your Business): What's required? Documents, verification steps?
- KYC (Know Your Customer): Per-customer or per-organization?
- Compliance certifications mentioned: SOC2, PCI-DSS, etc.
- AML/sanctions screening capabilities?
- Regulatory reporting: Who files SARs/STRs? Note that reporting obligations differ by jurisdiction (US FinCEN vs EU MiCA vs UK FCA). Flag if unclear, but note the jurisdictional context.
- RED FLAG if: Manual-only onboarding with no API

For each finding, provide: Tier + Confidence (High/Medium/Low) + Evidence + Source URL + Reasoning.
Generate unanswered questions tagged as Blocker/Important/Nice-to-know.
```

**6. Sandbox & Testing Agent**

```
You are assessing [Vendor]'s sandbox and testing environment. WebFetch their docs at [URL] and evaluate:

[Include Sub-Agent Rules here]

- Sandbox availability: Does one exist?
- Parity with production: Same endpoints, same behavior?
- Test data: Can test data be generated programmatically?
- Ease of setup: Self-service or requires vendor interaction?
- RED FLAG if: No sandbox environment at all

For each finding, provide: Tier + Confidence (High/Medium/Low) + Evidence + Source URL + Reasoning.
Generate unanswered questions tagged as Blocker/Important/Nice-to-know.
```

**7. Red Flags Agent**

```
You are scanning [Vendor]'s API docs for deal-breaker patterns. WebFetch their docs at [URL] and look for:

[Include Sub-Agent Rules here]

- No sandbox environment
- No idempotency on financial endpoints
- No API versioning
- Manual-only onboarding (no programmatic KYB/KYC)
- POST endpoints that don't return IDs for async operations
- No webhook retry mechanism
- Co-mingled funds across customers (meaning all customers' funds are pooled in one account with only virtual segregation -- explain this term if flagged)
- No batch/bulk operations (ONLY Red Flag for prepaid card vendors; Concern for all others)
- Vendor requires 1:1 beneficiary-per-customer mapping
- No programmatic fund movement
- Unclear or absent error handling

For each potential red flag found, provide:
- What you found
- Why it's a concern for integration
- Source URL
- Confidence level (High / Medium / Low)
- Whether you escalated from a lower baseline tier (and why)

Also flag anything else that seems unusual or concerning even if not in the list above.
```

### Step 2: Aggregation Gate (Cross-Reference Before Proceeding)

After all sub-agents return, the orchestrator MUST perform a cross-reference review before moving to Step 3 or Step 4. This is a synchronization gate to catch contradictions and inconsistencies between agents working in isolation.

1. **Collect all findings** from all agents into a single working set
2. **Check for contradictions between agents**:
   - Does one agent say feature X exists while another says it doesn't?
   - Does one agent grade something as Adequate while another graded the same thing as Red Flag?
   - Did one agent's findings answer another agent's questions?
3. **Check for severity escalations**: Review all findings where an agent escalated above the shared-criteria baseline. Accept, reject, or note each escalation with reasoning.
4. **Resolve contradictions**: If agents disagree, the evidence with higher confidence wins. If confidence is equal, flag as "Disputed -- needs verification."
5. **Merge findings**: Produce a consolidated findings list with resolved contradictions.
6. **Cross-reference questions against findings**: Before the question self-answering phase, check each generated question against the consolidated findings. If another agent already answered it, remove it. If partially answered, refine the question to focus on the remaining gap.

Only after this gate is complete, proceed to Step 3 (Deep Assessment) or Step 4 (Question Self-Answering).

## Deep Assessment Mode

Run everything from Quick Assessment mode PLUS the following.

### Category-Specific Domain Investigation

Read the category config file (e.g. `config/prepaid-cards.md`) which defines:
- The Level 2 domain agents to spawn
- Base requirements per domain
- Category-specific red flags

Spawn all category-defined Level 2 domain agents **in parallel**. Each agent:
1. Receives the vendor docs URL, its domain scope, base requirements, and the Sub-Agent Rules
2. WebFetches relevant doc pages for its domain
3. Spawns Level 3 sub-domain agents when the domain has distinct sub-areas (defined in the category config)
4. Evaluates each base requirement using the 4-tier severity scale
5. Discovers and evaluates additional requirements found in the docs
6. Generates domain-specific questions

Each Level 2 agent prompt should follow this template:

```
You are investigating [Vendor]'s [Domain Area] capabilities. WebFetch their docs at [URL],
specifically pages related to [domain keywords].

[Include Sub-Agent Rules here]

BASE REQUIREMENTS TO EVALUATE:
[list from category config]

For each requirement, provide a row with:
- Requirement name
- Status: Supported / Partial / Unclear / Not Found
- Tier: Red Flag / Concern / Adequate / Strong
- Confidence: High / Medium / Low
- Evidence: What the docs say (quote when possible)
- Source URL (REQUIRED -- if no URL, mark as "Not found in docs")

ADDITIONAL REQUIREMENTS:
If you discover capabilities or concerns not in the base requirements list, add them using the same format.

SUB-DOMAINS TO INVESTIGATE:
[If the category config defines sub-domains for this domain, spawn a sub-agent for each one.
Example for Card Issuance: spawn one agent for Virtual Cards and another for Physical Cards.
Each sub-agent should WebFetch relevant pages and return findings in the same format.]

Generate questions for anything you could not determine from the docs.
Tag each as Blocker/Important/Nice-to-know with the domain name.

EVIDENCE TRAIL:
At the end of your output, include a section listing:
- All URLs you WebFetched
- Which returned usable content vs SPA-rendered/empty
- Key quotes that support your findings
```

### Tremendous Domain Model Check

After domain investigation completes, spawn an agent to check for model mismatches:

```
Read the file at [path to config/tremendous-domain.md].

Given these findings about [Vendor]:
[summary of key findings from domain agents]

Check for mismatches between [Vendor]'s model and Tremendous's model:
- Does the vendor require 1:1 beneficiary-per-customer? (We have multi-recipient orders)
- Does the vendor support batch operations? (We process orders with many rewards)
  NOTE: Missing batch operations is only a Red Flag for prepaid card vendors. For other categories, it's a Concern with a known workaround (async job queue decomposition).
- Is KYC per-recipient or per-organization? (We do KYC at the organization level)
- Are funds co-mingled across customers? (We need clear fund separation)
  Define "co-mingled/omnibus" for the reader: all customers' assets pooled in a single account, separated only by internal ledger entries rather than separate accounts.
- Any other structural mismatches?

For each mismatch found, explain:
- What Tremendous expects
- What the vendor provides
- Severity (Red Flag / Concern) -- with category-aware context
- Possible workaround if any
```

### Codebase Integration Fitness (if in core repo)

If codebase patterns were scanned in Step 1, spawn an agent:

```
Given these vendor API patterns:
[summary of auth, error format, webhook format from findings]

And these Tremendous codebase patterns:
[patterns from Step 1 codebase scan]

Evaluate integration fitness:
- Does the vendor's auth model map to our client class pattern?
- Can their errors map to our error handling conventions?
- Do their webhooks fit our webhook handler pattern?
- Any structural incompatibilities?
```

### Verification Layer

After ALL investigation agents complete (including category-specific deep agents):

**IMPORTANT: Verify ALL findings, not just Red Flags and Concerns.** Adequate and Strong findings can also be hallucinated. The verification layer must cover everything.

1. **Group findings by source** to minimize redundant WebFetch calls. Findings from the same URL can be verified together.

2. **Spawn verification agents** -- one per logical group (batch by URL or domain area, not one per individual finding):

```
VERIFICATION TASK:
You are verifying findings from the [Vendor] API assessment. Your job is to independently
confirm or contradict each finding by re-reading the source material.

FINDINGS TO VERIFY:
[List of findings with their original tier, confidence, evidence, and source URL]

CROSS-REFERENCE DATA:
[List of potentially related findings from OTHER agents that could contradict or support these]

For each finding:
1. WebFetch the source URL. Did you get usable content or was it SPA-rendered?
2. Read the content. Does it support the original finding?
3. Search the vendor's docs more broadly -- is there contradicting information elsewhere?
4. Check cross-reference data for contradictions between agents.

Return a structured table:
| Finding | Original Tier | Verified? | Confidence | Evidence | Contradictions | Updated Tier |
|---------|--------------|-----------|------------|----------|----------------|-------------|

For each row:
- Verified: Confirmed / Contradicted / Partially Confirmed / Could Not Verify (page inaccessible)
- Include the source URL where you found confirming or contradicting evidence
- If you found a contradiction, explain both claims with their sources
- If a tier should change based on your verification, state the new tier and why
```

3. **Cross-reference between agents after verification**. Specifically check:
   - Webhook agent says event X exists, but lifecycle agent found no way to trigger it
   - Auth agent says sandbox exists, but sandbox agent couldn't confirm
   - API quality agent says pagination exists, but domain agents found endpoints without it
   - One agent listed specific capabilities (e.g. supported chains) that another agent's questions ask about

## Step 4: Question Self-Answering

Before finalizing the "Questions for Vendor" document:

1. **Pre-filter against consolidated findings**: Cross-reference every generated question against ALL findings from ALL agents (including category-specific deep agents). If an agent already documented the answer, remove the question entirely. If partially answered, refine the question to focus only on the remaining gap. This step happens BEFORE spawning any self-answering agents.

2. **Deduplicate** remaining questions (same question from multiple agents).

3. For each remaining unique question, spawn a sub-agent:

```
QUESTION: [the question]
VENDOR: [vendor name]
DOCS URL: [primary docs URL]

Search the vendor's website and documentation thoroughly for an answer:
1. WebFetch the main docs URL and search for relevant keywords
2. Look for FAQ pages, knowledge bases, changelogs, blog posts
3. Check developer guides, API reference, and getting started pages
4. Try the vendor's help center, support docs, and marketing pages

If you find an answer:
- Return: ANSWERED
- The answer with a direct quote when possible
- Source URL where you found it

If you find a partial answer:
- Return: PARTIALLY ANSWERED
- What you found + source URL
- A refined version of the question focusing on what's still unclear

If you cannot find an answer:
- Return: UNANSWERED
- Where you looked (list URLs checked)
- The original question as-is

EVIDENCE: List every URL you checked, whether it had useful content, and what you found.
```

4. Remove answered questions from the vendor questions list
5. Refine partially answered questions
6. Keep unanswered questions for the vendor document

## Step 5: Generate Output

### Assessment Report

Save to a local markdown file. Ask the user where, suggesting `./ai-notes/vendor-assessments/[vendor]-assessment.md` if the `ai-notes` directory exists, otherwise `./[vendor]-assessment.md`.

#### Report Writing Rules

- **Define jargon on first use.** Terms like "omnibus custody," "Travel Rule," "VASP," "MCC restrictions," "co-mingled funds" should have a brief parenthetical explanation. The audience is engineering managers, not domain specialists.
- **Distinguish findings from open questions.** If something is undocumented, it may be a concern (they should have it and don't) or an open question (it's simply not public information). Rate limits being undocumented is an open question, not necessarily a red flag.
- **Show escalation reasoning.** If any finding was escalated above the shared-criteria baseline, note it: "Escalated from Concern to Red Flag because [reason]."

#### Quick Mode Report Structure

```markdown
# [Vendor Name] - Quick API Assessment
**Date**: [today's date]
**Category**: [detected/specified category]
**Mode**: Quick Assessment
**Docs Reviewed**: [URLs]
**SPA-Blocked Pages**: [list any pages that were inaccessible due to SPA rendering]

## Executive Summary
[2-3 sentences. Confidence-weighted summary highlighting strengths, concerns, and blockers.]

## Severity Summary
| Tier | Count | Key Items |
|------|-------|-----------|
| Red Flag | N | [brief list] |
| Concern | N | [brief list] |
| Open Question | N | [things that are simply not public/documented -- not necessarily concerns] |
| Adequate | N | - |
| Strong | N | [brief list] |

## API Quality
### Idempotency [Tier] [Confidence]
[Finding + evidence + source URL + reasoning]

### Pagination [Tier] [Confidence]
...

### Error Responses [Tier] [Confidence]
...

### Rate Limits [Tier] [Confidence]
...

### Versioning [Tier] [Confidence]
...

## Async Flow & Webhooks
### Async Resilience [Tier] [Confidence]
...

### Webhook System [Tier] [Confidence]
...

## Auth & Security [Tier] [Confidence]
...

## Documentation Quality [Tier] [Confidence]
...

## KYB/KYC & Compliance [Tier] [Confidence]
...

## Sandbox & Testing [Tier] [Confidence]
...

## Red Flags
[List of deal-breaker patterns found, if any]

## Open Questions
[Things that are simply not public information -- distinct from concerns about missing features.
Examples: rate limits not documented (could be fine, we just don't know), pricing not public, etc.]
```

#### Deep Mode Report Structure

Everything from Quick mode, PLUS:

```markdown
## [Category-Specific Section]
### [Domain Area]
| Requirement | Status | Tier | Confidence | Evidence | Source |
|-------------|--------|------|------------|----------|--------|
| [req 1] | Supported | Strong | High | [evidence quote] | [URL] |
| [req 2] | Partial | Concern | Medium | [evidence] | [URL] |
...

#### [Sub-Domain] (if applicable)
[Detailed findings from Level 3 agents]

## Domain Model Compatibility
[Mismatch findings from Tremendous domain check]

## Integration Fitness [Only if in core repo]
[How vendor patterns map to Tremendous integration patterns]

## Verification Results

Summary: [N] findings verified. [M] contradictions found. [K] tiers updated.

[If all findings confirmed:]
All [N] findings verified against source documentation. No contradictions found between agents.

[If any contradictions or tier changes:]
| Finding | Original Tier | Verification | Updated Tier | Notes |
|---------|--------------|-------------|-------------|-------|
| [only include rows where verification changed something or found a contradiction] |

## Evidence Appendix
### Pages Successfully Accessed
[List of URLs that returned usable content]

### Pages Blocked (SPA/Auth)
[List of URLs that were inaccessible and what impact this had on findings]
```

### Questions for the Vendor (Separate Document)

Save alongside the report as `[vendor]-questions.md`.

```markdown
# Questions for [Vendor Name]
**Generated**: [today's date]
**Assessment Mode**: Quick / Deep
**Context**: [1-2 sentence description of what Tremendous wants to do with this vendor]

---

## Blockers (Must Answer Before Proceeding)
### [Domain Group]
1. [Question]
   _Context: [Why this matters / what we partially found]_

## Important (Affects Architecture Decisions)
### [Domain Group]
1. [Question]
   _Context: [...]_

## Nice to Know (Improves Understanding)
### [Domain Group]
1. [Question]
   _Context: [...]_

---
_[N] questions were answered from public documentation and removed from this list._
_See the assessment report ([vendor]-assessment.md) for those findings._
```

### Step 6: Offer Notion Upload

After the user reviews the local files:

```
The assessment is saved locally. Would you like me to create a Notion page for it?
I can create it in the same workspace where the other vendor assessments live.
```

If yes, use `mcp__notion__notion-create-pages` to create the page with the report content.

## Rules

- **Sub-agent architecture is mandatory.** Never load large doc content into the orchestrator's context. Each investigation happens in its own agent.
- **Use Opus model** for all sub-agents when available (`model: "opus"`). Assessment accuracy is critical.
- **Every finding must include a source URL and confidence level.** If no source URL exists, mark as "Not found in docs" and set confidence to Low.
- **Read-only.** Never write to Slack, Asana, or external services.
- **Parallel execution.** Spawn independent agents in parallel wherever possible to reduce total time.
- **Graceful degradation.** If a docs page is inaccessible, flag it and continue with what's available. Never halt the entire assessment because one page failed.
- **No hallucinated URLs.** If you cannot access a page, say so. Never fabricate content or URLs.
- **SPA detection is mandatory.** Every sub-agent must check WebFetch responses for SPA-rendering indicators and report inaccessible pages.
- **Verify ALL findings.** The verification layer covers every tier (Red Flag, Concern, Adequate, Strong), not just critical findings. Adequate and Strong findings can also be hallucinated.
- **Aggregation gate is mandatory.** After the parallel investigation phase, the orchestrator must cross-reference and reconcile before proceeding to verification or question generation.
- **Category-aware severity.** Batch operations are only Red Flag for prepaid cards. Webhook IP whitelisting is never a question worth asking if HMAC signing exists.

## Adding New Categories

Create a new `.md` file in `config/` following the format of existing category files. The file must define:
1. Category metadata (name, display name, keywords for detection)
2. Level 2 domain agents to spawn (with their scope and prompts)
3. Level 3 sub-domain agents per domain (if applicable)
4. Base requirements per domain
5. Category-specific red flags
6. Category-specific questions template (always-investigate questions)

After creating a new category file, verify it works by running a quick assessment against a known vendor in that category.
