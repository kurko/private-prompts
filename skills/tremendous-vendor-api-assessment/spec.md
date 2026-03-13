# Vendor API Assessment Skill - Specification

## Overview & Goals

A Claude Code skill that orchestrates a multi-level sub-agent assessment of vendor APIs and vendor capabilities. The skill evaluates vendors across API quality, domain-specific functionality, compliance, and integration fitness for Tremendous's platform.

### Primary Goals

1. **Reduce manual research time** - Automate the bulk of vendor API documentation review
2. **Consistent evaluation criteria** - Standardized assessment across vendor categories with a 4-tier severity scale
3. **Avoid embarrassment** - Self-answer questions from vendor docs before surfacing them as "questions for vendor"
4. **Catch red flags early** - Surface integration blockers before engineering time is invested
5. **Support multiple audiences** - Engineering, compliance, and business stakeholders all read these

### Non-Goals

- Replace human judgment on Go/No-Go decisions (outputs a confidence-weighted summary, not a verdict)
- Perform security audits or penetration testing
- Generate integration code

---

## Two Assessment Modes

### Mode 1: Quick Assessment (Preliminary)

**When to use**: Initial API quality check, e.g., "could you take a look at their API docs to see if you have any concerns?"

**Scope**: API quality signals only. No domain-specific deep dive.

**Areas evaluated**:
- API quality (idempotency, pagination, error responses, async patterns)
- Webhooks & event model
- Auth & security model
- Documentation quality
- KYB/KYC capabilities
- Sandbox/testing environment
- Red flags / deal breakers

**Output**: A single markdown report with graded findings + a "Questions for the Vendor" document.

**Sub-agent depth**: 2 levels (orchestrator + domain investigators). No sub-domain agents.

### Mode 2: Deep Assessment (Full)

**When to use**: Vendor has passed preliminary screening. Need full requirements evaluation before committing to integration.

**Scope**: Everything in Quick mode + category-specific domain deep dive with requirements table.

**Additional areas**: Category-defined agent tree (see below), static base requirements + dynamic extras, Tremendous domain model mismatch detection.

**Output**: Full structured report with confidence ratings per requirement + "Questions for the Vendor" document.

**Sub-agent depth**: 3 levels (orchestrator + domain investigators + sub-domain investigators) + verification layer.

---

## Input & Category Detection (Hybrid)

### Accepted Inputs

The skill accepts any combination of:
- **Vendor name** (required - will ask if not provided)
- **API docs URL** (strongly recommended)
- **Slack thread URL** (optional - for context on why the assessment is needed)
- **Vendor category** (optional - will infer or ask)
- **Additional context** (optional - user can paste doc content, PDFs, etc.)
- **Assessment mode** (optional - quick or deep, will ask if not provided)

### Input Processing Flow

1. Parse whatever the user provided
2. If a Slack thread URL is provided, fetch it for context (using `slack-readonly-cli`)
3. Optionally use `AskUserQuestion` to clarify:
   - Vendor category (if not obvious from docs)
   - Assessment mode (quick vs deep)
   - Any specific concerns to prioritize
   - Additional doc URLs or content
4. Attempt to access vendor docs URL via WebFetch
5. If docs are inaccessible (auth required, paywall, PDF-only):
   - Flag it as a finding
   - Ask the user if they can provide the content manually
   - Continue with whatever is available

### Vendor Categories (Extensible)

Initial categories:
- **Prepaid Cards** (e.g., Paynetics) - Card issuance, lifecycle, PCI compliance, SDKs
- **Monetary / Transfers** (e.g., Nium, Payoneer) - FX, corridors, settlement, beneficiary management
- **Crypto / Stablecoin** (e.g., BVNK) - Blockchain networks, wallet management, conversions
- **Merchant Gift Cards** (e.g., Smash) - Catalog, ordering, fulfillment, reconciliation

New categories are added by creating a new file in the `config/` directory (see File Structure below).

---

## Sub-Agent Architecture

### Fractal Design Principle

Each slice of work is processed by a single agent with its own context window. Agents spawn child agents for sub-domains. This prevents context overflow and hallucination.

### Level 1: Orchestrator (the skill itself)

Responsibilities:
- Parse input, detect category
- Spawn Level 2 domain investigators (in parallel where possible)
- **Aggregation gate**: Cross-reference all findings before proceeding. Catch contradictions, review severity escalations, pre-filter questions against findings.
- Spawn verification agents to cross-check ALL findings (not just Red Flags/Concerns)
- Generate the final report and questions document
- Offer to push to Notion

### Level 2: Domain Investigators

**Universal investigators** (both modes):
- **API Quality Agent** - Idempotency, pagination, error responses, versioning, rate limits
- **Async Flow Agent** - POST-returns-ID, GET fallback, webhook retry policy, signature verification, event catalog, delivery guarantees
- **Auth & Security Agent** - Auth mechanism, token rotation, IP allowlisting, environment separation
- **Documentation Quality Agent** - Completeness, accuracy, code samples, OpenAPI spec availability
- **KYB/KYC Agent** - Onboarding flow, verification requirements, compliance capabilities
- **Red Flags Agent** - Deal breaker patterns (no sandbox, no idempotency, no versioning, manual-only onboarding, no async ID return like Compliancely)

**Category-specific investigators** (deep mode only):
- Defined in category config files (see below)
- Example for Prepaid Cards: Account Management Agent, Card Issuance Agent, Card Lifecycle Agent, Funding Agent, Authorization & Ledger Agent, Compliance/PCI Agent

### Level 3: Sub-Domain Investigators (deep mode only)

Spawned by Level 2 agents when a domain has distinct sub-areas.

Example for Card Issuance Agent:
- Virtual Cards Sub-Agent
- Physical Cards Sub-Agent (shipping, activation, replacement)

Example for Monetary/Transfers:
- Domestic Transfers Sub-Agent
- International Transfers Sub-Agent
- FX & Conversion Sub-Agent

### Verification Layer

After all investigators complete:
1. **Verify ALL findings across ALL tiers** (Red Flag, Concern, Adequate, Strong). Adequate and Strong findings can also be hallucinated.
2. Group findings by source URL to minimize redundant WebFetch calls.
3. Spawn verification agents (one per URL group or domain area):
   - Re-read the relevant vendor documentation
   - Confirm or contradict the original finding
   - Provide source URLs for every claim
   - Flag contradictions between different domain agents
   - Output a structured verification table, not prose summaries
4. Cross-reference findings between agents (e.g., if Webhook Agent says event X exists but Lifecycle Agent found no way to trigger it)
5. Every sub-agent must document its evidence trail: which URLs it fetched, what it found, how it reached its conclusion

---

## Severity Grading Scale

All findings use a 4-tier scale plus an "Open Question" category:

| Tier | Label | Meaning | Example |
|------|-------|---------|---------|
| 1 | **Red Flag** | Potential blocker for integration | No idempotency on payment endpoints; no GET fallback for async operations; POST doesn't return an ID |
| 2 | **Concern** | Problem but workable; affects architecture | Poor error messages but errors exist; multiple incompatible error formats |
| - | **Open Question** | Information not publicly available; not necessarily a problem | Rate limits not documented; pricing not public; changelog absent |
| 3 | **Adequate** | Meets minimum expectations | Standard pagination; basic error codes; sandbox available but limited |
| 4 | **Strong** | Above average; reduces integration risk | Comprehensive OpenAPI spec; detailed error taxonomy; robust webhook with HMAC + retries |

Each finding includes: **Tier + Confidence (High/Medium/Low) + Signal Name + Evidence + Source URL (when available)**

### Key Distinctions
- **Concern vs Open Question**: A concern is a known problem. An open question is missing information that might be fine once we ask. Don't conflate "not documented" with "bad."
- **Category-aware severity**: Batch operations are only Red Flag for prepaid cards. For all other categories, it's a Concern.
- **Severity escalation**: Sub-agents must use baseline tiers from shared-criteria.md. Escalations above baseline require explicit justification.

---

## Universal API Quality Criteria

These are evaluated in BOTH modes:

### Idempotency
- Do mutation endpoints accept idempotency keys?
- What happens on duplicate requests?
- **Red Flag if**: No idempotency mechanism on payment/financial endpoints

### Pagination
- Cursor vs offset pagination?
- Consistent across endpoints?
- Large dataset handling?
- **Concern if**: Inconsistent pagination or offset-only on large collections

### Error Responses
- Structured error codes (machine-readable)?
- Consistency of error format across endpoints?
- HTTP status code correctness?
- **Red Flag if**: No error documentation at all
- **Concern if**: Poor/inconsistent error messages but errors are present

### Async Flow Resilience
- POST requests return an ID for later retrieval?
- GET endpoint exists to poll for results (webhook fallback)?
- Webhook retry policy documented?
- Signature/HMAC verification for webhooks?
- Event catalog completeness?
- Delivery guarantees (at-least-once, exactly-once)?
- **Red Flag if**: POST doesn't return ID; no GET fallback for async operations

### Rate Limits
- Documented on the website?
- Per-endpoint or global?
- Response headers for rate limit status?
- **Concern if**: Undocumented rate limits

### Sandbox / Testing Environment
- Available?
- Parity with production?
- Test data generation?
- Ease of setup?
- **Red Flag if**: No sandbox environment at all

### Versioning
- URL vs header versioning?
- Deprecation policy?
- Breaking change communication?
- **Concern if**: No versioning strategy documented

### Auth & Security
- API key vs OAuth vs HMAC?
- Token rotation mechanism?
- IP allowlisting?
- Environment separation (sandbox vs production keys)?

### Documentation Quality
- Complete endpoint coverage?
- Code samples in multiple languages?
- OpenAPI/Swagger spec available?
- Up-to-date (check for stale references)?
- **Concern if**: Major gaps in documentation

### KYB / KYC
- Onboarding flow documented?
- Verification requirements clear?
- Programmatic vs manual onboarding?
- **Concern if**: Manual-only onboarding process

---

## Question Generation & Self-Answering Flow

### Generation Phase

Each domain investigator generates questions as it works:
- Questions arise when documentation is unclear, missing, or contradictory
- Each question is tagged with:
  - **Domain** (e.g., "Card Lifecycle", "Webhooks", "Auth")
  - **Priority**: Blocker (must answer before proceeding) / Important (affects architecture) / Nice-to-know (improves understanding)

### Self-Answering Phase

Before including a question in the final "Questions for Vendor" document:
1. Spawn one sub-agent per question
2. Each sub-agent:
   - Searches the vendor's website/docs specifically for the answer
   - Checks related pages, FAQs, knowledge bases, changelogs
   - If an answer is found: include the answer + source URL in the report, remove from questions list
   - If partially answered: include what was found + source URL, keep a refined version of the question
   - If not found: keep the question for the vendor
3. Verification sub-agents confirm source URLs are real and content matches claims

### Output: Questions for the Vendor Document

Separate document with:
- Questions grouped by domain
- Each question tagged with priority (Blocker / Important / Nice-to-know)
- Any partial findings noted ("We found X on your docs page [URL], but need clarification on Y")
- Only questions that could NOT be answered from public documentation

---

## Codebase Awareness (Conditional)

### When in the `core` Repository

If the skill detects it's running inside the Tremendous `core` repository:
1. Spawn a sub-agent to scan existing vendor integration patterns:
   - Client class structure (`app/services/` or `lib/`)
   - Webhook handler patterns
   - Error mapping conventions
   - Testing patterns for vendor integrations
2. Use these patterns to generate more relevant assessment questions (e.g., "Does the vendor's error format map cleanly to our `VendorError` class?")
3. Include a "Integration Fitness" section in the report

### When Outside `core`

- Log a note: "Running outside the core repository - skipping codebase pattern analysis"
- Continue with a generic assessment (no integration fitness section)

---

## Tremendous Domain Model Context

Embedded in the skill so agents can flag vendor model mismatches:

**Key concepts**:
- **Organization**: A company that uses Tremendous to send rewards/payments
- **Member**: A user within an organization
- **Order**: A batch of rewards/payments created by an organization
- **Reward**: A single payment/gift within an order
- **Recipient**: The person receiving a reward
- **Funding Source**: How the organization pays (bank account, credit card, balance)
- **Campaign**: A template for how rewards are delivered
- **Product / Catalog Item**: What can be sent (gift card, prepaid card, bank transfer, etc.)

**Common mismatch patterns to flag**:
- Vendor requires 1:1 beneficiary-per-customer (conflict with our multi-recipient model)
- Vendor doesn't support batch operations (we process orders with many rewards)
- Vendor's KYC is per-recipient (we do KYC at the organization level)
- Vendor co-mingles funds across customers (we need clear fund separation)

---

## Output Format & Report Structure

### Assessment Report (Markdown)

```markdown
# [Vendor Name] - [Quick/Deep] API Assessment
**Date**: YYYY-MM-DD
**Category**: [Detected/specified category]
**Mode**: Quick Assessment / Deep Assessment
**Docs Reviewed**: [URLs]

## Executive Summary
[2-3 sentence overview of findings. Confidence-weighted: highlights strengths,
concerns, and blockers with severity counts.]

## Severity Summary
| Tier | Count | Key Items |
|------|-------|-----------|
| Red Flag | N | [brief list] |
| Concern | N | [brief list] |
| Adequate | N | - |
| Strong | N | [brief list] |

## API Quality Assessment
### Idempotency [Tier]
[Finding + evidence + source URL]

### Pagination [Tier]
[Finding + evidence + source URL]

[... all universal criteria ...]

## [Category-Specific Section - Deep Mode Only]
### [Domain Area]
#### [Sub-Domain]
[Requirements table with confidence ratings - like Paynetics format]

## Integration Fitness [Only if in core repo]
[How well vendor patterns map to Tremendous's integration patterns]

## Domain Model Compatibility
[Mismatch flags based on Tremendous domain concepts]

## Open Questions
[Questions that couldn't be answered and aren't in the vendor questions doc]
```

### Questions for the Vendor (Separate Markdown)

```markdown
# Questions for [Vendor Name]
**Generated**: YYYY-MM-DD
**Assessment Mode**: Quick / Deep

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
```

### Output Delivery

1. Save both documents locally as markdown drafts
2. Present to user for review
3. Offer to create/update a Notion page in the existing vendor assessment pattern

---

## File Structure

```
~/.private-prompts/skills/tremendous-vendor-api-assessment/
├── SKILL.md                          # Main skill file (orchestrator instructions)
├── spec.md                           # This specification
└── config/
    ├── shared-criteria.md            # Universal API quality criteria & severity definitions
    ├── tremendous-domain.md          # Tremendous domain model context for mismatch detection
    ├── prepaid-cards.md              # Category: agent tree, base requirements, red flags
    ├── crypto-stablecoin.md          # Category: agent tree, base requirements, red flags
    ├── monetary-transfers.md         # Category: agent tree, base requirements, red flags
    └── merchant-gift-cards.md        # Category: agent tree, base requirements, red flags
```

### Adding a New Category

Create a new `.md` file in `config/` with:
```markdown
---
category: [category-name]
display_name: [Human Readable Name]
---

## Domain Agent Tree
[List of Level 2 domain investigators to spawn]
[For each: list of Level 3 sub-domain investigators]

## Base Requirements
[Static requirements to evaluate, each with expected severity tier if not met]

## Category-Specific Red Flags
[Patterns that are deal breakers for this category]

## Key Questions Template
[Domain-specific questions that should always be investigated]
```

---

## Edge Cases & Error Handling

### Inaccessible Documentation
- Try WebFetch first
- If blocked (auth, paywall, PDF): flag as a finding, ask user for manual input, continue with what's available
- If vendor has multiple doc sites: investigate all of them

### Vendor With No Public Docs
- Flag as a Red Flag
- Generate questions based on category template
- Note that all findings are "Unable to assess - documentation not publicly available"

### Cross-Agent Contradictions
- Verification layer explicitly checks for contradictions between domain agents
- Surface contradictions prominently in the report with both claims + sources

### Very Large API Surface
- If a vendor has 100+ endpoints, the domain investigators should prioritize endpoints relevant to Tremendous's use case
- Use the category config's base requirements to focus investigation

---

## Open Questions

_None remaining - all questions resolved during spec interview._

---

## Out of Scope

- **Pricing evaluation** - Business/finance concern, not engineering
- **Legal/contract review** - Legal team's responsibility
- **Performance benchmarking** - Would require actual API access and load testing
- **Security penetration testing** - Requires authorization and specialized tools
- **Integration implementation** - This skill assesses; implementation is a separate effort
- **Vendor comparison** - Each assessment is standalone; comparing vendors is a human decision
