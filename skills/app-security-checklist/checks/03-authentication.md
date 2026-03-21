# 03 - Authentication

## Overview
Verify that authentication mechanisms are secure, resist common attacks, and
follow current best practices. This covers login flows, multi-factor auth,
token management, and authentication bypass vectors.

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails/Devise | `config/initializers/devise.rb`, `app/controllers/sessions_controller.rb` |
| Rails/custom | `app/controllers/`, auth-related services |
| Django | `settings.py` (AUTH_PASSWORD_VALIDATORS), `urls.py`, auth views |
| Node/Passport | `config/passport.js`, `routes/auth.js` |
| JWT-based | Token generation, validation, storage, refresh logic |

## Checklist Items

### AU-01: Plaintext Password Storage
- **What to check:** Passwords stored without hashing or with weak hashing
- **Detection patterns:**
  - Search: `password` column in migrations/schema without `_digest` suffix
  - Search: `password.*=.*params` (direct password assignment without hashing)
  - Search: `MD5|SHA1` used for password hashing (weak algorithms)
  - Search: `Digest::` used for passwords (wrong tool - use bcrypt/argon2)
  - Files: `db/migrate/**/*.rb`, `db/schema.rb`, `app/models/user*.rb`, `**/*user*.py`
- **Secure pattern:**
  ```ruby
  # Rails: use has_secure_password (bcrypt)
  class User < ApplicationRecord
    has_secure_password
  end
  # Or Devise (bcrypt by default)
  ```
- **Severity:** Critical
- **CWE:** CWE-256
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### AU-02: Missing Brute Force Protection
- **What to check:** Login endpoints without rate limiting or account lockout
- **Detection patterns:**
  - Search: `authenticate` or `sign_in` in controllers without rate limiting
  - Search: `Rack::Attack` or `rack-attack` in Gemfile (should be present)
  - Search: `Devise.lock_strategy` (should be configured)
  - Search: `express-rate-limit` in package.json (should be present for auth routes)
  - Search: `ratelimit` or `throttle` in auth-related files
  - Files: `config/initializers/rack_attack.rb`, `Gemfile`, `package.json`
- **Secure pattern:**
  ```ruby
  # config/initializers/rack_attack.rb
  Rack::Attack.throttle("logins/ip", limit: 5, period: 60.seconds) do |req|
    req.ip if req.path == "/login" && req.post?
  end
  ```
- **Severity:** High
- **CWE:** CWE-307
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### AU-03: Insecure "Remember Me" Implementation
- **What to check:** Remember-me tokens that are predictable or never expire
- **Detection patterns:**
  - Search: `remember_me` or `remember_token` in models/controllers
  - Search: `cookies\.permanent` with auth tokens (never-expiring auth cookies)
  - Search: `remember_for` config value (should be reasonable, not infinite)
  - Files: `app/models/user*.rb`, `app/controllers/sessions*.rb`, `config/initializers/devise.rb`
- **Secure pattern:**
  ```ruby
  # Devise: set reasonable remember period
  config.remember_for = 2.weeks
  config.extend_remember_period = false
  ```
- **Severity:** Medium
- **CWE:** CWE-613
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### AU-04: JWT Vulnerabilities
- **What to check:** JWT tokens with weak signing, missing validation, or insecure storage
- **Detection patterns:**
  - Search: `algorithm.*none` or `alg.*none` (algorithm none attack)
  - Search: `verify.*false` in JWT decode calls
  - Search: `HS256` with shared secrets (prefer RS256 for distributed systems)
  - Search: `localStorage.*token` or `sessionStorage.*token` (XSS-accessible storage)
  - Search: `jwt\.decode\(.*verify=False` (Python JWT without verification)
  - Search: `JWT\.decode\(.*algorithms:` (check if algorithms list is restrictive)
  - Files: `app/services/**/*.rb`, `lib/**/*.rb`, `**/*.js`, `**/*.py`, `config/initializers/**/*.rb`
- **Secure pattern:**
  ```ruby
  JWT.decode(token, secret, true, { algorithm: 'HS256' })  # verify=true, explicit algorithm
  ```
  ```javascript
  // Store in httpOnly cookie, not localStorage
  res.cookie('token', jwt, { httpOnly: true, secure: true, sameSite: 'strict' });
  ```
- **Severity:** Critical (algorithm none), High (other issues)
- **CWE:** CWE-347
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### AU-05: OAuth/OIDC Implementation Flaws
- **What to check:** OAuth flows with missing state parameter, open redirect, or token leakage
- **Detection patterns:**
  - Search: `state` parameter in OAuth callback handling (must be verified)
  - Search: `redirect_uri` validation (must be strict, not substring match)
  - Search: `omniauth` config without `provider_ignores_state` check
  - Search: `PKCE` or `code_verifier` (should be present for public clients)
  - Files: `config/initializers/omniauth.rb`, `app/controllers/omniauth_callbacks*.rb`, `routes/auth*.js`
- **Secure pattern:**
  ```ruby
  # Verify state parameter in OAuth callback
  raise "Invalid state" unless session[:oauth_state] == params[:state]
  ```
- **Severity:** High
- **CWE:** CWE-352
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### AU-06: Credential Exposure in Error Messages
- **What to check:** Login errors revealing whether username or password is wrong
- **Detection patterns:**
  - Search: `"Invalid username"` or `"User not found"` (reveals user existence)
  - Search: `"Invalid password"` or `"Wrong password"` (reveals user exists)
  - Search: `"No account"` or `"Email not registered"` (reveals registration status)
  - Files: `app/controllers/sessions*.rb`, `app/views/**/*login*`, `**/*auth*.js`
- **Secure pattern:**
  ```ruby
  flash[:error] = "Invalid email or password"  # Generic message
  ```
- **Severity:** Low
- **CWE:** CWE-204
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### AU-07: Missing Multi-Factor Authentication Support
- **What to check:** Sensitive applications without MFA option
- **Detection patterns:**
  - Search: `otp` or `totp` or `two_factor` in models/controllers
  - Search: `devise-two-factor` or `rotp` in Gemfile
  - Search: `speakeasy` or `otplib` in package.json
  - Files: `Gemfile`, `package.json`, `app/models/user*.rb`
- **Secure pattern:** MFA support should exist for any app handling sensitive data
- **Severity:** Medium (general apps), High (fintech/healthcare)
- **CWE:** CWE-308
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### AU-08: Session Fixation on Login
- **What to check:** Session ID not regenerated after successful authentication
- **Detection patterns:**
  - Search: `reset_session` near authentication logic (should be present)
  - Search: `session\.regenerate` or `req\.session\.regenerate` (Node)
  - Search: custom session controllers without session reset
  - Files: `app/controllers/sessions*.rb`, `routes/auth*.js`
- **Secure pattern:**
  ```ruby
  def create
    reset_session  # Prevent session fixation
    @user = authenticate(params[:email], params[:password])
    session[:user_id] = @user.id
  end
  ```
- **Severity:** High
- **CWE:** CWE-384
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### AU-09: API Key Management
- **What to check:** API keys without rotation, revocation, or scoping
- **Detection patterns:**
  - Search: `api_key` or `api_token` in models (check for expiry/rotation fields)
  - Search: `SecureRandom` for key generation (good, but check storage)
  - Search: API key comparison using `==` instead of constant-time compare
  - Files: `app/models/**/*.rb`, `app/controllers/api/**/*.rb`, `db/migrate/**/*.rb`
- **Secure pattern:**
  ```ruby
  class ApiKey < ApplicationRecord
    has_secure_token :token
    scope :active, -> { where("expires_at > ?", Time.current) }

    def self.authenticate(token)
      key = find_by(token_digest: Digest::SHA256.hexdigest(token))
      key if key&.active?
    end
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-798
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### AU-10: Timing Attack on Authentication
- **What to check:** String comparison for passwords/tokens using `==` instead of constant-time
- **Detection patterns:**
  - Search: `==.*password` or `password.*==` (non-constant-time comparison)
  - Search: `==.*token` or `token.*==` (non-constant-time comparison)
  - Search: `===.*secret` or `secret.*===` (JS triple equals is still timing-vulnerable)
  - Files: `app/models/**/*.rb`, `app/controllers/**/*.rb`, `lib/**/*.rb`, `**/*.js`
- **Secure pattern:**
  ```ruby
  ActiveSupport::SecurityUtils.secure_compare(provided_token, stored_token)
  ```
  ```javascript
  const crypto = require('crypto');
  crypto.timingSafeEqual(Buffer.from(a), Buffer.from(b));
  ```
- **Severity:** Medium
- **CWE:** CWE-208
- **OWASP Top 10:** A02:2021-Cryptographic Failures
