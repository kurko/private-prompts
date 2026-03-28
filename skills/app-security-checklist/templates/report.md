# Security Audit Report

**Date:** YYYY-MM-DD
**Repository:** [repo name from git remote or directory name]
**Tech Stack:** [detected stack]
**Deployment:** [platform] / TLS: [termination point] / CDN: [cdn or none]
**Domain Profile:** [activated domain or "None"]
**Mode:** [scan | scan-and-fix | category-focus | severity-threshold]

## Executive Summary

| Severity | Count |
|----------|-------|
| Critical | N |
| High     | N |
| Medium   | N |
| Low      | N |
| **Total** | **N** |

[1-3 sentence summary of overall security posture and most urgent issues.]

## STRIDE Threat Assessment

| Threat | Risk Level | Key Factors |
|--------|-----------|-------------|
| Spoofing | HIGH/MEDIUM/LOW | [brief explanation] |
| Tampering | HIGH/MEDIUM/LOW | [brief explanation] |
| Repudiation | HIGH/MEDIUM/LOW | [brief explanation] |
| Information Disclosure | HIGH/MEDIUM/LOW | [brief explanation] |
| Denial of Service | HIGH/MEDIUM/LOW | [brief explanation] |
| Elevation of Privilege | HIGH/MEDIUM/LOW | [brief explanation] |

## Deployment Context

| Attribute | Value |
|-----------|-------|
| Platform | [hosting platform] |
| TLS Termination | [platform-managed / cdn-edge / load-balancer / app-level / unknown] |
| CDN | [cloudflare / fastly / cloudfront / none-detected] |
| Managed Database | [yes / no / unknown] |
| Orchestration | [kubernetes / ecs / docker-compose / none] |
| Confidence | [high / medium / low] — [evidence summary] |

**Severity adjustments applied:** [count] findings had severity adjusted based
on deployment context. [If unknown deployment: "Unknown deployment assumed —
all findings rated as direct exposure."]

## Severity Calibration

[count] findings had their severity adjusted during cross-finding calibration
(Phase 3.5). [count] up, [count] down, [count] compound annotations.

| Finding | Proposed | Final | Reason |
|---------|----------|-------|--------|
| [finding-ID] | [original severity] | [calibrated severity] | [one-line justification] |

[If no adjustments: "All findings passed calibration unchanged."]

## Critical Findings

[Critical findings listed first for immediate attention]

### [FINDING-ID]: [Title]
- **Severity:** Critical
- **Wave:** [1 | 2 | 3] ([immediate | short-term | medium-term])
- **Category:** [OWASP category]
- **CWE:** [CWE-ID]
- **OWASP Top 10:** [mapping]
- **File:** `[path]:[line]`
- **Evidence:**
  ```[language]
  [vulnerable code snippet]
  ```
- **Impact:** [what an attacker could achieve]
- **Remediation:**
  ```[language]
  [fixed code snippet]
  ```

## High Findings

[Same format as Critical]

## Medium Findings

[Same format as Critical]

## Low Findings

[Same format as Critical]

## Domain Compliance Notes

[If domain profile active: compliance mapping, elevated items, domain-specific
findings. If no domain: "No domain profile active."]

## Remediation Roadmap

### Wave 1 -- Immediate (hours)
Config changes and one-liners that should be deployed today.

| # | Finding | Fix | Effort | Unblocks |
|---|---------|-----|--------|----------|
| 1 | [FINDING-ID]: [title] | [one-line fix description] | [estimate] | [finding IDs or "—"] |

### Wave 2 -- Short-term (days)
Add dependencies, configure middleware, write small services.

| # | Finding | Fix | Effort | Depends On | Unblocks |
|---|---------|-----|--------|------------|----------|
| 1 | [FINDING-ID]: [title] | [fix description] | [estimate] | [finding IDs or "—"] | [finding IDs or "—"] |

### Wave 3 -- Medium-term (sprint)
Architectural changes requiring planning and coordination.

| # | Finding | Fix | Effort | Depends On | Unblocks |
|---|---------|-----|--------|------------|----------|
| 1 | [FINDING-ID]: [title] | [fix description] | [estimate] | [finding IDs or "—"] | [finding IDs or "—"] |

### Dependency Graph

```
[Text-based dependency graph showing which fixes feed into others.
Example:
  Wave 1: H-01 (force_ssl) ──> L-04 (HSTS becomes irrelevant)
  Wave 2: H-03 (rack-attack) ──> standalone
  Wave 3: C-01 (Pundit) ──> H-05, H-06, M-02 (all authorization gaps)]
```

### Root Causes

| Root Cause | Findings | Single Fix |
|------------|----------|------------|
| [shared root cause] | [comma-separated finding IDs] | [one fix that addresses all] |

## Categories Audited

| # | Category | Status | Findings |
|---|----------|--------|----------|
| 01 | Input Validation | AUDITED | N findings |
| 02 | Output Encoding | AUDITED | N findings |
| 03 | Authentication | AUDITED | N findings |
| 04 | Password Management | AUDITED | N findings |
| 05 | Session Management | AUDITED | N findings |
| 06 | Access Control | AUDITED | N findings |
| 07 | Cryptographic Practices | AUDITED | N findings |
| 08 | Error Handling & Logging | AUDITED | N findings |
| 09 | Data Protection | AUDITED | N findings |
| 10 | Communication Security | AUDITED | N findings |
| 11 | System Configuration | AUDITED | N findings |
| 12 | Database Security | AUDITED | N findings |
| 13 | File Management | AUDITED | N findings |
| 14 | Memory Management | SKIPPED (GC language) | - |

## Clean Areas

[List of specific areas checked that had no issues, proving thoroughness]

## Reviewed Out

These findings were identified during the audit but removed after independent
review determined they were false positives or unsupported by evidence.

| Original ID | Title | Reviewer Verdict | Reason |
|-------------|-------|------------------|--------|
| [ID] | [title] | REJECTED / ADJUSTED | [reviewer's explanation] |

[If no findings were reviewed out: "All findings survived independent review."]

## Tool Recommendations

[Suggest SAST/SCA/DAST tools for ongoing monitoring based on detected stack]

| Tool | Purpose | Stack | Command |
|------|---------|-------|---------|
| Semgrep | SAST | All | `semgrep --config auto .` |
| Brakeman | SAST | Rails | `brakeman -q` |
| bundle-audit | SCA | Ruby | `bundle audit check --update` |
| npm audit | SCA | Node | `npm audit` |
| Gitleaks | Secrets | All | `gitleaks detect` |
| Trivy | SCA/Container | All | `trivy fs .` |

---

*Generated by app-security-checklist skill*
*Methodology: OWASP Secure Coding Practices + STRIDE + ASVS 5.0*
