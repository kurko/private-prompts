# 09 - Data Protection

## Overview
Verify that sensitive data is protected at rest, in transit, and in use.
Covers PII handling, data classification, and privacy controls.

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails | `app/models/` (encrypts), `config/credentials.yml.enc`, `.env*` |
| Django | `settings.py`, model fields, `DATABASES` config |
| Node | `.env*`, `config/`, model definitions, `crypto` usage |
| Go | Config files, `os.Getenv`, model structs |

## Checklist Items

### DP-01: PII in Plain Text
- **What to check:** Sensitive fields encrypted at rest (SSN, credit card, health data)
- **Detection patterns:**
  - Search: `ssn|social_security|tax_id` columns without encryption
  - Search: `credit_card|card_number|cvv|cvc` columns without encryption
  - Search: `date_of_birth|dob` stored as plain column (may need encryption per policy)
  - Search: `encrypts` in models (Rails 7+ - good)
  - Search: `attr_encrypted` gem usage (good)
  - Files: `db/schema.rb`, `db/migrate/**/*.rb`, `app/models/**/*.rb`
- **Secure pattern:**
  ```ruby
  class User < ApplicationRecord
    encrypts :ssn, :date_of_birth
    encrypts :email, deterministic: true  # Allows querying
  end
  ```
- **Severity:** Critical (fintech/healthcare), High (general)
- **CWE:** CWE-311
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### DP-02: Secrets in Source Code
- **What to check:** No API keys, passwords, or tokens hardcoded in source
- **Detection patterns:**
  - Search: `api_key\s*=\s*["'][A-Za-z0-9]` (hardcoded API key)
  - Search: `password\s*=\s*["'][^"']+["']` (hardcoded password)
  - Search: `secret\s*=\s*["'][A-Za-z0-9]` (hardcoded secret)
  - Search: `token\s*=\s*["'][A-Za-z0-9]` (hardcoded token)
  - Search: `AKIA[0-9A-Z]{16}` (AWS access key pattern)
  - Search: `sk_live_|pk_live_|sk_test_` (Stripe keys)
  - Search: `ghp_[A-Za-z0-9]{36}` (GitHub personal access token)
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`, `config/**/*`
- **Secure pattern:**
  ```ruby
  api_key = ENV.fetch('STRIPE_API_KEY')
  # Or Rails credentials
  api_key = Rails.application.credentials.stripe[:api_key]
  ```
- **Severity:** Critical
- **CWE:** CWE-798
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### DP-03: Secrets in Version Control History
- **What to check:** No committed secrets in git history
- **Detection patterns:**
  - Search: `.env` files in git tracking (should be in .gitignore)
  - Search: `credentials.yml` (unencrypted) in git
  - Search: known secret patterns in recent git diff history
  - Tool: Run `gitleaks detect` if available
  - Files: `.gitignore` (verify .env* is listed)
- **Secure pattern:**
  ```bash
  # .gitignore must include:
  .env*
  *.pem
  *.key
  config/master.key
  ```
- **Severity:** Critical
- **CWE:** CWE-540
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### DP-04: Missing Data-at-Rest Encryption
- **What to check:** Database encryption, file system encryption for sensitive data
- **Detection patterns:**
  - Search: `encrypts` in models (Rails 7+ column encryption)
  - Search: `attr_encrypted|crypt_keeper` gems in Gemfile
  - Search: database-level encryption configuration
  - Search: encrypted file storage (S3 SSE, GCS CMEK)
  - Files: `app/models/**/*.rb`, `Gemfile`, `config/storage.yml`, `config/database.yml`
- **Secure pattern:**
  ```ruby
  # Rails 7+ built-in encryption
  class Patient < ApplicationRecord
    encrypts :diagnosis, :medication
  end
  ```
- **Severity:** High
- **CWE:** CWE-311
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### DP-05: Unprotected Backups
- **What to check:** Database backups encrypted, backup credentials secured
- **Detection patterns:**
  - Search: `pg_dump|mysqldump|mongodump` in scripts without encryption
  - Search: backup storage configuration (S3 bucket policy, encryption setting)
  - Search: backup credentials in plain text
  - Files: `bin/*`, `lib/tasks/**/*.rake`, `scripts/**/*`, `Makefile`
- **Secure pattern:**
  ```bash
  # Encrypt backups
  pg_dump $DATABASE_URL | gpg --encrypt --recipient backup@example.com > backup.sql.gpg
  # Or use S3 SSE
  aws s3 cp backup.sql s3://backups/ --sse aws:kms
  ```
- **Severity:** High
- **CWE:** CWE-311
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### DP-06: Data Masking in Non-Production
- **What to check:** Production PII not used in development/staging without masking
- **Detection patterns:**
  - Search: database seed/dump scripts that copy production data
  - Search: `production.*dump|dump.*production` in scripts
  - Search: data masking/anonymization tools in dev setup
  - Files: `bin/*`, `lib/tasks/**/*.rake`, `scripts/**/*`, `db/seeds.rb`
- **Secure pattern:**
  ```ruby
  # Use faker gem for seed data, not production copies
  User.create!(name: Faker::Name.name, email: Faker::Internet.email)
  ```
- **Severity:** Medium
- **CWE:** CWE-200
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### DP-07: PII in Caches
- **What to check:** Cached data doesn't contain unencrypted PII
- **Detection patterns:**
  - Search: `Rails\.cache\.write.*user|Rails\.cache\.fetch.*user` with PII
  - Search: `cache.*ssn|cache.*credit_card|cache.*password`
  - Search: Redis caching of user objects without field filtering
  - Files: `app/controllers/**/*.rb`, `app/models/**/*.rb`, `app/services/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Cache non-sensitive data only, or encrypt cached PII
  Rails.cache.fetch("user_#{id}_profile") { user.as_json(only: [:id, :name]) }
  ```
- **Severity:** Medium
- **CWE:** CWE-524
- **OWASP Top 10:** A04:2021-Insecure Design

### DP-08: Data Retention and Deletion
- **What to check:** Data retention policies implemented, old data purged
- **Detection patterns:**
  - Search: `destroy_all|delete_all` in scheduled tasks for old data
  - Search: data retention rake tasks or cron jobs
  - Search: `created_at.*ago|older_than` in cleanup queries
  - Files: `lib/tasks/**/*.rake`, `app/jobs/**/*.rb`, `config/schedule.rb`
- **Secure pattern:**
  ```ruby
  # Scheduled data cleanup
  class DataRetentionJob < ApplicationJob
    def perform
      AuditLog.where("created_at < ?", 2.years.ago).delete_all
      Session.where("expires_at < ?", 30.days.ago).delete_all
    end
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-459
- **OWASP Top 10:** A04:2021-Insecure Design

### DP-09: Right to Deletion (GDPR)
- **What to check:** User data deletion/export capability exists for GDPR compliance
- **Detection patterns:**
  - Search: `delete_account|destroy_account|gdpr|right_to_forget` in controllers
  - Search: user data export endpoint
  - Search: cascade deletion of user's associated data
  - Files: `app/controllers/**/*.rb`, `app/models/user*.rb`, `config/routes.rb`
- **Secure pattern:**
  ```ruby
  class AccountDeletionService
    def call(user)
      user.orders.update_all(user_id: nil, email: '[deleted]')
      user.comments.destroy_all
      user.destroy!
      AuditLog.create!(action: :account_deleted, user_email_hash: Digest::SHA256.hexdigest(user.email))
    end
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-459
- **OWASP Top 10:** A04:2021-Insecure Design

### DP-10: Data Export Controls
- **What to check:** Bulk data exports restricted and logged
- **Detection patterns:**
  - Search: `export|download.*csv|download.*xlsx` without authorization
  - Search: API endpoints returning unbounded result sets
  - Search: `limit|pagination` missing on data listing endpoints
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  def export
    authorize :report, :export?
    @data = policy_scope(Record).limit(10_000)
    AuditLog.create!(user: current_user, action: :data_export, count: @data.count)
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-200
- **OWASP Top 10:** A01:2021-Broken Access Control

### DP-11: Cross-Border Data Transfer
- **What to check:** Data residency requirements met for regulated data
- **Detection patterns:**
  - Search: cloud storage region configuration
  - Search: CDN configuration for data-serving regions
  - Search: `region|availability_zone|data_center` in infrastructure config
  - Files: `config/storage.yml`, `terraform/**/*.tf`, `docker-compose.yml`
- **Secure pattern:** Configure storage and compute in required regions. Document data flows.
- **Severity:** Medium (regulatory)
- **CWE:** CWE-200
- **OWASP Top 10:** A04:2021-Insecure Design

### DP-12: Sensitive Data in URLs
- **What to check:** Sensitive data not in URL query strings (logged by servers/proxies)
- **Detection patterns:**
  - Search: `token=|api_key=|password=|secret=` in URL construction
  - Search: `redirect_to.*token|redirect_to.*key` with query params
  - Search: GET requests with sensitive parameters
  - Files: `app/controllers/**/*.rb`, `app/views/**/*.erb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  # Use POST for sensitive data, or request headers
  # Bad: redirect_to confirm_path(token: @token)
  # Good: Use session or signed cookie for token
  ```
- **Severity:** Medium
- **CWE:** CWE-598
- **OWASP Top 10:** A04:2021-Insecure Design

### DP-13: Browser Caching of Sensitive Pages
- **What to check:** Pages with sensitive data have cache-control headers
- **Detection patterns:**
  - Search: `Cache-Control|no-store|no-cache` in sensitive page responses
  - Search: `cache_control` usage in controllers handling PII
  - Search: sensitive pages without `Pragma: no-cache`
  - Files: `app/controllers/**/*.rb`, `config/environments/production.rb`
- **Secure pattern:**
  ```ruby
  # For pages with sensitive data
  response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate'
  response.headers['Pragma'] = 'no-cache'
  ```
- **Severity:** Low
- **CWE:** CWE-525
- **OWASP Top 10:** A04:2021-Insecure Design

### DP-14: Clipboard Security
- **What to check:** Sensitive data cleared from clipboard after use
- **Detection patterns:**
  - Search: `clipboard|navigator\.clipboard|execCommand.*copy` with sensitive data
  - Search: copy-to-clipboard for tokens/passwords without auto-clear
  - Files: `**/*.js`, `**/*.jsx`, `**/*.tsx`, `**/*.vue`
- **Secure pattern:**
  ```javascript
  // Auto-clear clipboard after copying sensitive data
  navigator.clipboard.writeText(apiKey);
  setTimeout(() => navigator.clipboard.writeText(''), 30000);
  ```
- **Severity:** Low
- **CWE:** CWE-200
- **OWASP Top 10:** A04:2021-Insecure Design

### DP-15: Data Classification Labels
- **What to check:** Data models have classification (public, internal, confidential, restricted)
- **Detection patterns:**
  - Search: `classification|data_class|sensitivity` in models
  - Search: comments or annotations indicating data sensitivity
  - Search: `PUBLIC|INTERNAL|CONFIDENTIAL|RESTRICTED` constants for data types
  - Files: `app/models/**/*.rb`, `db/schema.rb`
- **Secure pattern:** Document data classification. Apply encryption based on classification level.
- **Severity:** Low
- **CWE:** CWE-200
- **OWASP Top 10:** A04:2021-Insecure Design

### DP-16: Temporary File Cleanup
- **What to check:** Temporary files with sensitive data cleaned up after use
- **Detection patterns:**
  - Search: `Tempfile|tmp/|mktemp` creation without cleanup/ensure block
  - Search: `File\.open.*tmp` without deletion in ensure
  - Search: `fs\.writeFileSync.*tmp` without cleanup (Node)
  - Files: `app/services/**/*.rb`, `lib/**/*.rb`, `**/*.js`
- **Secure pattern:**
  ```ruby
  Tempfile.create('report') do |f|
    f.write(sensitive_data)
    f.rewind
    process(f)
  end  # Auto-deleted when block exits
  ```
- **Severity:** Low
- **CWE:** CWE-459
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### DP-17: Data Minimization
- **What to check:** Only necessary data collected and stored
- **Detection patterns:**
  - Search: user registration collecting excessive fields
  - Search: database columns that appear unused (no references in code)
  - Search: logging of full request bodies with unnecessary data
  - Files: `app/models/user*.rb`, `db/schema.rb`, `app/views/**/*registration*`
- **Secure pattern:** Collect only what's needed. Review schema periodically for unused columns.
- **Severity:** Low
- **CWE:** CWE-200
- **OWASP Top 10:** A04:2021-Insecure Design
