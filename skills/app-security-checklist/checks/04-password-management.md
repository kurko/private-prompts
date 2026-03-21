# 04 - Password Management

## Overview
Verify password policies, storage, reset flows, and change mechanisms follow
current NIST SP 800-63B guidelines (not outdated complexity rules).

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails/Devise | `config/initializers/devise.rb`, `app/models/user*.rb` |
| Rails/custom | `app/models/`, `app/controllers/passwords_controller.rb` |
| Django | `settings.py` (AUTH_PASSWORD_VALIDATORS), `contrib.auth` |
| Node/Passport | `config/passport.js`, password-related routes and models |

## Checklist Items

### PM-01: Password Minimum Length
- **What to check:** Minimum 8 characters enforced (NIST recommends 8+, max at least 64)
- **Detection patterns:**
  - Search: `validates.*password.*length` (Ruby model validation)
  - Search: `minimum.*password|password.*minimum` in config
  - Search: `config\.password_length` (Devise)
  - Search: `MinimumLengthValidator` (Django)
  - Search: `minlength.*password|password.*minlength` (JS)
  - Files: `app/models/user*.rb`, `config/initializers/devise.rb`, `settings.py`
- **Secure pattern:**
  ```ruby
  validates :password, length: { minimum: 8, maximum: 128 }
  # Devise
  config.password_length = 8..128
  ```
- **Severity:** High
- **CWE:** CWE-521
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-02: Password Storage Algorithm
- **What to check:** bcrypt, scrypt, or Argon2id with appropriate cost factor
- **Detection patterns:**
  - Search: `has_secure_password` (Rails bcrypt - good)
  - Search: `bcrypt|argon2|scrypt` in Gemfile/package.json (good)
  - Search: `PBKDF2` (acceptable but not preferred)
  - Search: `MD5|SHA1|SHA256` used for passwords (bad - not a KDF)
  - Search: `Digest::` for password hashing (bad)
  - Search: `bcrypt.*cost|rounds|work_factor` (check cost factor >= 12)
  - Files: `Gemfile`, `package.json`, `app/models/user*.rb`, `settings.py`
- **Secure pattern:**
  ```ruby
  # Rails: has_secure_password uses bcrypt with cost 12 by default
  class User < ApplicationRecord
    has_secure_password
  end
  # Or explicitly set cost
  BCrypt::Engine.cost = 12
  ```
- **Severity:** Critical
- **CWE:** CWE-916
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### PM-03: Breached Password Check
- **What to check:** Passwords checked against known breach databases (HaveIBeenPwned API)
- **Detection patterns:**
  - Search: `pwned|hibp|breach|compromised` in password validation
  - Search: `devise-pwned_password` in Gemfile
  - Search: `haveibeenpwned|pwnedpasswords` in dependencies
  - Files: `Gemfile`, `package.json`, `app/models/user*.rb`, `app/validators/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Gemfile: gem 'devise-pwned_password'
  class User < ApplicationRecord
    devise :pwned_password
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-521
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-04: Password Reset Token Security
- **What to check:** Time-limited, single-use, cryptographically random reset tokens
- **Detection patterns:**
  - Search: `reset_password_token` generation logic
  - Search: `SecureRandom|crypto\.randomBytes` in reset flow (good)
  - Search: `rand\(|Math\.random` in reset flow (bad - not cryptographic)
  - Search: `reset_password_sent_at` or expiry check in reset validation
  - Search: `token.*expire|expire.*token` in reset flow
  - Files: `app/models/user*.rb`, `app/controllers/password*`, `app/mailers/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Devise handles this well by default
  # Custom: use SecureRandom and expire tokens
  def generate_reset_token
    self.reset_token = SecureRandom.urlsafe_base64(32)
    self.reset_token_expires_at = 2.hours.from_now
    save!
  end
  ```
- **Severity:** High
- **CWE:** CWE-640
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-05: Password Reset Flow Information Leakage
- **What to check:** Reset flow doesn't reveal whether email exists
- **Detection patterns:**
  - Search: `email not found|no account|user not found|not registered` in reset flow
  - Search: different responses for found vs not-found emails in reset controller
  - Files: `app/controllers/password*`, `app/views/**/*reset*`, `routes/auth*.js`
- **Secure pattern:**
  ```ruby
  # Always show the same message
  flash[:notice] = "If that email exists, we've sent reset instructions."
  ```
- **Severity:** Low
- **CWE:** CWE-204
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-06: Password Change Requires Current Password
- **What to check:** Password update endpoint requires current password verification
- **Detection patterns:**
  - Search: `update_password|change_password` in controllers
  - Search: `current_password` parameter in password update action
  - Search: `authenticate` call before password change
  - Files: `app/controllers/**/*password*`, `app/controllers/**/*account*`
- **Secure pattern:**
  ```ruby
  def update_password
    unless @user.authenticate(params[:current_password])
      render :edit, alert: "Current password is incorrect"
      return
    end
    @user.update(password: params[:new_password])
  end
  ```
- **Severity:** High
- **CWE:** CWE-620
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-07: No Password Hints
- **What to check:** No password hints or security questions stored
- **Detection patterns:**
  - Search: `password_hint|security_question|security_answer` in schema/models
  - Search: `hint` column associated with user/password models
  - Files: `db/schema.rb`, `db/migrate/**/*.rb`, `app/models/user*.rb`
- **Secure pattern:** Do not store password hints. Use email-based reset instead.
- **Severity:** Medium
- **CWE:** CWE-640
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-08: No Knowledge-Based Recovery
- **What to check:** No "mother's maiden name" or similar knowledge-based auth recovery
- **Detection patterns:**
  - Search: `security_question|secret_question|recovery_question` in models
  - Search: `maiden|pet_name|first_car|birth_city` in schema
  - Files: `db/schema.rb`, `app/models/user*.rb`, `db/migrate/**/*.rb`
- **Secure pattern:** Use email/SMS-based account recovery, not knowledge-based questions.
- **Severity:** Medium
- **CWE:** CWE-640
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-09: Password History
- **What to check:** Users cannot reuse recent passwords
- **Detection patterns:**
  - Search: `password_history|previous_password|old_password` in models
  - Search: `devise.*password_archivable` or password history gems
  - Files: `app/models/user*.rb`, `Gemfile`, `db/migrate/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Store hashed previous passwords and check before update
  # gem 'devise-security' provides password_archivable
  ```
- **Severity:** Low
- **CWE:** CWE-521
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-10: Credential Stuffing Protection
- **What to check:** Login endpoint protected against automated credential stuffing attacks
- **Detection patterns:**
  - Search: `Rack::Attack|rack-attack` throttling on login (Ruby)
  - Search: `express-rate-limit|rate-limiter` on auth routes (Node)
  - Search: CAPTCHA integration on login (`recaptcha|hcaptcha|turnstile`)
  - Search: `devise.*lockable` configuration
  - Files: `config/initializers/rack_attack.rb`, `Gemfile`, `package.json`
- **Secure pattern:**
  ```ruby
  # Combine rate limiting with account lockout
  Rack::Attack.throttle("logins/email", limit: 5, period: 300) do |req|
    req.params.dig("user", "email") if req.path == "/login" && req.post?
  end
  ```
- **Severity:** High
- **CWE:** CWE-307
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-11: Password Strength Feedback
- **What to check:** Users get feedback on password strength during creation
- **Detection patterns:**
  - Search: `zxcvbn|password-strength|password_strength` in dependencies
  - Search: password strength meter in registration views/components
  - Files: `package.json`, `Gemfile`, `app/views/**/*registration*`, `**/*signup*`
- **Secure pattern:**
  ```javascript
  // Use zxcvbn for realistic password strength estimation
  import zxcvbn from 'zxcvbn';
  const result = zxcvbn(password);
  if (result.score < 3) showWarning(result.feedback.suggestions);
  ```
- **Severity:** Low
- **CWE:** CWE-521
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-12: No Maximum Length Below 64
- **What to check:** Password max length allows at least 64 characters (NIST)
- **Detection patterns:**
  - Search: `maximum.*password` with value < 64
  - Search: `maxlength.*password|password.*maxlength` with value < 64
  - Search: `VARCHAR.*password` with length < 72 in migrations (bcrypt truncates at 72)
  - Files: `app/models/user*.rb`, `config/initializers/devise.rb`, `db/migrate/**/*.rb`
- **Secure pattern:**
  ```ruby
  validates :password, length: { minimum: 8, maximum: 128 }
  ```
- **Severity:** Medium
- **CWE:** CWE-521
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-13: No Composition Rules (NIST)
- **What to check:** No forced complexity rules (uppercase, number, special char requirements)
- **Detection patterns:**
  - Search: `password.*[A-Z]|password.*[0-9]|password.*special` in validation
  - Search: `must contain.*uppercase|must contain.*number|must contain.*special`
  - Search: password format validators with character class requirements
  - Files: `app/models/user*.rb`, `app/validators/**/*.rb`, `**/*password*`
- **Secure pattern:**
  ```ruby
  # NIST 800-63B: Check length and breach status, NOT composition
  validates :password, length: { minimum: 8 }
  # Add breach check, remove complexity requirements
  ```
- **Severity:** Low
- **CWE:** CWE-521
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-14: No Periodic Rotation Requirement (NIST)
- **What to check:** No forced periodic password expiration (NIST discourages this)
- **Detection patterns:**
  - Search: `password_expires|password_expiry|password_age|force_change` in models
  - Search: `devise.*expire_password_after` or similar expiry config
  - Search: `password.*expired|expired.*password` in controllers
  - Files: `app/models/user*.rb`, `config/initializers/devise.rb`, `db/migrate/**/*.rb`
- **Secure pattern:** Only force password change after confirmed breach, not on a schedule.
- **Severity:** Low
- **CWE:** CWE-262
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### PM-15: Secure Password Display Toggle
- **What to check:** Password fields have show/hide toggle, default to hidden
- **Detection patterns:**
  - Search: `type="password"` with toggle mechanism in views
  - Search: `showPassword|togglePassword|password-toggle` in JS/components
  - Search: `autocomplete="new-password"` on registration (good)
  - Search: `autocomplete="current-password"` on login (good)
  - Files: `app/views/**/*login*`, `app/views/**/*registration*`, `**/*auth*.jsx`
- **Secure pattern:**
  ```html
  <input type="password" autocomplete="current-password" id="password">
  <button type="button" onclick="togglePasswordVisibility()">Show</button>
  ```
- **Severity:** Low
- **CWE:** CWE-549
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures
