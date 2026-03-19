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
   - **SPA detection**: If WebFetch returns mostly JavaScript, empty body, or a page that says "enable JavaScript" with minimal actual content, attempt the Rendering Fallback Chain (see "WebFetch SPA Detection and Rendering Fallback" in Sub-Agent Rules). Record which rendering method succeeded. If all methods fail, flag as inaccessible and ask the user if they can provide content manually.

### Step 0.5: Sitemap and Page Discovery

Before spawning domain investigators, spawn a **Sitemap Discovery Agent** to build a page inventory. This is a blocking step — all sub-agents need the inventory before starting.

```
You are discovering available documentation pages for [Vendor]. Your goal is to build a comprehensive
inventory of doc pages so that investigation agents know WHERE to look.

RENDERING NOTE: [Include if SPA was detected: "[domain] is SPA-rendered. Use [method] for all URLs."]

1. Fetch the main docs page (via rendering service if SPA) and extract ALL internal links from the content.
2. Check common sitemap locations:
   - [docs-url]/sitemap.xml
   - [docs-url]/docs/sitemap.xml
   - [base-domain]/sitemap.xml
   - [base-domain]/robots.txt (look for Sitemap: directives)
3. Check for OpenAPI/Swagger spec at common paths:
   - [docs-url]/openapi.json, /openapi.yaml, /swagger.json
   - [base-domain]/api/openapi.json, /api/swagger.json
   - [base-domain]/.well-known/openapi.json
4. Check developer subdomains:
   - developer.[vendor-domain], api.[vendor-domain], docs.[vendor-domain]
5. From the links discovered in steps 1-4, identify the top 5-10 most promising secondary pages
   (API reference, guides, webhooks, authentication, changelog) and fetch them to discover deeper links.

OUTPUT a categorized page inventory:
- **API Reference pages**: [URLs]
- **Authentication / Security pages**: [URLs]
- **Webhook / Event pages**: [URLs]
- **Guide / Tutorial pages**: [URLs]
- **Changelog / Versioning pages**: [URLs]
- **Compliance / KYC / KYB pages**: [URLs]
- **Sandbox / Testing pages**: [URLs]
- **OpenAPI/Swagger spec**: [URL if found]
- **Other relevant pages**: [URLs]

For each URL, note:
- Content Quality Grade (Direct / Rendered / Inaccessible)
- Brief description of what the page covers (1 line)
```

The resulting `PAGE INVENTORY` is passed to ALL sub-agents in their prompts so they know where to look. Include it in each sub-agent prompt as:

```
PAGE INVENTORY (discovered pages for this vendor — check these for your domain):
[paste categorized inventory here]
```

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

Every finding MUST include a confidence level, tied to the Content Quality Grade of the source page:
- **High**: Direct quote or explicit documentation found from a **Direct** or **Browser-Extracted** source. You can link to the exact page.
- **Medium**: Inferred from related documentation, error codes, or indirect evidence. Also the maximum confidence for findings from **Rendered** sources (markdown.new / defuddle.md) unless corroborated by a Direct source.
- **Low**: Based on absence of documentation, a single indirect reference, or a page graded **Inaccessible**.

Confidence CANNOT be High if the source page was accessed via a rendering service (Rendered grade) — unless the same information is corroborated by a Direct or Browser-Extracted source.

### Evidence Trail

For every finding, document:
1. Which URLs you WebFetched
2. **Rendering method used**: Direct WebFetch / markdown.new / defuddle.md / agent-browser
3. **Content Quality Grade**: Direct / Rendered / Browser-Extracted / Inaccessible
4. What you found (quote the relevant text when possible)
5. How you arrived at the tier (your reasoning chain)
6. **Finding classification** (when a feature is not found): "Confirmed absent" / "Not found — degraded source" / "Not found — page inaccessible"

This evidence trail is included in the agent's output and will be used by the verification layer.

### Inline Source Links

Every factual claim in sub-agent output MUST include a short inline markdown link at the end of the claim it supports. The orchestrator preserves these links when assembling the final report.

**Format rules:**
- Place the link at the **end** of the claim: `"Idempotency keys are supported ([source](url))"` or `"Supports cursor pagination ([API reference](url))"`
- Link text should be short (1-5 words): `[source](url)`, `[API reference](url)`, `[webhooks guide](url)`, `[documentation](url)`
- **Never start a paragraph or sentence with a link.** The link always goes after the claim it supports.
- For "not found" findings, link to the page that was searched: `"No idempotency mechanism found ([API reference](url))"`
- Multiple sources: link each separately at the end: `"Supports HMAC verification and retry policies ([webhooks guide](url), [security docs](url))"`
- Bare URLs or URL-only appendix references are not sufficient. The reader must be able to click directly from a finding to the page that supports it.

**Single-source fallback:** When all findings come from the same URL (e.g., single-page API docs), sub-agents must still provide verifiable evidence. Instead of repeating the same link on every claim, include a **quoted snippet** from the docs that the reader can search for. Format: `"Correlation ID must be unique" ([API docs](url))` on first use of the URL in a section, then `(docs: "the id is available in webhooks to correlate account creation request")` for subsequent claims in the same section. The goal is that a human reader can always ctrl+F the source and find the text that supports the claim.

### WebFetch SPA Detection and Rendering Fallback

After every WebFetch call, check the response for SPA indicators:
- Body has <500 characters of actual content
- Contains "enable JavaScript", "Loading...", "Please turn on JavaScript", or similar
- Body is mostly `<script>` tags with no readable content
- Contains empty root containers like `<div id="root"></div>` or `<div id="app"></div>`

If SPA is detected, execute the **Rendering Fallback Chain** — stop at the first method that returns usable content:

**Step A — markdown.new**: WebFetch `https://markdown.new/[full-vendor-url]` (append the full vendor URL including protocol as a path, e.g. `https://markdown.new/https://docs.vendor.com/api/overview`). If the response contains meaningful markdown content (>500 chars of text), use it and record rendering method as `markdown.new`.

**Step B — defuddle.md**: WebFetch `https://defuddle.md/[vendor-domain-and-path]` (no protocol prefix, e.g. `https://defuddle.md/docs.vendor.com/api/overview`). If the response contains meaningful content, use it and record rendering method as `defuddle.md`.

**Step C — agent-browser (critical pages or interactive content)**: Attempt this for:
- Pages critical to the assessment (main docs page, API reference, key feature pages) where Steps A-B failed
- Pages where Steps A-B returned content but it contains **interactive content indicators** (see below)

To use agent-browser: first check if a skill called `agent-browser` exists (invoke the Skill tool with `skill: "agent-browser"`). The skill provides documentation on available commands and interaction patterns. If the skill does not exist, use the `agent-browser` CLI tool directly.

Basic extraction workflow: `agent-browser open [url]` → `agent-browser snapshot` → `agent-browser get text @ref` → extract content as text.

For pages with interactive elements, use `agent-browser snapshot` to identify interactive refs, then interact with them (e.g., `agent-browser select @ref "option-value"`, `agent-browser click @ref`) and snapshot again to capture the updated content.

Record rendering method as `agent-browser`.

**Interactive Content Indicators** — escalate to agent-browser even if Steps A-B returned content when the rendered markdown contains:
- `<select>` elements or references to dropdowns that change page content (e.g., "Select a delivery model", "Choose your integration type")
- Tabbed interfaces where content differs per tab (e.g., "REST / GraphQL / SDK" tabs)
- Accordions or expandable sections that hide content behind user interaction
- "Show more" / "Load more" patterns that gate additional content

When interactive content is detected, the agent should: use agent-browser to interact with each option/tab/accordion, snapshot after each interaction, and combine all variations into the extracted content. This ensures no content is missed behind interactive elements.

**Step D — Flag as truly inaccessible**: Only after Steps A-C all fail, mark the page as Inaccessible. Record: "Page [URL] could not be rendered by any method (WebFetch, markdown.new, defuddle.md, agent-browser)."

**Orchestrator shortcut**: When the orchestrator discovers SPA rendering during Step 0 / Step 0.5, it tells all sub-agents which rendering method worked for that domain so they skip the direct WebFetch attempt and go straight to the working renderer. Include this in sub-agent prompts as: `RENDERING NOTE: [domain] is SPA-rendered. Use [method] directly (e.g., prepend https://markdown.new/ to all URLs for this domain).`

### Content Quality Grades

Every page accessed during the assessment MUST be assigned a Content Quality Grade:

| Grade | Meaning | Max Confidence |
|-------|---------|---------------|
| **Direct** | WebFetch returned full, usable content | High |
| **Rendered** | Content obtained via markdown.new or defuddle.md | Medium (unless corroborated by a Direct source) |
| **Browser-Extracted** | Content obtained via agent-browser snapshot + text extraction | High (if thorough extraction) |
| **Inaccessible** | All rendering methods failed | Low |

**Finding Classification Based on Source Quality:**

When a feature or capability is NOT found in the docs, sub-agents MUST classify the finding based on the source quality:

- **"Confirmed absent"** — Only valid from **Direct** or **Browser-Extracted** pages where there is positive evidence of absence (e.g., a complete API reference that lists all endpoints and the feature is not among them).
- **"Not found — degraded source"** — For **Rendered** pages. Sub-agents MUST state: _"Accessed via [markdown.new / defuddle.md], which may not capture interactive content, expandable sections, or dynamically-loaded elements. Human verification recommended at [URL]."_
- **"Not found — page inaccessible"** — For **Inaccessible** pages. Sub-agents MUST state: _"Could not assess — page could not be rendered by any available method."_

**CRITICAL RULE: Sub-agents MUST NOT say "vendor does not support X" or "confirmed absent" based on Rendered or Inaccessible sources.** These sources may be missing interactive content, tabbed sections, or dynamically-loaded elements that contain the information.

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

For each finding, provide: Tier + Confidence + Evidence with short inline markdown links at the end of each claim (e.g., "Supports cursor pagination ([API reference](url))") + Reasoning.
Also generate questions you could not answer from the docs, tagged as Blocker/Important/Nice-to-know.
```

**2. Payment Flow & Webhooks Agent**

```
You are assessing [Vendor]'s payment flow model, async patterns, and webhook system. WebFetch their docs at [URL] and evaluate:

[Include Sub-Agent Rules here]

PAYMENT FLOW MODEL:
- Is the payment/payout creation API synchronous or asynchronous?
  - Synchronous ("sync"): The POST request creates the payment AND returns the final
    success/failure status in the same response. Common with lower-volume vendors.
  - Asynchronous ("async"): The POST request creates the payment and returns an acknowledgment
    (e.g., "accepted", "pending"), but the final success/failure status arrives later via
    webhook or must be polled. Common with higher-volume vendors.
- This is a classification, not a severity finding. Label the flow as "Sync" or "Async"
  and explain the evidence.
- If async: how does the final status arrive? (webhook, polling, both?)
  CRITICAL: Tremendous never relies on webhooks alone — webhooks are unreliable. For async
  vendors, we always implement a dual strategy: listen for webhooks AND poll the vendor's API
  as a fallback if we don't receive a webhook within a predetermined time window. So it's
  essential that there is a GET endpoint to retrieve a payout's current status by ID.
  RED FLAG if: The vendor is async but provides no GET endpoint to check payout status
  (meaning webhooks are the only way to learn the outcome).
- If async: what is the typical latency from payout creation to final status webhook?
  This drives UX decisions (e.g., can we show the user a result immediately, or do we
  need a "processing" state?). Look for documented average and p95 times. If not documented,
  generate a question for the vendor tagged as Important: "What is the average and p95 latency
  from payout creation to final status webhook delivery?"
- If sync: does the vendor also send webhooks for status changes after the initial response
  (e.g., clawbacks, reversals)?

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

For each finding, provide: Tier + Confidence + Evidence with short inline markdown links at the end of each claim (e.g., "Retry policy uses exponential backoff ([webhooks guide](url))") + Reasoning.
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

For each finding, provide: Tier + Confidence + Evidence with short inline markdown links at the end of each claim (e.g., "API keys can be scoped per-endpoint ([security docs](url))") + Reasoning.
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
- SPA rendering: Did any doc pages require the rendering fallback chain? List all affected pages with their Content Quality Grade and which rendering method was used.

For each finding, provide: Tier + Confidence + Evidence with short inline markdown links at the end of each claim (e.g., "OpenAPI spec available at /api/openapi.json ([documentation](url))") + Reasoning.
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

For each finding, provide: Tier + Confidence + Evidence with short inline markdown links at the end of each claim (e.g., "KYB requires programmatic document upload ([onboarding guide](url))") + Reasoning.
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

For each finding, provide: Tier + Confidence + Evidence with short inline markdown links at the end of each claim (e.g., "Sandbox available with self-service provisioning ([testing guide](url))") + Reasoning.
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
- What you found, with short inline markdown links at the end of each claim (e.g., "No idempotency on payment endpoints ([API reference](url))")
- Why it's a concern for integration
- Confidence level (High / Medium / Low)
- Whether you escalated from a lower baseline tier (and why)

Also flag anything else that seems unusual or concerning even if not in the list above.
```

**8. Recipient Experience Agent**

```
You are assessing what the end recipient sees when they receive a payout via [Vendor].
WebFetch their docs at [URL] and evaluate:

[Include Sub-Agent Rules here]

CONTEXT: Tremendous sends payouts on behalf of our customers to their recipients. Understanding
what the recipient experiences is critical for designing our redemption flow and setting
expectations in our product UI.

DELIVERY MECHANISM:
- How does the recipient learn they've been paid? Look for:
  - Email notification from the vendor (like PayPal)
  - SMS notification
  - Funds appear directly in a bank account (ACH, wire, etc.) with no separate notification
  - Recipient receives a URL/link to view or claim the payout (like merchant gift card links)
  - Push notification in a vendor app/wallet
  - Crypto sent directly to a wallet address (recipient sees it on-chain)
- Does the vendor send the notification, or is Tremendous expected to notify the recipient?
- Can the notification be customized or branded (e.g., include our customer's logo or message)?

RECIPIENT ACTIONS REQUIRED:
- Does the recipient need to take any action to receive the funds?
  - Create an account or sign up with the vendor?
  - Click a link to claim/accept?
  - Provide additional info (bank details, KYC, etc.)?
  - Nothing — funds arrive automatically?
- Is there an expiration on unclaimed payouts?

RECIPIENT VISIBILITY:
- Can the recipient see the status of their payout?
  - Tracking page or portal?
  - Email updates on status changes?
  - No visibility until funds arrive?

If not documented, generate questions for the vendor tagged as Important:
- "What does the recipient experience when a payout is sent? Do they receive an email/SMS,
  or do funds simply appear?"
- "Does the recipient need to take any action (sign up, claim, provide details) to receive
  the payout?"
- "Can payout notifications be customized or white-labeled?"

For each finding, provide: Tier + Confidence + Evidence with short inline markdown links
at the end of each claim (e.g., "Recipients receive an email with a claim link ([payout guide](url))").
Generate unanswered questions tagged as Blocker/Important/Nice-to-know.
```

**9. Reconciliation Agent**

```
You are assessing [Vendor]'s reconciliation capabilities. WebFetch their docs at [URL] and evaluate:

[Include Sub-Agent Rules here]

CONTEXT: After a payout is executed, the final cost may differ from what was quoted — especially
when foreign exchange is involved. Tremendous reconciles these differences with every vendor.
Understanding the vendor's reconciliation mechanism is critical for integration architecture.

RECONCILIATION MECHANISM:
- How does the vendor provide reconciliation data? Look for:
  - Standard JSON API endpoints (list/search transactions with filters)
  - CSV or file downloads via API
  - SFTP file drops (scheduled or on-demand)
  - Dashboard-only (manual download from a web portal)
- Can reconciliation data be fetched programmatically, or only via manual export?
- CONCERN if: Dashboard-only with no programmatic access

DATA AVAILABLE IN RECONCILIATION:
- What fields are included? Look for:
  - Transaction/payout ID (linkable back to our records)
  - Final settlement amount (the actual amount delivered, which may differ from the requested amount)
  - FX rate applied (if currency conversion was involved)
  - Fees charged (transaction fees, FX spread, etc.)
  - Status/state of each transaction
  - Timestamps (created, settled, completed, etc.)
- CONCERN if: No way to reconcile FX differences or see the final cost vs. quoted cost

TIMING & AVAILABILITY:
- How soon after a transaction is reconciliation data available?
  - Real-time / near-real-time via API?
  - Next business day?
  - Specific settlement cycle (T+1, T+2, etc.)?

REPORT SCOPE & FILTERING:
- What timeframe does each reconciliation report/file cover?
  - Fixed window (e.g., daily file, last 30 days only)?
  - Custom date range filtering?
- Can you filter by date range, status, currency, or other fields?
- CONCERN if: Fixed window with no filtering (limits ability to reconcile specific periods)

For each finding, provide: Tier + Confidence + Evidence with short inline markdown links
at the end of each claim (e.g., "Transaction reports available via SFTP daily ([settlement docs](url))").
Generate unanswered questions tagged as Blocker/Important/Nice-to-know.
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
7. **Preserve verifiability for single-source docs.** When most or all findings cite the same URL (e.g., single-page API docs), the orchestrator must:
   - Not silently drop inline links. If a link would be the same URL repeated throughout a section, use it once at the section level and include **quoted snippets** from the source for individual claims so the reader can search the original docs.
   - Format: after a factual claim, add the relevant quote in a parenthetical or as an indented block: `(docs say: "Correlation ID must be unique")`
   - For findings based on absence ("no mention of X"), note what was searched and where: `(searched full API docs for "hmac", "signature", "signing" — no matches)`

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
- Evidence: What the docs say, with short inline markdown links at the end of each claim (e.g., "Supports real-time balance updates ([card management API](url))")
- Source: markdown link to the source page (e.g., [API Reference](url)) — if no URL, mark as "Not found in docs"

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
- All URLs you accessed, with rendering method used (Direct WebFetch / markdown.new / defuddle.md / agent-browser)
- Content Quality Grade for each page (Direct / Rendered / Browser-Extracted / Inaccessible)
- Finding classification for any "not found" results (Confirmed absent / Not found — degraded source / Not found — page inaccessible)
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
- **Source verifiability disclaimer.** When the vendor's docs are concentrated on a single page or a small number of pages (making repeated inline links to the same URL unhelpful), add a **Source & Verifiability** note immediately below the tl;dr / Executive Summary blockquote. The note should:
  - Name the primary doc URL(s)
  - Explain why inline links are sparse (e.g., "All API documentation lives on a single ReDoc page, so individual section links aren't available")
  - Tell the reader how to verify claims: "Key findings include quoted text from the docs. Search the API docs page for these quotes to verify."
  - List the distinct URLs that ARE used in the report (e.g., security page, licenses page)

#### Quick Mode Report Structure

```markdown
# [Vendor Name] - Quick API Assessment
**Date**: [today's date]
**Category**: [detected/specified category]
**Mode**: Quick Assessment
**Docs Reviewed**: [URLs]
**Content Sources**: [N] Direct | [N] Rendered (markdown.new/defuddle.md) | [N] Browser-Extracted | [N] Inaccessible

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
[Finding with short inline links at the end of each claim, e.g.: "Mutation endpoints accept an `Idempotency-Key` header ([API reference](url)). Duplicate requests return the original response ([idempotency guide](url))."]

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
| [req 1] | Supported | Strong | High | [evidence quote with inline link] | [API Reference](url) |
| [req 2] | Partial | Concern | Medium | [evidence with inline link] | [documentation](url) |
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

### Direct Sources (Full Content via WebFetch)
[List of URLs that returned full content directly]

### Rendered Sources (markdown.new / defuddle.md)
[List of URLs accessed via rendering services, with which service was used]

### Browser-Extracted Sources (agent-browser)
[List of URLs accessed via agent-browser, if any]

### Inaccessible Pages
[List of URLs where all rendering methods failed, and what impact this had on findings]

### Findings Requiring Human Verification
[List of all findings classified as "Not found — degraded source" — these are findings where the feature
was not found but the source was a Rendered page, so the absence may be due to rendering limitations.
For each, include the URL to check manually and what to look for.]

| Finding | Classification | Source URL | What to Verify |
|---------|---------------|-----------|----------------|
| [feature not found] | Not found — degraded source | [URL] | [Look for X in interactive elements, tabs, expandable sections] |
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

### Step 5.5: Citation Audit

After generating the report and questions documents, audit every inline citation link before
presenting the output to the user. The existing verification layer (Step 3.5) checks whether
*findings* are accurate. This step checks whether *links* still point to content that supports
the claims they're attached to. Vendor docs get reorganized, pages get removed, and Docusaurus
SPAs silently redirect removed pages to the homepage instead of returning 404s.

**1. Extract citations.** Parse all `[text](url)` links from both the assessment report and the
questions document. Deduplicate by URL (many claims may cite the same page).

**2. Spawn citation audit agents.** For each unique URL, spawn a sub-agent (parallel, batched
to avoid redundant fetches). Each agent receives the URL and every claim that cites it:

```
CITATION AUDIT

URL: [url]
CLAIMS CITING THIS URL:
1. "[surrounding sentence or bullet text]" — from section "[section name]"
2. "[surrounding sentence or bullet text]" — from section "[section name]"

Fetch the URL. Apply the standard SPA detection and rendering fallback chain
(Direct → markdown.new → defuddle.md). Then check:

1. BROKEN LINK: Does the URL return a 404, error page, or fail to load entirely?
2. SILENT REDIRECT: Does the page load but show generic/homepage content instead of
   the specific topic expected? (Common with Docusaurus sites that redirect removed
   pages to the docs root.) Compare the page title and content against what the claims
   expect to find there.
3. CLAIM MISMATCH: For each claim, does the page content actually support it? Look for
   the specific feature, endpoint, field, or behavior described in the claim text. A page
   about webhooks that doesn't mention retry counts can't support a claim about "100 retries."

Return one of:
- PASS: URL loads, content supports all claims
- BROKEN: URL returns 404 or error (include details)
- REDIRECT: URL loads but content doesn't match expected topic (include what the page
  actually shows)
- MISMATCH: URL loads and topic is correct, but one or more specific claims aren't
  supported by the page content (list which claims and why)

For BROKEN and REDIRECT: search the vendor's docs site for the correct URL that covers
the expected topic. If found, return the replacement URL.
```

**3. Process results.** For each non-PASS result:
- **BROKEN/REDIRECT with replacement found:** update the link in the report automatically.
- **BROKEN/REDIRECT with no replacement:** remove the inline link and append "(link removed —
  original page no longer available)" after the claim. Downgrade confidence to Medium if it
  was High.
- **MISMATCH:** flag the specific claim for the orchestrator to review. The orchestrator
  decides whether to find a better source URL, reword the claim, or downgrade confidence.

**4. Add audit summary to Evidence Appendix.** Append a section to the report:

```markdown
### Citation Audit
[N] unique URLs checked. [M] passed. [K] issues found and resolved.

[If any issues were found:]
| URL | Issue | Resolution |
|-----|-------|------------|
| [original url] | [Broken/Redirect/Mismatch] | [Replaced with [new url] / Link removed / Claim reworded] |
```

### Step 5.6: Final Verifiability Checklist

Before presenting the report to the user, the orchestrator must verify:

- [ ] Every Red Flag finding has either an inline link OR a quoted snippet from the source docs
- [ ] Every Concern finding has either an inline link OR a quoted snippet
- [ ] If inline links are sparse (most pointing to the same URL), a Source & Verifiability disclaimer exists below the Executive Summary
- [ ] "Not found" findings include what was searched and where (e.g., "searched for 'hmac', 'signature' — no matches")
- [ ] The Evidence Appendix lists all URLs accessed with their Content Quality Grades
- [ ] No finding claims "confirmed absent" without verifiable evidence (link or quote)

If any check fails, fix before proceeding. Only after all checks pass, proceed to Step 6 (Notion Upload).

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
- **Rendering fallback is mandatory.** Never flag a page as inaccessible without first attempting the full rendering fallback chain (markdown.new → defuddle.md → agent-browser for critical pages). Only after all methods fail can a page be marked Inaccessible.
- **Content Quality Grades are mandatory.** Every page accessed during the assessment must be assigned a grade (Direct / Rendered / Browser-Extracted / Inaccessible). Every finding must reference the grade of its source.
- **Sitemap discovery runs before domain investigators.** The Sitemap Discovery Agent (Step 0.5) is a blocking step. Its page inventory must be passed to all sub-agents.
- **Never claim "confirmed absent" from degraded sources.** Sub-agents must not say "vendor does not support X" when the source page was Rendered or Inaccessible. Use the finding classification system: "Confirmed absent" (Direct/Browser-Extracted only), "Not found — degraded source" (Rendered), or "Not found — page inaccessible" (Inaccessible).
- **agent-browser is a last resort.** Only use agent-browser for critical pages (main docs, API reference, key feature pages) when both markdown.new and defuddle.md fail. It is slow and resource-intensive.
- **Citation audit is mandatory.** Every link in the final report must be verified before presenting to the user. Silent redirects (URL loads but shows homepage/generic content) are as bad as 404s. The citation audit (Step 5.5) runs after report generation and before Notion upload.
- **Every finding must have inline source links.** Every factual claim in the report must include short inline markdown links to source documentation at the end of the claim (e.g., `"Supports cursor pagination ([API reference](url))"`). Bare URLs or URL-only appendix references are not sufficient. The reader must be able to click directly from a finding to the page that supports it. Links go at the end of claims (never start a paragraph with a link), with short link text (1-5 words like "source", "API reference", "documentation").
- **Verifiability over link volume.** The purpose of inline links is human verification, not decoration. When a vendor's docs live on a single page, quotes from the docs are more useful than the same URL repeated 40 times. The orchestrator must never silently drop evidence during consolidation — if links are removed, quotes must replace them, and a disclaimer must explain why.

## Adding New Categories

Create a new `.md` file in `config/` following the format of existing category files. The file must define:
1. Category metadata (name, display name, keywords for detection)
2. Level 2 domain agents to spawn (with their scope and prompts)
3. Level 3 sub-domain agents per domain (if applicable)
4. Base requirements per domain
5. Category-specific red flags
6. Category-specific questions template (always-investigate questions)

After creating a new category file, verify it works by running a quick assessment against a known vendor in that category.
