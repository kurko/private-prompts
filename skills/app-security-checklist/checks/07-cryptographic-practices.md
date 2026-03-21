# 07 - Cryptographic Practices

## Overview
Verify use of current cryptographic algorithms, proper key management, and
correct implementation of encryption/signing.

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails | `config/credentials.yml.enc`, `app/models/` (encrypts), `lib/` |
| Django | `settings.py`, `crypto/` modules |
| Node | `crypto` usage, `bcrypt`/`argon2` packages, JWT config |
| Go | `crypto/` package usage, TLS config |

## Checklist Items

### CP-01: Weak Encryption Algorithms
- **What to check:** No DES, 3DES, RC4, MD5, SHA1 for security-critical purposes
- **Detection patterns:**
  - Search: `DES|3DES|TripleDES|RC4|RC2` in crypto code
  - Search: `MD5` used for anything other than checksums/cache keys
  - Search: `SHA1` used for signatures or key derivation
  - Search: `Blowfish` (obsolete for new implementations)
  - Search: `createCipher\(` (Node - uses deprecated API, likely weak algo)
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`, `config/**/*`
- **Secure pattern:**
  ```ruby
  # Use AES-256-GCM for encryption
  cipher = OpenSSL::Cipher.new('aes-256-gcm')
  ```
- **Severity:** High
- **CWE:** CWE-327
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-02: Hardcoded Encryption Keys
- **What to check:** No encryption keys, salts, or IVs hardcoded in source
- **Detection patterns:**
  - Search: `aes_key|encryption_key|cipher_key` assigned to string literal
  - Search: `secret.*=.*["'][A-Za-z0-9+/=]{16,}["']` (base64 key in code)
  - Search: `iv\s*=\s*["']` (hardcoded initialization vector)
  - Search: `salt\s*=\s*["']` (hardcoded salt)
  - Search: `ENCRYPTION_KEY|SECRET_KEY` assigned in code (not ENV)
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`, `config/**/*`
- **Secure pattern:**
  ```ruby
  key = ENV.fetch('ENCRYPTION_KEY')
  # Or Rails credentials
  key = Rails.application.credentials.encryption_key
  ```
- **Severity:** Critical
- **CWE:** CWE-321
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-03: Proper Random Number Generation
- **What to check:** Cryptographic randomness used for security-sensitive values
- **Detection patterns:**
  - Search: `rand\(` for tokens, keys, or nonces (Ruby - not cryptographic)
  - Search: `Math\.random\(\)` for any security purpose (JS - not cryptographic)
  - Search: `random\.random\(\)|random\.randint\(` for security (Python - not crypto)
  - Search: `srand` (seeded predictable RNG)
  - Files: `**/*.rb`, `**/*.js`, `**/*.py`, `**/*.go`
- **Secure pattern:**
  ```ruby
  SecureRandom.hex(32)      # Ruby
  SecureRandom.uuid          # Ruby
  ```
  ```javascript
  crypto.randomBytes(32)     // Node
  crypto.randomUUID()        // Node 19+
  ```
  ```python
  import secrets
  secrets.token_hex(32)      # Python
  ```
- **Severity:** High
- **CWE:** CWE-330
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-04: TLS Configuration
- **What to check:** TLS 1.2+ enforced, strong cipher suites, HSTS enabled
- **Detection patterns:**
  - Search: `ssl_version|tls_version|min_version` in server/client config
  - Search: `TLSv1[^.]|TLSv1\.0|TLSv1\.1|SSLv3` (deprecated versions)
  - Search: `Strict-Transport-Security|force_ssl|HSTS` in config
  - Search: `ssl_ciphers|cipher_suites` (check for weak ciphers)
  - Files: `config/environments/production.rb`, `nginx.conf`, `**/*.conf`, `config/puma.rb`
- **Secure pattern:**
  ```ruby
  # Rails
  config.force_ssl = true
  # Nginx
  ssl_protocols TLSv1.2 TLSv1.3;
  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
  ```
- **Severity:** High
- **CWE:** CWE-326
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-05: Key Rotation Capability
- **What to check:** Encryption keys can be rotated without data loss
- **Detection patterns:**
  - Search: key versioning (`key_id|key_version|key_rotation`)
  - Search: `rotate|reencrypt|re_encrypt` methods
  - Search: Rails `config.active_record.encryption.primary_key` (supports rotation)
  - Search: single key without version/ID in encrypted data
  - Files: `app/models/**/*.rb`, `config/**/*.rb`, `lib/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Rails 7+ encryption supports key rotation
  config.active_record.encryption.primary_key = ENV['ENCRYPTION_KEY_V2']
  config.active_record.encryption.deterministic_key = ENV['DET_KEY_V2']
  config.active_record.encryption.key_derivation_salt = ENV['KEY_SALT']
  # Previous keys for decryption
  config.active_record.encryption.previous = [{ primary_key: ENV['ENCRYPTION_KEY_V1'] }]
  ```
- **Severity:** Medium
- **CWE:** CWE-320
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-06: IV/Nonce Reuse
- **What to check:** Initialization vectors and nonces never reused with the same key
- **Detection patterns:**
  - Search: `iv\s*=` with a static/hardcoded value
  - Search: `nonce\s*=` with a static value
  - Search: `cipher\.(encrypt|update)` without generating new IV
  - Search: IV generated outside the encryption function (risk of reuse)
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`
- **Secure pattern:**
  ```ruby
  cipher = OpenSSL::Cipher.new('aes-256-gcm')
  cipher.encrypt
  iv = cipher.random_iv  # Generate fresh IV every time
  ```
- **Severity:** High
- **CWE:** CWE-323
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-07: Padding Oracle
- **What to check:** CBC mode encryption not vulnerable to padding oracle attacks
- **Detection patterns:**
  - Search: `aes.*cbc|cbc` in cipher selection
  - Search: different error messages for bad padding vs bad data
  - Search: `PaddingError|BadPadding|InvalidPadding` in error handling
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`
- **Secure pattern:**
  ```ruby
  # Use GCM mode instead of CBC (authenticated encryption)
  cipher = OpenSSL::Cipher.new('aes-256-gcm')
  ```
- **Severity:** High
- **CWE:** CWE-354
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-08: ECB Mode Usage
- **What to check:** ECB mode not used (it doesn't hide data patterns)
- **Detection patterns:**
  - Search: `aes.*ecb|ECB` in cipher selection
  - Search: `Mode\.ECB|mode=ECB` in crypto config
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`
- **Secure pattern:** Use GCM (preferred) or CBC with HMAC. Never ECB.
- **Severity:** High
- **CWE:** CWE-327
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-09: Key Derivation Functions
- **What to check:** Proper KDFs used when deriving keys from passwords/passphrases
- **Detection patterns:**
  - Search: `PBKDF2|pbkdf2` (acceptable, check iterations >= 600k for SHA-256)
  - Search: `scrypt|argon2` (preferred)
  - Search: raw `SHA256|SHA512` used to derive keys (bad - not a KDF)
  - Search: `Digest::SHA` used for key derivation
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`
- **Secure pattern:**
  ```ruby
  # Use PBKDF2 with sufficient iterations
  key = OpenSSL::KDF.pbkdf2_hmac(password, salt: salt, iterations: 600_000, length: 32, hash: 'sha256')
  ```
- **Severity:** High
- **CWE:** CWE-916
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-10: Certificate Validation
- **What to check:** TLS certificate verification not disabled in HTTP clients
- **Detection patterns:**
  - Search: `verify_ssl.*false|verify_mode.*NONE` (Ruby)
  - Search: `verify=False|verify_ssl=False` (Python)
  - Search: `NODE_TLS_REJECT_UNAUTHORIZED.*0` (Node)
  - Search: `InsecureSkipVerify.*true` (Go)
  - Search: `rejectUnauthorized.*false` (Node)
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`, `.env*`, `config/**/*`
- **Secure pattern:**
  ```ruby
  # Always verify certificates (usually the default)
  Faraday.new(url: api_url, ssl: { verify: true })
  ```
- **Severity:** Critical
- **CWE:** CWE-295
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### CP-11: Certificate Pinning
- **What to check:** Certificate pinning for high-security connections (mobile, financial)
- **Detection patterns:**
  - Search: `pin-sha256|Public-Key-Pins` in headers/config
  - Search: `ssl_pinning|certificate_pinning|pinned_certificates` in mobile code
  - Search: TrustKit or similar pinning library in mobile dependencies
  - Files: `**/*.swift`, `**/*.kt`, `**/*.java`, `config/**/*`
- **Secure pattern:** Pin backup certificates, not just primary. Have a rotation plan.
- **Severity:** Medium (web), High (mobile financial apps)
- **CWE:** CWE-295
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### CP-12: Asymmetric Key Sizes
- **What to check:** RSA keys >= 2048 bits, ECDSA >= 256 bits
- **Detection patterns:**
  - Search: `RSA.*1024|generate_key.*1024` (weak RSA key)
  - Search: `rsa_key_size|key_size|key_length` with values < 2048
  - Search: `generate_rsa.*512|generate_rsa.*768` (dangerously weak)
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`, `config/**/*`
- **Secure pattern:**
  ```ruby
  key = OpenSSL::PKey::RSA.generate(4096)  # At least 2048
  ```
- **Severity:** High
- **CWE:** CWE-326
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-13: Hash Length Extension
- **What to check:** HMAC used instead of plain hash for message authentication
- **Detection patterns:**
  - Search: `SHA256\.hexdigest\(secret \+ |Digest.*secret.*\+` (hash(secret+message))
  - Search: `hashlib\.sha256\(.*secret.*\+` (Python vulnerable pattern)
  - Search: `createHash\(.*secret` without HMAC (Node)
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`
- **Secure pattern:**
  ```ruby
  # Use HMAC, not hash(secret + message)
  OpenSSL::HMAC.hexdigest('SHA256', secret, message)
  ```
- **Severity:** Medium
- **CWE:** CWE-328
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-14: Constant-Time Operations
- **What to check:** Secret comparisons use constant-time algorithms
- **Detection patterns:**
  - Search: `==.*hmac|hmac.*==` (non-constant-time HMAC comparison)
  - Search: `==.*digest|digest.*==` (non-constant-time hash comparison)
  - Search: `==.*signature|signature.*==` (non-constant-time sig comparison)
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`
- **Secure pattern:**
  ```ruby
  ActiveSupport::SecurityUtils.secure_compare(computed_hmac, received_hmac)
  ```
  ```python
  import hmac
  hmac.compare_digest(computed, received)
  ```
- **Severity:** Medium
- **CWE:** CWE-208
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-15: Proper AEAD Usage
- **What to check:** Authenticated encryption (GCM, ChaCha20-Poly1305) used where integrity matters
- **Detection patterns:**
  - Search: `aes.*cbc` without separate HMAC (unauthenticated encryption)
  - Search: encryption without authentication tag verification
  - Search: `cipher\.final` without `auth_tag` check (Ruby GCM)
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`
- **Secure pattern:**
  ```ruby
  # AES-256-GCM provides both confidentiality and integrity
  cipher = OpenSSL::Cipher.new('aes-256-gcm')
  cipher.encrypt
  cipher.key = key
  iv = cipher.random_iv
  cipher.auth_data = associated_data
  encrypted = cipher.update(plaintext) + cipher.final
  tag = cipher.auth_tag
  # Store: iv + tag + encrypted
  ```
- **Severity:** Medium
- **CWE:** CWE-353
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CP-16: Key Storage Separation
- **What to check:** Encryption keys stored separately from encrypted data
- **Detection patterns:**
  - Search: key and encrypted data in same database table
  - Search: `encryption_key` column in same table as encrypted columns
  - Search: key files in application directory (not separate key store)
  - Search: keys in `config/` directory (should be in ENV or KMS)
  - Files: `db/schema.rb`, `config/**/*.rb`, `.env*`, `app/models/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Use environment variables or KMS
  key = ENV.fetch('ENCRYPTION_KEY')
  # Or Rails credentials (encrypted, key separate)
  key = Rails.application.credentials.encryption_key
  # Or cloud KMS
  key = AwsKms.decrypt(ENV['ENCRYPTED_KEY'])
  ```
- **Severity:** High
- **CWE:** CWE-321
- **OWASP Top 10:** A02:2021-Cryptographic Failures
