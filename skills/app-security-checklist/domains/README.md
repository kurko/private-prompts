# Custom Domain Profiles

Add domain-specific security profiles by creating markdown files in this
directory. The orchestrator loads any `.md` file (except this README) and
applies it alongside the built-in profiles.

## File Format

Follow the same structure as built-in profiles:

```markdown
# [Your Domain] Security Profile

## Compliance Framework
[Applicable regulations]

## Detection Signals
Keywords that trigger auto-detection: `keyword1`, `keyword2`, `keyword3`

## Severity Elevations
| Item | Standard Severity | Domain Severity | Reason |
|------|-------------------|-----------------|--------|
| [checklist item ID] | [standard] | [elevated] | [why] |

## Additional Checks

### [DOMAIN-ID]: [Check Title]
- **What to check:** [description]
- **Detection patterns:**
  - Search: `[grep pattern]`
  - Files: `[glob pattern]`
- **Secure pattern:** [code example]
- **Severity:** [Critical|High|Medium|Low]
```

## Naming Convention

Use kebab-case: `government-fedramp.md`, `gaming-compliance.md`, etc.

## Activation

Custom profiles activate when:
1. The user specifies the domain name (e.g., "security audit for a government app")
2. Auto-detection finds 3+ matching signals from the `Detection Signals` section
   in the codebase
