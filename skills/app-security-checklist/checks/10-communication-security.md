# 10 - Communication Security

## Overview
Verify that all network communications are encrypted and authenticated.
Covers HTTPS enforcement, API security, WebSocket security, and internal
service communication.

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails | `config/environments/production.rb`, `config/initializers/` |
| Django | `settings.py` (SECURE_*), middleware |
| Express/Node | HTTPS setup, `helmet` config, proxy trust |
| Go | `http.ListenAndServeTLS`, TLS config |
| Nginx/Apache | `*.conf` files, SSL directives |

## Checklist Items

### CS-01: HTTP Connections for Sensitive Data
- **What to check:** All sensitive endpoints use HTTPS, HTTP redirects to HTTPS
- **Detection patterns:**
  - Search: `force_ssl` in production config (Rails)
  - Search: `config\.force_ssl\s*=\s*true` (should be present)
  - Search: `SECURE_SSL_REDIRECT\s*=\s*True` (Django)
  - Search: `http://` in API client configurations (should be https://)
  - Files: `config/environments/production.rb`, `settings.py`, `.env*`
- **Secure pattern:**
  ```ruby
  # config/environments/production.rb
  config.force_ssl = true
  ```
- **Severity:** High
- **CWE:** CWE-319
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CS-02: Missing HSTS Headers
- **What to check:** Strict-Transport-Security header with reasonable max-age
- **Detection patterns:**
  - Search: `Strict-Transport-Security` in headers/config
  - Search: `hsts` in config (Rails sets this with force_ssl)
  - Search: `includeSubDomains|preload` HSTS directives
  - Files: `config/environments/production.rb`, `nginx.conf`, `config/initializers/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Rails sets HSTS automatically with force_ssl, but verify max-age
  config.ssl_options = { hsts: { subdomains: true, preload: true, expires: 1.year } }
  ```
- **Severity:** Medium
- **CWE:** CWE-319
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### CS-03: Insecure WebSocket Connections
- **What to check:** WebSocket uses wss:// not ws://, authenticates connections
- **Detection patterns:**
  - Search: `ws://` in client code (should be wss://)
  - Search: `ActionCable|WebSocket|socket\.io` connection config
  - Search: WebSocket connection without authentication
  - Files: `app/javascript/**/*.js`, `app/channels/**/*.rb`, `**/*socket*`
- **Secure pattern:**
  ```javascript
  // Always use wss:// in production
  const ws = new WebSocket(`wss://${window.location.host}/cable`);
  ```
- **Severity:** High
- **CWE:** CWE-319
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CS-04: Certificate Validation Disabled
- **What to check:** TLS certificate verification not disabled in HTTP clients
- **Detection patterns:**
  - Search: `verify_ssl.*false|verify_mode.*NONE` (Ruby)
  - Search: `verify=False|verify_ssl=False` (Python)
  - Search: `NODE_TLS_REJECT_UNAUTHORIZED.*0` (Node env var)
  - Search: `InsecureSkipVerify.*true` (Go)
  - Search: `rejectUnauthorized.*false` (Node)
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.go`, `.env*`
- **Secure pattern:**
  ```ruby
  # Never disable certificate verification in production
  Faraday.new(url: url, ssl: { verify: true })
  ```
- **Severity:** Critical
- **CWE:** CWE-295
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### CS-05: Missing CORS Configuration
- **What to check:** CORS headers restrict origins, don't use wildcard for authenticated endpoints
- **Detection patterns:**
  - Search: `Access-Control-Allow-Origin.*\*` (wildcard origin - dangerous with credentials)
  - Search: `rack-cors|cors` in Gemfile/package.json
  - Search: `origins.*\*|origin.*\*` in CORS config
  - Search: `credentials.*true.*origin.*\*` (wildcard + credentials = vulnerability)
  - Files: `config/initializers/cors.rb`, `package.json`, `middleware/**/*`
- **Secure pattern:**
  ```ruby
  # config/initializers/cors.rb
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins 'https://app.example.com'
      resource '*', headers: :any, methods: [:get, :post, :put, :delete], credentials: true
    end
  end
  ```
- **Severity:** High
- **CWE:** CWE-942
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### CS-06: Internal Service TLS
- **What to check:** Internal service-to-service communication uses TLS
- **Detection patterns:**
  - Search: `http://` URLs for internal services (should be https://)
  - Search: `localhost:` or `127\.0\.0\.1:` with http in service clients
  - Search: internal API base URLs without TLS
  - Files: `app/services/**/*.rb`, `config/**/*.rb`, `.env*`, `docker-compose.yml`
- **Secure pattern:**
  ```ruby
  # Use TLS even for internal services
  INTERNAL_API_URL = ENV.fetch('INTERNAL_API_URL')  # https://internal-api.local
  ```
- **Severity:** Medium
- **CWE:** CWE-319
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CS-07: gRPC Channel Security
- **What to check:** gRPC connections use TLS, not insecure channels
- **Detection patterns:**
  - Search: `insecure_channel|Grpc::Core::Channel` without TLS
  - Search: `grpc\.Dial\(.*grpc\.WithInsecure` (Go insecure gRPC)
  - Search: `grpc\.insecure_channel` (Python)
  - Files: `**/*.rb`, `**/*.py`, `**/*.go`, `**/*.js`
- **Secure pattern:**
  ```go
  conn, err := grpc.Dial(addr, grpc.WithTransportCredentials(credentials.NewTLS(tlsConfig)))
  ```
- **Severity:** High
- **CWE:** CWE-319
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CS-08: Message Queue Encryption
- **What to check:** Messages in queues encrypted if containing sensitive data
- **Detection patterns:**
  - Search: `Sidekiq|ActiveJob|Resque|Celery` job arguments with PII
  - Search: queue connection strings without TLS (`redis://` vs `rediss://`)
  - Search: `amqp://` vs `amqps://` for RabbitMQ
  - Files: `config/sidekiq.yml`, `config/cable.yml`, `.env*`, `app/jobs/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Use TLS for Redis connections
  Sidekiq.configure_server do |config|
    config.redis = { url: ENV['REDIS_TLS_URL'] }  # rediss://
  end
  # Don't pass PII in job arguments - pass IDs and look up in job
  MyJob.perform_later(user_id: user.id)  # Not user.ssn
  ```
- **Severity:** Medium
- **CWE:** CWE-319
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CS-09: Webhook Payload Signing
- **What to check:** Outbound webhooks sign payloads for receiver verification
- **Detection patterns:**
  - Search: `webhook.*send|deliver.*webhook|post.*webhook` in services
  - Search: HMAC signature generation for outbound webhooks
  - Search: `X-Signature|X-Hub-Signature` header in webhook delivery
  - Files: `app/services/**/*webhook*`, `app/models/**/*webhook*`
- **Secure pattern:**
  ```ruby
  def deliver_webhook(url, payload)
    signature = OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, payload.to_json)
    HTTP.headers('X-Signature': "sha256=#{signature}").post(url, json: payload)
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-345
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### CS-10: API Versioning Security
- **What to check:** Deprecated API versions don't bypass newer security controls
- **Detection patterns:**
  - Search: `v1/|api/v1` routes with different auth than current version
  - Search: deprecated API versions without security updates
  - Search: older API versions with less restrictive authorization
  - Files: `config/routes.rb`, `app/controllers/api/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Apply same security controls across API versions
  namespace :api do
    namespace :v1 do
      # Same auth middleware as v2
    end
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-863
- **OWASP Top 10:** A01:2021-Broken Access Control

### CS-11: GraphQL Subscription Auth
- **What to check:** GraphQL subscriptions authenticate WebSocket connections
- **Detection patterns:**
  - Search: `subscription` in GraphQL schema without auth
  - Search: `ActionCableSubscription|graphql-ws` without connection auth
  - Search: subscription resolvers without authorization checks
  - Files: `app/graphql/**/*.rb`, `**/*subscription*`, `**/*schema*`
- **Secure pattern:**
  ```ruby
  class Types::SubscriptionType < Types::BaseObject
    field :message_added, Types::MessageType, null: false do
      argument :channel_id, ID, required: true
    end
    def message_added(channel_id:)
      raise GraphQL::ExecutionError, "Unauthorized" unless context[:current_user]&.member_of?(channel_id)
    end
  end
  ```
- **Severity:** High
- **CWE:** CWE-862
- **OWASP Top 10:** A01:2021-Broken Access Control

### CS-12: SSE Authentication
- **What to check:** Server-Sent Events endpoints authenticate connections
- **Detection patterns:**
  - Search: `text/event-stream|EventSource` without authentication
  - Search: SSE endpoints without session/token verification
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  def stream
    authenticate_user!  # Verify auth before streaming
    response.headers['Content-Type'] = 'text/event-stream'
    # ... stream events
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-862
- **OWASP Top 10:** A01:2021-Broken Access Control

### CS-13: Certificate Pinning for Mobile
- **What to check:** Mobile apps pin server certificates for high-security connections
- **Detection patterns:**
  - Search: `TrustKit|ssl_pinning|CertificatePinner` in mobile code
  - Search: certificate/public key hashes in mobile configuration
  - Files: `**/*.swift`, `**/*.kt`, `**/*.java`, `Info.plist`
- **Secure pattern:** Pin certificate public keys with backup pins. Plan for rotation.
- **Severity:** Medium
- **CWE:** CWE-295
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### CS-14: DNS Security
- **What to check:** DNS configuration prevents hijacking and spoofing
- **Detection patterns:**
  - Search: DNSSEC configuration in infrastructure
  - Search: CAA records limiting certificate issuance
  - Search: SPF/DKIM/DMARC records for email domain
  - Files: `terraform/**/*.tf`, DNS configuration files
- **Secure pattern:** Configure CAA, DNSSEC, SPF, DKIM, and DMARC records.
- **Severity:** Medium
- **CWE:** CWE-350
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### CS-15: Email Transport Security
- **What to check:** Email sent via TLS, SMTP credentials secured
- **Detection patterns:**
  - Search: `smtp_settings|SMTP` configuration
  - Search: `enable_starttls|tls|ssl` in email config
  - Search: `authentication.*plain` without TLS (sends password in clear)
  - Search: SMTP password in source code (should be ENV)
  - Files: `config/environments/production.rb`, `settings.py`, `.env*`
- **Secure pattern:**
  ```ruby
  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_HOST'],
    port: 587,
    enable_starttls_auto: true,
    user_name: ENV['SMTP_USER'],
    password: ENV['SMTP_PASSWORD'],
    authentication: :plain
  }
  ```
- **Severity:** Medium
- **CWE:** CWE-319
- **OWASP Top 10:** A02:2021-Cryptographic Failures
