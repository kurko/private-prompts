# Shared Assessment Criteria

## Severity Scale

All findings use a 4-tier scale plus an "Open Question" category:

| Tier | Label | Meaning | Example |
|------|-------|---------|---------|
| 1 | **Red Flag** | Potential blocker for integration | No idempotency on payment endpoints; POST doesn't return an ID for async ops |
| 2 | **Concern** | Problem but workable; affects architecture | Poor error messages but errors exist; multiple incompatible error formats |
| - | **Open Question** | Information not publicly available; not necessarily a problem | Rate limits not documented; pricing not public; changelog absent |
| 3 | **Adequate** | Meets minimum expectations | Standard pagination; basic error codes; sandbox available but limited |
| 4 | **Strong** | Above average; reduces integration risk | Comprehensive OpenAPI spec; detailed error taxonomy; HMAC webhooks with retries |

### Distinguishing "Concern" from "Open Question"

- **Concern**: The feature/behavior exists but is problematic (e.g., two incompatible error formats, idempotency returns 400 instead of original response).
- **Open Question**: The information is simply not public. It might be fine once we ask (e.g., rate limits may be generous but undocumented, pricing is shared during sales). Don't conflate "not documented" with "doesn't exist" or "is bad."

### Confidence Indicator

Every finding MUST include a confidence level:
- **High**: Direct quote or explicit documentation found. You can link to the exact page.
- **Medium**: Inferred from related documentation, error codes, or indirect evidence.
- **Low**: Based on absence of documentation, a single indirect reference, or a page that was SPA-rendered and couldn't be fully accessed.

### Severity Escalation Rules

Sub-agents must use these baseline tiers. If escalating above baseline, explicitly state: "Escalated from [baseline] to [actual] because [reason]."

| Signal | Baseline Tier |
|--------|--------------|
| Rate limits undocumented | Open Question |
| Changelog missing | Open Question |
| No error documentation at all | Red Flag |
| Poor/inconsistent errors but they exist | Concern |
| No idempotency on financial endpoints | Red Flag |
| Idempotency exists but non-standard behavior | Concern |
| No sandbox | Red Flag |
| No batch/bulk API (prepaid cards vendor) | Red Flag |
| No batch/bulk API (all other vendors) | Concern |
| Manual-only onboarding | Red Flag |
| POST doesn't return ID for async ops | Red Flag |
| Webhook IP list not published | Not a finding (HMAC signing is sufficient) |

## Universal API Quality Criteria

These are evaluated in BOTH quick and deep modes.

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
- Note: Most API docs have poor clarity on errors; grade the severity but ensure they exist at minimum

### Async Flow Resilience
- POST requests return an ID for later retrieval?
- GET endpoint exists to poll for results (webhook fallback)?
- **Red Flag if**: POST doesn't return ID; no GET fallback for async operations
- Anti-pattern example: Compliancely doesn't return IDs that can be used to query their API later

### Webhook System
- Event catalog completeness
- Retry policy documented? How many retries? Backoff strategy?
- Signature/HMAC verification mechanism?
- Delivery guarantees (at-least-once, exactly-once)?
- **Concern if**: No retry policy or signature verification documented

### Rate Limits
- Documented on the website?
- Per-endpoint or global?
- Response headers for rate limit status?
- **Open Question if**: Undocumented rate limits (not a Concern or Red Flag -- many vendors share this during onboarding)

### Sandbox / Testing Environment
- Available?
- Parity with production?
- Test data generation?
- Ease of setup (self-service vs vendor interaction)?
- **Red Flag if**: No sandbox environment at all

### Versioning
- URL vs header versioning?
- Deprecation policy?
- Breaking change communication?
- **Concern if**: No versioning strategy documented

### Auth & Security
- Auth mechanism: API key vs OAuth vs HMAC vs other
- Token rotation mechanism
- IP allowlisting support
- Environment separation (sandbox vs production keys/endpoints)
- Permission scoping for API keys

### Documentation Quality
- Complete endpoint coverage
- Code samples (multiple languages?)
- OpenAPI/Swagger spec available for download
- Up-to-date (no stale references or broken links)
- Changelog published and maintained
  - **Open Question if**: No changelog (a documentation gap, not an integration blocker)
- Getting started guide quality
- SPA rendering: were doc pages accessible via WebFetch or did they require JavaScript?

### KYB / KYC
- Onboarding flow: programmatic or manual?
- Verification requirements clear?
- **Red Flag if**: Manual-only onboarding process with no API
- Check: AML/sanctions screening capabilities
- Check: Compliance certifications mentioned (SOC2, PCI-DSS, etc.)
- Note: Regulatory reporting obligations (SAR/STR) differ by jurisdiction. Flag if unclear, but note the jurisdictional context (US FinCEN vs EU MiCA vs UK FCA).

### Webhook Security
- If HMAC/signature verification exists, that is sufficient for webhook security.
- Do NOT flag "no published webhook source IP list" as a finding. Tremendous does not whitelist vendor IPs; signature verification is the security mechanism.
