# Severity Classification Rubric

Severity is determined by potential IMPACT, not by ease of exploitation.
When in doubt, check the CVSS v4.0 calculator for reference, but use these
practical guidelines for speed.

## Critical (CVSS 9.0-10.0)

**Definition:** Immediate risk of unauthorized access to sensitive data or
systems, with minimal attacker skill required.

**Indicators (any one is sufficient):**
- Remote code execution (RCE)
- SQL injection in authentication or data access paths
- Authentication bypass (access without credentials)
- Hardcoded production credentials or API keys in source code
- Deserialization of untrusted data with code execution
- Unrestricted file upload with server-side execution
- Cross-tenant data access in multi-tenant systems
- Direct access to financial transaction manipulation

**NOT Critical (common over-classifications):**
- Missing security headers (Medium at most)
- Self-XSS that requires victim to paste code (Low)
- Information disclosure of non-sensitive data (Low-Medium)
- Missing rate limiting on non-auth endpoints (Low-Medium)

## High (CVSS 7.0-8.9)

**Definition:** Significant risk that requires attacker interaction or specific
conditions, or moderate impact on confidentiality/integrity.

**Indicators:**
- Stored XSS (persists across sessions)
- IDOR allowing access to other users' non-financial data
- Missing authorization on sensitive (non-critical) endpoints
- JWT without signature verification
- SSRF to internal services
- SQL injection in non-authentication paths
- Insecure password storage (weak algorithm, missing salt)
- Missing brute force protection on login
- CSRF on state-changing operations
- Broken access control (horizontal privilege escalation)
- Missing HTTPS for sensitive data transmission

## Medium (CVSS 4.0-6.9)

**Definition:** Exploitable under specific conditions, or low-impact issues
that affect security posture.

**Indicators:**
- Reflected XSS (requires victim to click a link)
- Missing security headers (CSP, X-Frame-Options)
- Information disclosure in error messages (stack traces, versions)
- Missing input validation that doesn't lead to injection
- Insecure cookie flags (missing Secure/HttpOnly)
- Verbose error messages revealing internal structure
- Session timeout too long
- Missing audit logging
- CORS misconfiguration (overly permissive but not wildcard)
- Missing rate limiting on general API endpoints

## Low (CVSS 0.1-3.9)

**Definition:** Minor issues that improve security posture but pose minimal
immediate risk.

**Indicators:**
- Missing X-Content-Type-Options header
- Server version disclosure
- Missing Referrer-Policy header
- Login error messages revealing username existence
- Missing password complexity feedback
- Non-sensitive information in URL query parameters
- Directory listing enabled (no sensitive content)
- Missing Subresource Integrity (SRI) on CDN resources

## Calibration Examples

| Finding | WRONG Severity | RIGHT Severity | Why |
|---------|---------------|----------------|-----|
| Missing CSRF token on login form | Critical | High | Requires victim interaction, limited scope |
| `params.permit!` in admin controller | Critical | High | Requires admin access, blast radius limited |
| SQL injection in public search | High | Critical | Unauthenticated, full DB access |
| Missing CSP header | High | Medium | Browser defense-in-depth, not primary control |
| Rate limit missing on /health endpoint | Medium | Low | No security-sensitive data or action |
| Hardcoded test API key in seeds.rb | High | Low | Development only, no production impact |
| `YAML.load` with user input | High | Critical | Arbitrary code execution in Ruby |
