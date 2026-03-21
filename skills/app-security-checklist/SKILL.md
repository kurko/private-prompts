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
2. **STRIDE-informed context injection.** Before subagents launch, the parent
   performs a lightweight threat model. Each subagent receives the relevant threat
   categories.
3. **Tech stack awareness.** Categories irrelevant to the detected stack are
   skipped entirely.
4. **Domain-specific amplification.** Built-in profiles (fintech, healthcare,
   e-commerce, SaaS/multi-tenant) activate additional checks within relevant
   categories.

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
   section relevant to this category
3. Read `templates/subagent-prompt.md` — this is the prompt template
4. Read `templates/severity-rubric.md` — inject into the subagent prompt
5. Construct the subagent prompt by filling in the template:
   - Replace `[CATEGORY_NAME]` with the category name
   - Replace `[detected stack]` with Phase 0 results
   - Replace `[injected STRIDE assessment]` with Phase 1 results
   - Replace `[domain name]` and domain notes
   - Insert the full checklist file contents
   - Insert the full severity rubric contents
6. Spawn the subagent

**Critical:** Spawn ALL subagents in parallel. Do NOT run them sequentially.

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

### Phase 3: Domain-Specific Checks

If a domain profile is active:
1. Check for domain-specific requirements not covered by the 14 categories
2. Elevate severity of findings per the domain's Severity Elevations table
3. Add compliance mapping (PCI DSS numbers, HIPAA rules, etc.)

### Phase 4: Report Synthesis

Collect all subagent findings and produce the final report:
1. De-duplicate findings that span multiple categories
2. Sort by severity (Critical first)
3. Add executive summary with finding counts
4. Add the STRIDE assessment
5. Add domain compliance notes (if applicable)
6. Write the report to `tmp/security-audit-YYYY-MM-DD.md`
7. If severity-threshold mode: filter the report but note filtered counts

Use `templates/report.md` as the output format template.

Display the report path and finding summary to the user.

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
