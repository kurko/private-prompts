# 11 - System Configuration

## Overview
Verify that server, framework, and infrastructure configurations follow
security hardening guidelines.

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails | `config/environments/production.rb`, `config/initializers/` |
| Django | `settings.py`, `wsgi.py`, `asgi.py` |
| Express/Node | `app.js`, `server.js`, `helmet` config |
| Go | `main.go`, server config |
| Infrastructure | `Dockerfile`, `docker-compose.yml`, `nginx.conf`, `terraform/` |

## Checklist Items

### SC-01: Debug Mode in Production
- **What to check:** Debug/development mode disabled in production
- **Detection patterns:**
  - Search: `consider_all_requests_local\s*=\s*true` in production.rb
  - Search: `DEBUG\s*=\s*True` in production settings (Django)
  - Search: `NODE_ENV` not set to `production` in deploy config
  - Search: `GIN_MODE` not set to `release` (Go Gin)
  - Files: `config/environments/production.rb`, `settings.py`, `.env.production`, `Dockerfile`
- **Secure pattern:**
  ```ruby
  config.consider_all_requests_local = false
  ```
- **Severity:** High
- **CWE:** CWE-489
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-02: Default Credentials
- **What to check:** No default admin passwords, database passwords, or API keys
- **Detection patterns:**
  - Search: `password.*password|password.*123|password.*admin` in config
  - Search: `admin.*admin|root.*root` in seed files or config
  - Search: `changeme|default|example|test123` in credential fields
  - Files: `config/**/*.rb`, `db/seeds.rb`, `.env*`, `docker-compose.yml`
- **Secure pattern:** All credentials from ENV or secrets manager. No defaults.
- **Severity:** Critical
- **CWE:** CWE-798
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### SC-03: Unnecessary Services Enabled
- **What to check:** Unused endpoints, admin panels, debug endpoints disabled in prod
- **Detection patterns:**
  - Search: `/admin|/debug|/swagger|/graphiql|/sidekiq` routes
  - Search: `mount.*Sidekiq|mount.*LetterOpener|mount.*Rswag` without auth
  - Search: `web-console|better_errors` in production Gemfile group
  - Files: `config/routes.rb`, `Gemfile`, `package.json`
- **Secure pattern:**
  ```ruby
  # Protect admin panels
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
  # Move debug gems to development group
  group :development do
    gem 'web-console'
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-1188
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-04: Security Headers Missing
- **What to check:** CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy set
- **Detection patterns:**
  - Search: `Content-Security-Policy` in response headers config
  - Search: `X-Frame-Options` configuration
  - Search: `X-Content-Type-Options` configuration
  - Search: `Referrer-Policy` configuration
  - Search: `Permissions-Policy` (formerly Feature-Policy)
  - Search: `helmet` in package.json (Node - sets headers automatically)
  - Files: `config/initializers/**/*.rb`, `config/environments/production.rb`, `nginx.conf`
- **Secure pattern:**
  ```ruby
  # config/initializers/content_security_policy.rb
  Rails.application.configure do
    config.content_security_policy do |policy|
      policy.default_src :self
      policy.script_src :self
      policy.style_src :self, :unsafe_inline
    end
  end
  # Default headers
  config.action_dispatch.default_headers = {
    'X-Frame-Options' => 'SAMEORIGIN',
    'X-Content-Type-Options' => 'nosniff',
    'Referrer-Policy' => 'strict-origin-when-cross-origin',
    'Permissions-Policy' => 'camera=(), microphone=(), geolocation=()'
  }
  ```
- **Severity:** Medium
- **CWE:** CWE-693
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-05: Outdated Dependencies with Known CVEs
- **What to check:** No dependencies with known CVEs
- **Detection patterns:**
  - Search: `bundler-audit|bundle-audit` in CI pipeline (Ruby)
  - Search: `npm audit|yarn audit` in CI pipeline (Node)
  - Search: `pip-audit|safety` in CI pipeline (Python)
  - Search: `govulncheck` in CI pipeline (Go)
  - Tool: Run `bundle audit check --update` or `npm audit`
  - Files: `Gemfile.lock`, `package-lock.json`, `.github/workflows/**/*.yml`
- **Secure pattern:**
  ```yaml
  # CI pipeline step
  - name: Security audit
    run: bundle audit check --update
  ```
- **Severity:** Varies (depends on CVE)
- **CWE:** CWE-1104
- **OWASP Top 10:** A06:2021-Vulnerable and Outdated Components

### SC-06: Directory Listing
- **What to check:** Directory listing disabled on web server
- **Detection patterns:**
  - Search: `autoindex on` (Nginx directory listing)
  - Search: `Options.*Indexes` (Apache directory listing)
  - Search: `serveIndex|serve-index` (Node express)
  - Files: `nginx.conf`, `.htaccess`, `server.js`
- **Secure pattern:**
  ```nginx
  autoindex off;
  ```
- **Severity:** Low
- **CWE:** CWE-548
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-07: Server Version Exposure
- **What to check:** Server version headers removed
- **Detection patterns:**
  - Search: `Server:` header configuration
  - Search: `server_tokens` in Nginx config (should be off)
  - Search: `ServerSignature` in Apache config (should be Off)
  - Search: `x-powered-by` header (Express - should be removed)
  - Files: `nginx.conf`, `.htaccess`, `app.js`
- **Secure pattern:**
  ```nginx
  server_tokens off;
  ```
  ```javascript
  app.disable('x-powered-by');
  ```
- **Severity:** Low
- **CWE:** CWE-200
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-08: Error Page Configuration
- **What to check:** Custom error pages configured for 404, 500, etc.
- **Detection patterns:**
  - Search: custom error pages in `public/` (Rails)
  - Search: `error_page` in Nginx config
  - Search: `ErrorDocument` in Apache config
  - Search: custom error handler middleware (Node)
  - Files: `public/404.html`, `public/500.html`, `nginx.conf`
- **Secure pattern:** Generic error pages that reveal no internal details.
- **Severity:** Low
- **CWE:** CWE-209
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-09: File Permissions
- **What to check:** Application files have restrictive permissions
- **Detection patterns:**
  - Search: `chmod 777|chmod 666|chmod.*o+w` in scripts/Docker
  - Search: world-readable configuration files
  - Search: writable directories beyond tmp/log
  - Files: `Dockerfile`, `bin/*`, `scripts/**/*`
- **Secure pattern:**
  ```dockerfile
  # Restrictive permissions in Docker
  RUN chmod 600 config/master.key
  RUN chmod -R 755 public/
  ```
- **Severity:** Medium
- **CWE:** CWE-732
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-10: Temp Directory Security
- **What to check:** Temporary directories scoped and cleaned
- **Detection patterns:**
  - Search: `Dir\.tmpdir|/tmp/` usage in application code
  - Search: predictable temp file names
  - Search: temp files without cleanup
  - Files: `app/services/**/*.rb`, `lib/**/*.rb`, `**/*.js`
- **Secure pattern:**
  ```ruby
  Dir.mktmpdir('myapp-') do |dir|
    # Auto-cleaned when block exits
  end
  ```
- **Severity:** Low
- **CWE:** CWE-377
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-11: Environment Variable Validation
- **What to check:** Required environment variables validated at boot
- **Detection patterns:**
  - Search: `ENV\[` without fetch or default (may silently be nil)
  - Search: `ENV\.fetch` (good - raises on missing)
  - Search: env validation on application startup
  - Files: `config/application.rb`, `config/environments/**/*.rb`, `.env.example`
- **Secure pattern:**
  ```ruby
  # Validate at boot
  %w[DATABASE_URL SECRET_KEY_BASE REDIS_URL].each do |key|
    raise "Missing required env var: #{key}" unless ENV[key].present?
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-1188
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-12: Secrets Management
- **What to check:** Secrets stored in vault/KMS, not environment files
- **Detection patterns:**
  - Search: `vault|aws-kms|google-kms|azure-keyvault` in dependencies
  - Search: secrets loaded from files vs environment
  - Search: `.env` files committed to git
  - Files: `Gemfile`, `package.json`, `.gitignore`, `config/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Use Rails credentials (encrypted, key separate)
  Rails.application.credentials.stripe_api_key
  # Or vault
  Vault.logical.read('secret/data/app')
  ```
- **Severity:** Medium
- **CWE:** CWE-522
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### SC-13: Container Security
- **What to check:** Containers run as non-root with read-only filesystem
- **Detection patterns:**
  - Search: `USER` directive in Dockerfile (should not be root)
  - Search: `--privileged` in docker-compose
  - Search: `read_only: true` in docker-compose (good)
  - Search: `security_opt|cap_drop` in container config
  - Files: `Dockerfile`, `docker-compose.yml`, `k8s/**/*.yml`
- **Secure pattern:**
  ```dockerfile
  FROM ruby:3.2-slim
  RUN useradd -m appuser
  USER appuser
  ```
- **Severity:** Medium
- **CWE:** CWE-250
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-14: CI/CD Pipeline Security
- **What to check:** CI/CD pipelines use pinned actions, secrets not exposed in logs
- **Detection patterns:**
  - Search: `uses:.*@master|uses:.*@main` (unpinned GitHub Actions)
  - Search: `echo.*SECRET|echo.*TOKEN` in CI scripts
  - Search: `--build-arg.*SECRET` in Docker builds
  - Search: `::set-output` with secrets
  - Files: `.github/workflows/**/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`
- **Secure pattern:**
  ```yaml
  uses: actions/checkout@v4  # Pin to specific version
  # Use GitHub secrets, not inline values
  env:
    API_KEY: ${{ secrets.API_KEY }}
  ```
- **Severity:** Medium
- **CWE:** CWE-798
- **OWASP Top 10:** A08:2021-Software and Data Integrity Failures

### SC-15: Infrastructure-as-Code Security
- **What to check:** IaC templates don't have insecure defaults
- **Detection patterns:**
  - Search: `0\.0\.0\.0/0` in security groups (overly permissive)
  - Search: `public.*true|PubliclyAccessible.*true` in RDS/storage config
  - Search: `encrypted.*false` in storage/database config
  - Files: `terraform/**/*.tf`, `cloudformation/**/*.yml`, `k8s/**/*.yml`
- **Secure pattern:**
  ```hcl
  resource "aws_security_group_rule" "app" {
    type        = "ingress"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["10.0.0.0/8"]  # Internal only
  }
  ```
- **Severity:** High
- **CWE:** CWE-1188
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-16: DNS Configuration
- **What to check:** DNS records don't point to decommissioned resources (subdomain takeover)
- **Detection patterns:**
  - Search: CNAME records pointing to unclaimed cloud resources
  - Search: DNS records for decommissioned services
  - Files: `terraform/**/*.tf`, DNS zone files
- **Secure pattern:** Audit DNS records regularly. Remove records for decommissioned services.
- **Severity:** Medium
- **CWE:** CWE-350
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-17: CDN Security Headers
- **What to check:** CDN passes through security headers, doesn't strip them
- **Detection patterns:**
  - Search: CDN configuration for header passthrough
  - Search: CloudFront/Cloudflare security header configuration
  - Files: `terraform/**/*.tf`, CDN config files
- **Secure pattern:** Configure CDN to add/pass security headers at edge.
- **Severity:** Low
- **CWE:** CWE-693
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-18: Monitoring and Alerting
- **What to check:** Application monitoring catches security anomalies
- **Detection patterns:**
  - Search: `sentry|bugsnag|rollbar|datadog|newrelic` in dependencies
  - Search: error tracking configuration
  - Search: uptime monitoring configuration
  - Files: `Gemfile`, `package.json`, `config/initializers/**/*.rb`
- **Secure pattern:** Deploy error tracking (Sentry), APM (Datadog/New Relic), and uptime monitoring.
- **Severity:** Low
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### SC-19: Backup Configuration
- **What to check:** Automated backups configured with retention and testing
- **Detection patterns:**
  - Search: backup configuration in infrastructure code
  - Search: backup scripts in bin/scripts directories
  - Search: backup testing/restoration procedures
  - Files: `terraform/**/*.tf`, `bin/*`, `scripts/**/*`
- **Secure pattern:** Automated daily backups with 30-day retention. Test restoration quarterly.
- **Severity:** Medium
- **CWE:** CWE-530
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### SC-20: Disaster Recovery
- **What to check:** DR plan exists and is tested
- **Detection patterns:**
  - Search: multi-region configuration in infrastructure
  - Search: failover configuration in load balancer/database
  - Search: DR documentation
  - Files: `terraform/**/*.tf`, `docs/**/*`, `README.md`
- **Secure pattern:** Document and test DR procedures. Automate failover where possible.
- **Severity:** Low
- **CWE:** CWE-693
- **OWASP Top 10:** A05:2021-Security Misconfiguration
