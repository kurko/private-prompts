---
name: app-security-checklist
description: >-
  Run a comprehensive security audit of the current codebase. Use when the user asks
  to audit security, run a security scan, check for vulnerabilities, do a security
  review, or similar. Activates for phrases like "security audit", "check security",
  "find vulnerabilities", "security scan", "pentest this", "OWASP check".
---

# App Security Checklist

A comprehensive security audit skill that covers all 14 OWASP Secure Coding
Practices categories, informed by STRIDE threat modeling, enhanced with
domain-specific profiles, and calibrated against CVSS severity standards.

## How It Works

1. **Focused passes per vulnerability class.** Each subagent receives ONLY its
   category's checklist (15-25 concrete detection patterns). This eliminates the
   "boil the ocean" problem and reduces false positives.
2. **Deployment-aware severity.** Deployment context (PaaS, CDN, self-hosted)
   is detected and injected into every subagent, so findings like "force_ssl
   disabled" get the right severity for the actual infrastructure.
3. **STRIDE-informed context injection.** Before subagents launch, the parent
   performs a lightweight threat model. Each subagent receives the relevant threat
   categories.
4. **Tech stack awareness.** Categories irrelevant to the detected stack are
   skipped entirely.
5. **Domain-specific amplification.** Built-in profiles (fintech, healthcare,
   e-commerce, SaaS/multi-tenant) inject per-category severity elevations and
   additional checks into each subagent. Subagents must acknowledge which
   elevations they applied.
6. **Cross-finding severity calibration.** After all findings are collected and
   reviewed, a calibration pass normalizes severities using the rubric as the
   single source of truth. This catches inter-subagent inconsistencies,
   over-classifications (missing headers rated as HIGH), under-classifications
   (domain elevations missed), and findings mitigated by controls that a
   single-category subagent could not see.
7. **Remediation roadmap.** A dedicated subagent groups all findings into three
   waves (immediate/short-term/medium-term), maps dependencies between fixes,
   and identifies root causes that resolve multiple findings at once.

## Invocation

The user invokes the skill naturally. Parse intent from the user's message:

```
"Run a security audit"                           -> full scan, all categories
"Security audit, focus on auth and crypto"        -> category focus mode
"Security scan, only high and critical"           -> severity threshold mode
"Security audit and fix what you find"            -> scan-and-fix mode
"Security audit for a fintech app"                -> full scan + fintech domain
```

## Modes

| Mode | Trigger | Behavior |
|------|---------|----------|
| **scan** (default) | No special keywords | Scan all relevant categories, produce report |
| **scan-and-fix** | "fix", "remediate", "patch" | Scan, then create branch and commit fixes |
| **category-focus** | Names specific categories | Scan only named categories |
| **severity-threshold** | "only critical", "high and above" | Scan all but filter report to threshold |

## Argument Parsing

Extract these parameters from the user's message:

```
MODE:        scan | scan-and-fix | category-focus | severity-threshold
CATEGORIES:  list of category slugs (for category-focus mode)
THRESHOLD:   critical | high | medium | low (for severity-threshold mode)
DOMAIN:      fintech | healthcare | ecommerce | saas-multi-tenant | <custom>
TARGET_PATH: specific directory to audit (defaults to project root)
```

---

## Subagent Orchestration Principles

These principles govern ALL phases of the audit. Every phase description below
is subject to these rules.

### Why Subagents

Every subagent starts with a clean context window. This is the single most
important quality control mechanism in the skill. When the orchestrating agent
searches dozens of files, reads thousands of lines, and tracks findings across
14 categories, its context fills with noise. Pattern matching degrades.
Confirmation bias accumulates -- once the orchestrator "believes" a finding is
real, it stops scrutinizing. Subagents break this cycle: each one sees only the
evidence it gathers and the instructions it receives.

**The orchestrating agent is a coordinator, not an author.** It detects the tech
stack, performs the STRIDE pre-pass, constructs subagent prompts, launches
subagents, validates their output, and assembles the final deliverable from
subagent-written sections. It MUST NOT write findings, report prose, remediation
advice, attack chain narratives, or executive summaries. If text requires
judgment, synthesis, or security expertise, a subagent writes it.

### The Write-Then-Review Pattern

Every significant text output follows this pipeline:

```
Author Subagent  -->  Review Subagent  -->  Final Text
   (writes)            (validates)          (used in report)
```

1. **Author subagent** produces the text (findings, report section, remediation
   roadmap, attack chain narrative).
2. **Review subagent** receives the author's output PLUS the evidence references
   (file paths, line numbers, code snippets the author cited). The reviewer
   validates the text against the evidence. It does NOT re-search the codebase
   from scratch -- it spot-checks the specific claims.
3. **Orchestrator** incorporates the reviewed text into the final report. If the
   reviewer flagged issues, the orchestrator uses the reviewer's corrected
   version, not the original.

### What Counts as "Significant"

The write-then-review pattern applies to:

- **Category findings** (Phase 2 subagent output) -- already written by
  subagents; these get review subagents
- **Executive summary** (Phase 4) -- written by a synthesis subagent, reviewed
- **Attack chain narratives** -- if findings combine into multi-step attack
  paths, a subagent writes the narrative, another reviews it
- **Remediation roadmap** -- if scan-and-fix mode produces a prioritized fix
  plan, a subagent writes it, another reviews it
- **Domain compliance analysis** (Phase 3) -- written by a subagent, reviewed

The write-then-review pattern does NOT apply to:

- **Tech stack detection** (Phase 0) -- factual file existence checks, < 5 lines
- **Deployment context detection** (Phase 0.5) -- factual file existence checks
- **STRIDE assessment** (Phase 1) -- short, structured, factual (6 lines)
- **Subagent prompt construction** -- mechanical template filling
- **Any output shorter than 5 lines** -- the overhead exceeds the value

### Author Subagent Instructions

Every subagent prompt MUST include this line verbatim in the CRITICAL RULES
section:

```
YOUR OUTPUT WILL BE REVIEWED BY A SEPARATE AGENT that will verify every claim
against the actual codebase. Cite specific files and line numbers for every
assertion. Do not speculate. Do not generalize.
```

This statement is true (a review subagent will check the work) and keeps authors
honest by making the review step salient at writing time.

### Review Subagent Instructions

When spawning a review subagent, use these instructions. The review subagent
receives: (a) the author's complete output, and (b) the deployment context and
STRIDE assessment for calibration.

```
SECURITY FINDING REVIEWER

You are reviewing the output of a security audit subagent. Your job is to
verify accuracy, not to find new vulnerabilities.

For each finding in the author's output, check:

1. EVIDENCE GROUNDING: Does every claim cite a specific file and line number?
   Read each cited file at the cited line. Does the code actually contain what
   the finding claims? If a finding says "user input flows unsanitized to X,"
   verify that the cited code actually shows this. Findings with no file/line
   citations FAIL this check automatically.

2. SEVERITY CALIBRATION: Is the severity justified by what the code actually
   does, not by what it hypothetically could do? Compare against the severity
   rubric. Common over-classifications to watch for:
   - Missing headers rated as HIGH (should be MEDIUM or LOW)
   - Development-only issues rated as production severity
   - Issues behind authentication rated as if they were public

3. MITIGATING CONTROLS: Did the author miss compensating controls? Check for:
   - Framework-level protections (Rails CSRF, Django middleware, etc.)
   - Middleware that validates/sanitizes before the flagged code runs
   - Configuration that restricts the attack surface
   - Deployment context that reduces severity (see DEPLOYMENT CONTEXT below)
   If a mitigating control exists, the finding is either a false positive or
   needs severity downgrade.

4. REMEDIATION SPECIFICITY: Is the remediation advice specific to THIS
   codebase? It must reference actual files, actual patterns, actual gem/package
   names from the project. Generic advice like "use parameterized queries"
   without showing how in the project's actual ORM/framework is insufficient.

5. FALSE POSITIVE CHECK: Could this finding be a false positive? Common
   sources: test fixtures, seed data, commented-out code, development-only
   configurations, dead code paths.

For each finding, return one of:

  CONFIRMED — evidence checks out, severity is appropriate
  ADJUSTED  — evidence checks out but severity is wrong (state correct severity and why)
  WEAKENED  — finding is real but mitigating controls reduce impact (state adjusted severity)
  REJECTED  — false positive or evidence does not support the claim (state why)

If you REJECT or ADJUST a finding, provide a one-line explanation that will
appear in the final report's transparency notes.

Do NOT add new findings. Do NOT re-audit the codebase. You are a reviewer,
not an auditor.
```

### Handling Disagreements

When a review subagent downgrades or rejects a finding:

- **ADJUSTED findings:** Use the reviewer's severity in the final report. Append
  a transparency note: `[Severity adjusted during review: [original] -> [final],
  reason: [reviewer's explanation]]`.
- **WEAKENED findings:** Use the reviewer's reduced severity. Append:
  `[Mitigating control identified during review: [control description]]`.
- **REJECTED findings:** Remove from the main findings. Add to a
  "Reviewed Out" appendix at the end of the report:

  ```
  ## Reviewed Out

  These findings were identified during the audit but removed after
  independent review determined they were false positives or unsupported
  by evidence.

  | Original ID | Title | Reviewer Verdict | Reason |
  |-------------|-------|------------------|--------|
  | 06-03 | Missing tenant scoping on ... | REJECTED | ActsAsTenant middleware applies globally (app/models/concerns/...) |
  ```

  This section provides transparency: the reader sees what was considered and
  why it was excluded, rather than wondering if the audit missed it.

- **CONFIRMED findings:** No annotation needed. Use as-is.

The orchestrating agent MUST NOT override a reviewer's REJECTED verdict. If the
orchestrator disagrees with a rejection, it adds an "Orchestrator Note" column
to that row in the "Reviewed Out" table explaining why it disagrees. The human
reader decides. Do NOT spawn additional reviewers to resolve disagreements --
the cost is not justified for a rare edge case, and the reviewer saw the
evidence more recently than the orchestrator.

### Performance Considerations

- **Parallel review:** Review subagents for independent categories run in
  parallel. A single review subagent can review all findings from one category
  (typically 0-5 findings). Do not spawn one reviewer per finding.
- **Batch small categories:** If a category produced 0-1 findings, batch its
  review with another small category's review into a single reviewer subagent
  to reduce overhead.
- **Skip review for CLEAN categories:** If a category subagent returned
  STATUS: CLEAN with no findings, no review is needed.
- **Skip review for trivially short output:** If total output (findings +
  clean areas) is under 5 lines, skip review.
- **Executive summary review:** The executive summary review subagent runs
  AFTER all category reviews complete (it needs the final, reviewed findings
  to verify the summary is accurate).

### Orchestrator Discipline

The orchestrating agent's permitted actions:

| Permitted | NOT Permitted |
|-----------|---------------|
| Detect tech stack (Phase 0) | Write finding descriptions |
| Detect deployment context (Phase 0.5) | Write remediation advice |
| Perform STRIDE pre-pass (Phase 1) | Write executive summary prose |
| Construct subagent prompts from templates | Editorialize on findings |
| Launch and collect subagent results | Rephrase subagent output "for clarity" |
| Validate subagent output format | Add commentary to findings |
| Apply domain severity elevations (mechanical) | Invent attack scenarios |
| Assemble reviewed sections into final report | Summarize what subagents found in its own words |
| Write the "Reviewed Out" appendix (tabular, factual) | |

When assembling the final report, the orchestrator copies reviewed text
verbatim from subagent output into the report template. It may reorder
sections, apply formatting to match the template, and insert section headers,
but it does not rewrite subagent prose.

## Execution Phases

### Phase 0: Tech Stack Detection

Detect the tech stack by checking for these files:

**Languages:**
- `Gemfile` → Ruby
- `package.json` → JavaScript/TypeScript
- `requirements.txt` / `Pipfile` / `pyproject.toml` → Python
- `go.mod` → Go
- `Cargo.toml` → Rust
- `pom.xml` / `build.gradle` → Java
- `*.csproj` → .NET
- `composer.json` → PHP

**Frameworks:**
- `config/routes.rb` → Rails
- `manage.py` → Django
- `next.config.*` → Next.js
- `mix.exs` → Elixir/Phoenix

**Databases:** Check `config/database.yml`, `prisma/schema.prisma`, `mongoid.yml`,
or grep dependency files for `pg`, `mysql2`, `sqlite3`, `mongoose`.

**Infrastructure:** `Dockerfile`, `docker-compose.yml`, `.github/workflows/`

**Category skip rules:**
- Skip **14-Memory Management** for: Ruby, Python, JavaScript, Java, C#, Elixir
- Skip **12-Database Security** if no database detected
- Skip **13-File Management** if no file upload/download patterns found
- Skip **10-Communication Security** if no network calls or API endpoints detected
- When in doubt, **include** the category

**Domain auto-detection:** Grep for domain signal keywords (defined in each
`domains/*.md` file). If a domain scores 3+ keyword matches, activate it
automatically. Tell the user which domain was detected and allow override.

### Phase 0.5: Deployment Context Detection

After tech stack detection, detect the deployment environment. Deployment context
affects severity ratings -- for example, `force_ssl = false` is HIGH when the app
runs on a bare VPS but MEDIUM when deployed behind Heroku, CloudFlare, or another
platform that handles TLS termination at the edge.

**Files to check:**

| Signal File / Location | What It Indicates |
|------------------------|-------------------|
| `Procfile` | Heroku (or Heroku-like PaaS) |
| `app.json` | Heroku review apps / configuration |
| `fly.toml` | Fly.io |
| `render.yaml` | Render |
| `railway.json` or `railway.toml` | Railway |
| `vercel.json` or `.vercel/` | Vercel |
| `netlify.toml` | Netlify |
| `terraform/**/*.tf` | Infrastructure-as-code (check for provider blocks) |
| `k8s/**/*.yml`, `k8s/**/*.yaml` | Kubernetes manifests |
| `docker-compose.yml` | Docker Compose (self-hosted or local) |
| `nginx.conf`, `nginx/*.conf` | Nginx reverse proxy (self-hosted likely) |
| `Caddyfile` | Caddy (auto-TLS) |
| `.platform/` | Platform.sh |
| `.elasticbeanstalk/`, `Dockerrun.aws.json` | AWS Elastic Beanstalk |
| `.gcloudignore`, `app.yaml` (GAE) | Google Cloud |
| `azure-pipelines.yml`, `.azure/` | Azure |
| Git remotes (run `git remote -v`) | Heroku (`heroku.com`), Render, Fly, etc. |

**What to extract:**

1. **Hosting platform:** `heroku | fly | render | railway | vercel | netlify |
   aws-eb | gcp | azure | kubernetes | self-hosted | unknown`
2. **TLS termination point:** `platform-managed | cdn-edge | load-balancer |
   app-level | unknown`
   - Platform-managed: Heroku, Fly, Render, Railway, Vercel, Netlify, GAE, Azure App Service
   - CDN-edge: Look for CloudFlare (CF headers in code, `cloudflare` in DNS config),
     Fastly, AWS CloudFront references
   - Load-balancer: Nginx/Caddy in front of app, ALB/NLB references in Terraform
   - App-level: No proxy detected, app handles TLS directly
3. **CDN presence:** `cloudflare | fastly | cloudfront | none-detected`
   - Grep for `CDN-` headers, `CF-` headers, CloudFront distribution IDs
4. **Managed database:** `yes | no | unknown`
   - Heroku `DATABASE_URL`, Render database references, RDS/Cloud SQL in Terraform
5. **Container orchestration:** `kubernetes | ecs | docker-compose | none`

**Output format:**

```
DEPLOYMENT CONTEXT:
- Platform:         heroku
- TLS termination:  platform-managed
- CDN:              cloudflare
- Managed database: yes
- Orchestration:    none
- Confidence:       high (Procfile + heroku git remote + DATABASE_URL)

SEVERITY ADJUSTMENTS:
- CS-01 (force_ssl): HIGH -> MEDIUM (TLS terminated at platform edge)
- SC-05 (container hardening): N/A (no containers, platform-managed)
- SC-08 (firewall rules): N/A (platform manages network layer)
```

**Severity adjustment rules:**

| Finding | Bare / Self-Hosted | PaaS (Heroku, Fly, Render) | Behind CDN (CF, Fastly) |
|---------|--------------------|----------------------------|-------------------------|
| `force_ssl` disabled | HIGH | MEDIUM (platform forces HTTPS) | MEDIUM (CDN forces HTTPS) |
| Missing HSTS | HIGH | MEDIUM (platform sets HSTS) | LOW (CDN sets HSTS) |
| No firewall config | HIGH | N/A (platform-managed) | MEDIUM (CDN provides WAF) |
| DB on public network | CRITICAL | N/A (managed DB) | CRITICAL |
| Missing container hardening | HIGH | N/A (no containers) | HIGH |
| Server version disclosure | MEDIUM | LOW (behind platform proxy) | LOW (behind CDN) |

**When nothing is found:** If no deployment signals are detected, set platform to
`unknown` and confidence to `low`. In this case, **assume direct exposure** --
rate all findings as if the app is self-hosted on a bare VPS with no CDN, no
managed TLS, and no network-level protections. State this assumption explicitly
in the report.

**Injection into subagent prompts:** The deployment context block is appended to
the subagent prompt template after the STRIDE assessment. Subagents use it to
calibrate severity. The severity adjustment rules table above MUST be included
in each subagent prompt so adjustments are applied consistently.

### Phase 1: STRIDE Pre-Pass

Perform a rapid STRIDE threat assessment by examining:
1. **Application type** (web app, API, CLI tool, library, mobile backend)
2. **Trust boundaries** (auth middleware, API gateways, public endpoints)
3. **Data sensitivity** (PII fields, payment data, health records)
4. **External integrations** (third-party APIs, webhooks, OAuth providers)

Produce a STRIDE assessment in this format:

```
STRIDE THREAT ASSESSMENT:
- Spoofing:              HIGH/MEDIUM/LOW (brief explanation)
- Tampering:             HIGH/MEDIUM/LOW (brief explanation)
- Repudiation:           HIGH/MEDIUM/LOW (brief explanation)
- Information Disclosure: HIGH/MEDIUM/LOW (brief explanation)
- Denial of Service:     HIGH/MEDIUM/LOW (brief explanation)
- Elevation of Privilege: HIGH/MEDIUM/LOW (brief explanation)
```

### Phase 2: Parallel Subagents

Spawn one subagent per active category **in parallel** using model=opus.

For each active category:
1. Read the category's checklist file from `checks/XX-category-name.md`
   (the file is in the same directory as this SKILL.md)
2. Read `domains/<active-domain>.md` if a domain is active — extract the
   section relevant to this category (see **Domain Profile Injection** below)
3. Read `templates/subagent-prompt.md` — this is the prompt template
4. Read `templates/severity-rubric.md` — inject into the subagent prompt
5. Construct the subagent prompt by filling in the template:
   - Replace `[CATEGORY_NAME]` with the category name
   - Replace `[detected stack]` with Phase 0 results
   - Replace `[injected STRIDE assessment]` with Phase 1 results
   - Insert the deployment context block from Phase 0.5 (including the
     severity adjustment rules table)
   - Replace `[domain name]` and inject per-category domain notes
     (see **Domain Profile Injection** below)
   - Insert the full checklist file contents
   - Insert the full severity rubric contents
6. Spawn the subagent

**Critical:** Spawn ALL subagents in parallel. Do NOT run them sequentially.

#### Domain Profile Injection (Per-Category)

When a domain profile is active, each subagent must receive ONLY the domain
notes that apply to its category. This prevents prompt bloat and ensures the
subagent acts on the right elevations.

**Extraction procedure:**

1. Parse the domain profile's **Severity Elevations** table. Each row maps a
   checklist item ID (e.g., `AC-01`, `DP-01`) to a category by its prefix:
   - `AC-*` -> `06-access-control`
   - `AU-*` -> `03-authentication`
   - `CP-*` -> `07-cryptographic-practices`
   - `CS-*` -> `10-communication-security`
   - `DB-*` -> `12-database-security`
   - `DP-*` -> `09-data-protection`
   - `EH-*` -> `08-error-handling-logging`
   - `FM-*` -> `13-file-management`
   - `IV-*` -> `01-input-validation`
   - `MM-*` -> `14-memory-management`
   - `OE-*` -> `02-output-encoding`
   - `PM-*` -> `04-password-management`
   - `SC-*` -> `11-system-configuration`
   - `SM-*` -> `05-session-management`

2. For each subagent, filter severity elevations to ONLY those whose item ID
   prefix matches the subagent's category. Example: the `06-access-control`
   subagent receives `AC-01: High -> Critical` but NOT `DP-01: High -> Critical`.

3. Parse the **Additional Checks** section. Each additional check (e.g., `MT-01`,
   `FIN-01`) has a detection patterns section that lists file globs. Match
   additional checks to subagent categories using this heuristic:
   - If the check's file globs overlap with the subagent's category scope
     (e.g., `app/models/**` -> `12-database-security`, `06-access-control`)
   - If the check's title/description maps to the category domain (e.g.,
     "Transaction Integrity" -> `12-database-security`)
   - When ambiguous, include the check in ALL plausibly relevant subagents.
     The parent will de-duplicate.

4. Construct the domain injection block for the subagent prompt:

```
DOMAIN PROFILE: [domain name]
COMPLIANCE FRAMEWORK: [frameworks from domain profile]

SEVERITY ELEVATIONS FOR THIS CATEGORY:
These items have elevated severity due to [domain] requirements.
You MUST use the elevated severity when rating these findings.
| Item | Standard | Elevated | Reason |
|------|----------|----------|--------|
| [only rows relevant to this category] |

ADDITIONAL DOMAIN CHECKS FOR THIS CATEGORY:
[only additional checks relevant to this category, full content including
detection patterns and secure patterns]
```

5. If no severity elevations or additional checks match a category, the domain
   injection block should still be present but state:

```
DOMAIN PROFILE: [domain name]
COMPLIANCE FRAMEWORK: [frameworks]
SEVERITY ELEVATIONS FOR THIS CATEGORY: None — no elevations apply to this category.
ADDITIONAL DOMAIN CHECKS FOR THIS CATEGORY: None — no additional checks for this category.
```

**Subagent acknowledgment requirement:**

Each subagent MUST include an `APPLIED_ELEVATIONS` section in its return output,
immediately after the `STATUS` line:

```
CATEGORY: Access Control
STATUS: FINDINGS

APPLIED_ELEVATIONS:
- AC-01: HIGH -> CRITICAL (SaaS multi-tenant: IDOR = cross-tenant access) [APPLIED to finding 06-02]
- AC-08: CRITICAL -> CRITICAL (no change, already Critical) [NOT APPLICABLE, no finding]

DEPLOYMENT_ADJUSTMENTS:
- CS-01: HIGH -> MEDIUM (TLS terminated at platform edge) [APPLIED to finding 10-01]
```

If the subagent reports a finding whose ID matches a severity elevation row
but does NOT use the elevated severity, the parent agent flags this as a
validation error and re-rates the finding to the elevated severity, appending
a note: `[Severity elevated per [domain] profile: [reason]]`.

Each subagent returns findings in this format:

```
CATEGORY: [category name]
STATUS: FINDINGS | CLEAN | ERROR

---
ID: [category-number]-[sequential]
SEVERITY: CRITICAL | HIGH | MEDIUM | LOW
TITLE: [one-line description]
FILE: [absolute path]
LINE: [line number or range]
CODE: |
  [relevant code snippet]
EVIDENCE: [what was observed and verified]
REMEDIATION: |
  [specific fix with code example]
CWE: [CWE ID]
OWASP_TOP10: [mapping]
---

CLEAN_AREAS:
- [area]: [what was checked and why it passed]
```

### Phase 2.5: Finding Review

Before domain-specific checks, review all subagent findings using the
write-then-review pattern (see **Subagent Orchestration Principles** above).

1. For each category that returned STATUS: FINDINGS, spawn a **review subagent**
   using the Review Subagent Instructions from the orchestration principles.
   Provide the reviewer with:
   - The category subagent's complete output
   - The deployment context and STRIDE assessment
   - The severity rubric
2. Run review subagents **in parallel** across categories. Batch categories with
   0-1 findings into shared reviewers to reduce overhead.
3. Collect reviewer verdicts. Apply CONFIRMED / ADJUSTED / WEAKENED / REJECTED
   dispositions per the Handling Disagreements rules.
4. Produce the reviewed finding set for Phase 3 and beyond.

### Phase 3: Domain-Specific Checks

If a domain profile is active:
1. Check for domain-specific requirements not covered by the 14 categories
2. Elevate severity of findings per the domain's Severity Elevations table
3. Add compliance mapping (PCI DSS numbers, HIPAA rules, etc.)

### Phase 3.5: Severity Calibration

**Purpose:** Normalize severity ratings across all subagent findings using the
severity rubric as the single source of truth. Subagents rate severities
independently, and despite receiving the same rubric, they apply it
inconsistently -- the same finding type gets rated CRITICAL by one subagent
and HIGH by another. Review subagents (Phase 2.5) catch some of this per
category, but they lack cross-finding visibility. This phase eliminates
remaining variance before the report is written.

**When:** After Phase 3 (domain elevations applied) and before Phase 4 (report
synthesis). By this point, every finding has survived review (Phase 2.5),
received any applicable domain elevation (Phase 3), and carries a proposed
severity that may or may not match the rubric.

**Executor:** The parent agent performs this phase directly. No subagent is
spawned. Calibration requires cross-finding visibility (comparing severities
across categories, checking clean areas from one subagent against findings
from another) that a single-category subagent cannot have. The work is
mechanical: compare proposed severities against rubric criteria, apply rules,
produce a mapping. This fits the orchestrator's permitted actions (see
**Orchestrator Discipline**) because it is rule application, not judgment or
prose writing.

#### Inputs

The calibration phase operates on:

1. **All findings** from all subagents that survived review (Phase 2.5), with
   their current severities -- including any domain elevations applied in
   Phase 3
2. **The severity rubric** (`templates/severity-rubric.md`). This is the
   authoritative reference. If a proposed severity contradicts the rubric, the
   rubric wins unless a domain elevation explicitly overrides it
3. **The STRIDE assessment** from Phase 1
4. **The active domain profile** (`domains/<domain>.md`), if any, including its
   Severity Elevations table
5. **The deployment context** from Phase 0.5 (platform, TLS termination point,
   CDN presence, managed database, container orchestration)
6. **All CLEAN_AREAS sections** from every subagent. These document what was
   checked and found secure -- critical for identifying mitigating controls
   that other subagents missed

#### Process

For each finding, evaluate these checks in order. Each check may adjust the
working severity up or down. Later checks operate on the result of earlier
checks, not the original proposed severity.

**1. Rubric baseline.**
Look up the finding's type in the severity rubric. The rubric has two relevant
sections: the severity-level indicators (e.g., "Missing HTTPS for sensitive data
transmission" listed under High) and the Calibration Examples table (explicit
WRONG/RIGHT mappings). If either section covers this finding type and the
proposed severity differs, set the working severity to the rubric's
classification. This becomes the baseline for subsequent checks.

If the rubric does not have an exact match for the finding type, the proposed
severity carries forward as the working severity.

**2. Domain elevation check.**
If a domain profile is active, check its Severity Elevations table. Domain
elevations raise severity above the rubric baseline (e.g., IDOR goes from
High to Critical in fintech). Verify that Phase 3 applied all applicable
elevations. If a finding matches a domain elevation row but the working
severity is below the domain's specified severity, raise it now.

Domain elevations NEVER lower a severity. They only raise. The domain-elevated
severity becomes a **floor** -- no subsequent check can lower the finding
below this floor.

**3. Deployment context check.**
Determine if infrastructure mitigations reduce real-world exploitability.
Reference the Phase 0.5 severity adjustment rules table. Examples:

- `force_ssl = false` behind CloudFlare with HTTPS enforcement at the edge:
  downgrade from High to Medium (infrastructure enforces the control)
- Missing rate limiting when Rack::Attack is absent but CDN rate limiting
  is active: downgrade by one level
- Missing security headers when the reverse proxy / CDN injects them:
  downgrade by one level
- Development-only findings confirmed unreachable in production by the
  deployment pipeline: downgrade to Low or remove

**Constraints:**
- Deployment context NEVER lowers a Critical finding. A Critical rating means
  the primary control is absent -- infrastructure mitigations are
  defense-in-depth, not replacements.
- Deployment context NEVER lowers a finding below its domain-elevated floor
  (from step 2). If the fintech domain elevates IDOR to Critical, deployment
  context cannot lower it to High.

**4. Over-classification check.**
Flag and correct these common subagent biases:

**a. "Missing X" treated as a primary vulnerability.**
Subagents frequently rate missing defense-in-depth controls as if they were
primary controls. The rubric is the ceiling for these findings:

| Pattern | Common Over-Classification | Rubric Severity |
|---------|---------------------------|-----------------|
| Missing CSP header | High | Medium |
| Missing X-Content-Type-Options | Medium | Low |
| Missing Referrer-Policy | Medium | Low |
| Missing SRI on CDN resources | High | Low |
| Missing rate limiting on non-auth endpoints | Medium | Low |
| Missing X-Frame-Options (when CSP frame-ancestors exists) | Medium | Low |

**Rule:** If the finding is "missing [defensive header/feature]" and the
rubric classifies it lower than the proposed severity, use the rubric.
The subagent's argument that the feature is "important" does not override
the rubric.

**b. Authenticated-attacker findings rated as unauthenticated.**
If exploiting the finding requires an already-authenticated user, the severity
must reflect the required access level. Check the finding's FILE and CODE:

- File in `app/controllers/admin/` or `Admin::` namespace → attacker needs
  admin credentials
- Code guarded by `before_action :authenticate_user!` or similar → attacker
  needs authentication
- Code in a controller that inherits from an authenticated base class →
  check the base class

**Rule:** A finding that requires authenticated access is one severity level
lower than the equivalent unauthenticated finding. A finding that requires
admin access is two levels lower (minimum Low). Typical adjustment:
`params.permit!` in admin controller → High, not Critical.

**c. Findings in dead code or development-only paths.**
Subagents report findings in files that never run in production.

**Rule:** If the finding's file path matches any of these patterns, downgrade
to Low with justification "development/test-only code path":
- `db/seeds*`
- `spec/**`, `test/**`, `features/**`
- `config/environments/development.rb`, `config/environments/test.rb`
- `*_test.rb`, `*_spec.rb`, `*.test.js`, `*.spec.ts`

Also check if the vulnerable code is inside a runtime guard:
- `if Rails.env.development?` / `if Rails.env.test?`
- `if ENV['RAILS_ENV'] == 'development'`
- `unless Rails.env.production?`

These are Low at most, regardless of what the vulnerability would be in
production code.

**d. Findings mitigated by controls from another subagent's scope.**
Each subagent audits one category and cannot see mitigating controls that
belong to other categories. Cross-reference findings against CLEAN_AREAS
from all subagents:

| Finding (Subagent A) | Mitigating Control (Subagent B's CLEAN_AREAS) | Action |
|----------------------|-----------------------------------------------|--------|
| Missing CSRF protection | Endpoint uses API token auth (no cookies) | Remove or downgrade to Low |
| SQL injection risk | ORM parameterizes all queries (confirmed clean) | Verify and remove if false positive |
| Missing password complexity | App uses OAuth-only (no local passwords) | Remove |
| Missing brute-force protection on login | Rate limiting configured at CDN/proxy | Downgrade by one level |
| Session fixation risk | Session ID regenerated on login (confirmed) | Remove if fully mitigated |

**Rule:** When subagent A reports a finding and subagent B's CLEAN_AREAS
explicitly describe a mitigating control for that exact issue, downgrade
or remove the finding with justification citing the mitigating control and
the subagent that confirmed it.

**5. Under-classification check.**
Flag these patterns:

**a. Compounding findings.**
When two or more findings in combination create a worse outcome than either
alone, annotate each finding with a `COMPOUNDS_WITH` field listing related
finding IDs. Do NOT change individual severities here -- severity elevation
for attack chains happens during Phase 4 report synthesis, where compound
findings are presented together. The calibration phase only annotates the
relationship.

Examples:
- Missing CSRF + session fixation → session hijacking chain
- IDOR + missing audit logging → undetectable unauthorized data access
- Reflected XSS + missing CSP → reliable XSS exploitation
- SQL injection + verbose error messages → accelerated exploitation

**b. Domain elevations the subagent missed.**
If the domain profile's Severity Elevations table specifies a higher severity
for a checklist item ID, and the finding still carries the standard severity
after Phase 3, apply the domain elevation. This is a completeness check --
Phase 3 should have caught these, but verify.

**c. STRIDE-informed elevation.**
If the STRIDE assessment rated a threat category as HIGH and a finding
directly maps to that threat category at Medium or lower, flag it for human
review. Do NOT auto-elevate. Add a note: `"STRIDE assessment rates [threat]
as HIGH; verify severity is appropriate."` The reviewer or the user decides
whether to elevate.

#### Output Format

Produce a calibration table. Only findings with adjustments or annotations
appear in the table. Findings where proposed severity equals final severity
and no annotations apply are omitted (implicit pass-through).

```
SEVERITY CALIBRATION RESULTS:

[finding_id]:
  proposed: [severity from subagent / Phase 3]
  final: [calibrated severity]
  justification: "[one-line reason for change]"
  compounds_with: [list of finding IDs, if applicable]

[finding_id]:
  proposed: [severity]
  final: [severity]
  justification: "[reason]"

CALIBRATION SUMMARY:
  Total findings reviewed: N
  Adjusted up:   N ([list of IDs])
  Adjusted down: N ([list of IDs])
  Unchanged:     N
  Annotated with compound relationships: N
  Flagged for human review (STRIDE): N
```

#### Calibration Example

```
SEVERITY CALIBRATION RESULTS:

10-01:
  proposed: CRITICAL
  final: HIGH
  justification: "force_ssl disabled -- rubric classifies 'Missing HTTPS for sensitive data transmission' as HIGH (not CRITICAL). Deployment context: behind CloudFlare, but CDN mitigation does not apply because rubric match takes precedence at HIGH."

06-03:
  proposed: CRITICAL
  final: MEDIUM
  justification: "Row-level tenant isolation finding over-classified. Subagent 06 reported missing DB-level RLS, but subagent 06 CLEAN_AREAS confirms workspace scoping via current_user.workspaces enforced in ApplicationController. No cross-tenant access path demonstrated. This is defense-in-depth (MEDIUM), not a primary control failure."

08-02:
  proposed: LOW
  final: LOW
  justification: "No severity change, but STRIDE notes added."
  compounds_with: [06-01]
  stride_note: "STRIDE assessment rates Repudiation as HIGH; verify severity is appropriate."

11-05:
  proposed: HIGH
  final: LOW
  justification: "Debug mode finding in config/environments/development.rb -- development-only code path, not reachable in production."

02-01:
  proposed: HIGH
  final: LOW
  justification: "Missing CSP header proposed as HIGH, rubric classifies as MEDIUM. Further downgraded to LOW: deployment context shows CloudFlare injects CSP header at edge (confirmed in Phase 0.5)."

05-02:
  proposed: HIGH
  final: HIGH
  justification: "No severity change. Annotated with compound relationship."
  compounds_with: [03-01]

CALIBRATION SUMMARY:
  Total findings reviewed: 19
  Adjusted up:   0
  Adjusted down: 4 (10-01, 06-03, 11-05, 02-01)
  Unchanged:     15
  Annotated with compound relationships: 2
  Flagged for human review (STRIDE): 1
```

#### Calibration Principles

These resolve ambiguity when the rubric does not have an exact match:

1. **The rubric is the single source of truth.** If the rubric classifies a
   finding type at a specific severity, that severity governs. Subagent
   arguments, STRIDE context, and deployment context do not override explicit
   rubric classifications -- they only apply when the rubric is silent or when
   domain elevations explicitly raise the ceiling.

2. **Domain elevations are the ceiling for domain-adjusted findings.** If the
   fintech domain elevates IDOR from High to Critical, that is the final
   severity. Neither deployment context nor calibration can lower it below
   the domain's specified severity.

3. **Severity measures impact given access requirements.** A finding that would
   be devastating if exploited but requires admin credentials is less severe
   than the same finding exploitable by anonymous users. Access requirements
   are part of the severity assessment per CVSS.

4. **One finding, one severity.** If the same finding was reported by multiple
   subagents with different proposed severities (pre-dedup), the calibrated
   severity applies to the deduplicated finding. Note the highest proposed
   severity in the justification for traceability.

5. **Calibration does not invent findings or remove them.** It adjusts severity
   and annotates relationships. Finding removal (false positives) is handled
   by Phase 2.5 review subagents. If calibration determines a finding is a
   false positive, it downgrades to Low with a justification, but does not
   delete it -- the report's "Reviewed Out" section is the appropriate place
   for removals.

6. **Transparency over stealth.** Every adjustment appears in the calibration
   table with a justification. The report includes the calibration summary so
   the reader can see what changed and why. Hidden severity changes erode
   trust in the audit.

#### Integration with Phase 4

Phase 4 (Report Synthesis) receives calibrated findings. The report template
gains a new section after the executive summary:

```
## Severity Calibration

N findings had their severity adjusted during cross-finding calibration.
[N up, N down, N compound annotations.]

| Finding | Proposed | Final | Reason |
|---------|----------|-------|--------|
| 10-01 | CRITICAL | HIGH | Rubric: missing HTTPS = HIGH |
| 06-03 | CRITICAL | MEDIUM | Workspace scoping mitigates; defense-in-depth only |
| ... | ... | ... | ... |
```

This section is factual and tabular -- the orchestrator writes it directly
(no subagent needed) since it is a reformatting of the calibration output.

Compound annotations (`COMPOUNDS_WITH`) are passed to the synthesis subagent
so it can identify and narrate attack chains in the executive summary.

### Phase 4: Report Synthesis

Collect all **reviewed and calibrated** subagent findings and assemble the
final report. By this point, findings have passed through review (Phase 2.5),
domain elevation (Phase 3), and severity calibration (Phase 3.5). Use the
**final** (calibrated) severities for sorting and counting.

1. De-duplicate findings that span multiple categories
2. Sort by **calibrated** severity (Critical first)
3. Spawn a **synthesis subagent** (model=opus) to write the executive summary.
   The synthesis subagent receives the complete calibrated finding set (IDs,
   final severities, titles, categories) plus the STRIDE assessment and any
   `COMPOUNDS_WITH` annotations from Phase 3.5. It writes only the executive
   summary paragraph and the finding count table. A separate **review subagent**
   then verifies the summary matches the actual findings (no invented findings,
   no omitted criticals, counts reflect calibrated severities).
4. Add the STRIDE assessment (from Phase 1, verbatim)
5. Add the **Severity Calibration** section (from Phase 3.5 output, tabular --
   orchestrator writes this directly per the Phase 3.5 Integration spec)
6. Add domain compliance notes (if applicable)
7. Populate the "Reviewed Out" section with any REJECTED findings and their
   reviewer explanations. If no findings were reviewed out, state:
   "All findings survived independent review."
8. Add transparency notes to ADJUSTED and WEAKENED findings inline
9. Write the report to `tmp/security-audit-YYYY-MM-DD.md`
10. If severity-threshold mode: filter the report but note filtered counts

The orchestrator assembles these sections into the `templates/report.md`
structure. It copies subagent-written text verbatim -- it does not rephrase,
editorialize, or add commentary (see **Orchestrator Discipline**).

Display the report path and finding summary to the user.

### Phase 4.5: Remediation Roadmap

After report synthesis and before any scan-and-fix execution, generate a
prioritized remediation roadmap. This is produced by a **dedicated subagent**
(model=opus) that receives ALL findings plus attack chain analysis.

**Subagent input:**
1. All findings from Phase 2 (full list with IDs, severities, files, and
   remediation snippets)
2. The STRIDE assessment from Phase 1
3. The deployment context from Phase 0.5
4. The domain profile (if active), including compliance requirements
5. Attack chains identified during Phase 4 report synthesis

**Subagent instructions:**

```
REMEDIATION ROADMAP GENERATOR

You receive the complete set of security audit findings. Your job is to
organize them into an actionable remediation roadmap with three waves,
identify dependencies between fixes, and flag which findings are
prerequisites for others.

YOUR OUTPUT WILL BE REVIEWED BY A SEPARATE AGENT that will verify every
claim against the actual codebase. Cite specific files and line numbers for
every assertion. Do not speculate. Do not generalize.

GROUP FINDINGS INTO WAVES:

WAVE 1 — Immediate (hours)
  Criteria: one-liner config changes, environment variable additions,
  toggling existing flags. These block exploitation of other issues or
  are trivially fixable.
  Examples:
  - Set `config.force_ssl = true`
  - Add missing security headers via a one-line middleware config
  - Remove hardcoded secrets and replace with ENV references
  - Set secure cookie flags
  - Add `protect_from_forgery` to a controller
  - Fix a permissive CORS origin

WAVE 2 — Short-term (days)
  Criteria: requires adding a gem/package, enabling a module, configuring
  middleware, writing a small service class, or adding validation logic.
  Non-trivial but scoped to individual files or small subsystems.
  Examples:
  - Add rack-attack for rate limiting
  - Implement CSRF token rotation
  - Add parameterized queries to replace string interpolation SQL
  - Add output encoding helpers
  - Configure Content-Security-Policy with proper directives
  - Add audit logging for sensitive operations
  - Rotate exposed secrets and add to credential manager

WAVE 3 — Medium-term (sprint)
  Criteria: architectural changes, new models, data migrations, redesigning
  authorization systems, adding multi-tenancy isolation, implementing
  encryption-at-rest. Requires planning, testing, and possibly coordination
  with product.
  Examples:
  - Implement row-level security for multi-tenancy
  - Add a proper authorization framework (Pundit/CanCanCan)
  - Redesign session management architecture
  - Migrate from homegrown auth to Devise/Auth0
  - Add field-level encryption for PII
  - Implement proper key rotation infrastructure

DEPENDENCY MAPPING:
For each finding, check:
1. Does fixing this finding make another finding irrelevant?
   (e.g., "fix force_ssl before the HSTS finding matters")
2. Does fixing this finding require another finding to be fixed first?
   (e.g., "add auth framework before fixing individual authorization gaps")
3. Do multiple findings share a root cause that should be fixed once?
   (e.g., "all IDOR findings trace to missing tenant scoping")

OUTPUT FORMAT:
Return the roadmap in this exact format:

## Remediation Roadmap

### Wave 1 — Immediate (hours)
Config changes and one-liners that should be deployed today.

| # | Finding | Fix | Effort | Unblocks |
|---|---------|-----|--------|----------|
| 1 | H-01: force_ssl disabled | Set `config.force_ssl = true` in production.rb | 5 min | L-04 (HSTS) |
| 2 | ... | ... | ... | ... |

### Wave 2 — Short-term (days)
Add dependencies, configure middleware, write small services.

| # | Finding | Fix | Effort | Depends On | Unblocks |
|---|---------|-----|--------|------------|----------|
| 1 | H-03: no rate limiting | Add rack-attack gem, configure throttles | 2 hrs | — | — |
| 2 | ... | ... | ... | ... | ... |

### Wave 3 — Medium-term (sprint)
Architectural changes requiring planning and coordination.

| # | Finding | Fix | Effort | Depends On | Unblocks |
|---|---------|-----|--------|------------|----------|
| 1 | C-01: missing authorization framework | Implement Pundit policies for all controllers | 2-3 days | — | H-05, H-06, M-02 |
| 2 | ... | ... | ... | ... | ... |

### Dependency Graph
[Text-based dependency graph showing which fixes feed into others]

Example:
  Wave 1: H-01 (force_ssl) ──> L-04 (HSTS becomes irrelevant)
  Wave 2: H-03 (rack-attack) ──> standalone
  Wave 3: C-01 (Pundit) ──> H-05, H-06, M-02 (all authorization gaps)

### Root Causes
[Group findings that share a common root cause]

| Root Cause | Findings | Single Fix |
|------------|----------|------------|
| No tenant scoping | C-02, H-04, H-07, M-03 | Add ActsAsTenant to ApplicationRecord |
| No authorization framework | H-05, H-06, M-02 | Implement Pundit policies |
```

**Review step:** After the roadmap subagent returns, spawn a review subagent per
the write-then-review pattern. The reviewer checks that wave assignments match
the effort criteria (a config toggle must not be in Wave 3), that dependency
chains are logically sound, and that root cause groupings are accurate. The
reviewer does NOT re-audit findings -- it validates the roadmap's logic.

**Integration into report:** The reviewed roadmap is appended to the report after
the "Domain Compliance Notes" section and before "Categories Audited". It
replaces the need for the reader to manually prioritize -- the waves tell them
what to do Monday morning vs. this sprint vs. next quarter.

**Wave assignment in findings:** Each individual finding in the report gains a
`Wave` field:

```
### [FINDING-ID]: [Title]
- **Severity:** High
- **Wave:** 1 (immediate)
- **Category:** ...
```

The wave assignment comes from the roadmap subagent, not from the category
subagents. The parent agent merges wave assignments into each finding after
the roadmap subagent returns.

### Phase 5: Scan-and-Fix (scan-and-fix mode only)

1. **Create branch:** `security/audit-fixes-YYYY-MM-DD`
   (if exists, append sequence number: `-2`, `-3`, etc.)
2. **Prioritize:** Critical findings first, then High, then Medium.
   Low findings are NOT auto-fixed (reported only).
3. **For each fixable finding:**
   a. Apply the fix from the REMEDIATION field
   b. Run relevant tests if test suite exists
   c. Commit with message: `fix(security): [CWE-ID] short description`
      Include: Category, Severity, Finding ID in commit body
4. **For unfixable findings:** Add `TODO(security)` comments in code
5. **Do NOT open a PR.** Print the branch name and let the user decide.

**What gets auto-fixed:**
- SQL injection (parameterize queries)
- XSS (add output encoding, remove `raw`/`html_safe`)
- Missing CSRF protection
- Insecure cookie flags
- Missing security headers
- Hardcoded secrets (replace with ENV)
- YAML.load → YAML.safe_load
- Missing input validation (add)

**What does NOT get auto-fixed (report only):**
- Authorization architecture redesigns
- Database schema changes
- Dependency upgrades (may have breaking changes)
- Rate limiting setup (infrastructure decisions)
- Encryption implementation (key management decisions)
- Session configuration changes (product decisions)
- Multi-tenancy isolation (architectural)

**Post-fix:** Run test suite if it exists. If tests fail, revert the failing
commit and report it as "fix attempted, test failure, manual intervention
required."

## Error Handling

- If a subagent errors: report the category as ERROR in the audit table,
  continue with other categories
- If tech stack detection fails: default to including ALL categories
- If domain detection is ambiguous: ask the user
- If the report file cannot be written: display the report in the terminal

## Category Reference

| # | File | Items | Category |
|---|------|-------|----------|
| 01 | `checks/01-input-validation.md` | 15 | Input Validation |
| 02 | `checks/02-output-encoding.md` | 10 | Output Encoding |
| 03 | `checks/03-authentication.md` | 10 | Authentication |
| 04 | `checks/04-password-management.md` | 15 | Password Management |
| 05 | `checks/05-session-management.md` | 18 | Session Management |
| 06 | `checks/06-access-control.md` | 20 | Access Control |
| 07 | `checks/07-cryptographic-practices.md` | 16 | Cryptographic Practices |
| 08 | `checks/08-error-handling-logging.md` | 18 | Error Handling & Logging |
| 09 | `checks/09-data-protection.md` | 17 | Data Protection |
| 10 | `checks/10-communication-security.md` | 15 | Communication Security |
| 11 | `checks/11-system-configuration.md` | 20 | System Configuration |
| 12 | `checks/12-database-security.md` | 16 | Database Security |
| 13 | `checks/13-file-management.md` | 15 | File Management |
| 14 | `checks/14-memory-management.md` | 15 | Memory Management |
| | | **210** | **Total checklist items** |

## Domain Profiles

| Domain | File | Auto-detect signals |
|--------|------|---------------------|
| Fintech | `domains/fintech.md` | stripe, plaid, payment, transaction, ledger |
| Healthcare | `domains/healthcare.md` | hipaa, patient, medical, diagnosis, fhir |
| E-commerce | `domains/ecommerce.md` | cart, checkout, product, order, inventory |
| SaaS Multi-Tenant | `domains/saas-multi-tenant.md` | tenant, organization, workspace, ActsAsTenant |
| Custom | `domains/*.md` | User-defined in Detection Signals section |
