# 08 - Error Handling & Logging

## Overview
Verify that error handling doesn't leak sensitive information and that security-
relevant events are logged for monitoring and forensics.

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails | `config/environments/`, `app/controllers/`, `config/initializers/` |
| Django | `settings.py` (DEBUG, LOGGING), middleware, error views |
| Express/Node | Error middleware, `winston`/`pino` config, error handlers |
| Go | Error handling patterns, `log` package usage, middleware |

## Checklist Items

### EH-01: Stack Trace Exposure in Production
- **What to check:** Detailed errors not shown to users in production
- **Detection patterns:**
  - Search: `config\.consider_all_requests_local\s*=\s*true` in production.rb (Rails)
  - Search: `DEBUG\s*=\s*True` in production settings (Django)
  - Search: `NODE_ENV.*development|NODE_ENV.*undefined` in production (Node)
  - Search: `full_message|backtrace|stacktrace` in rendered responses
  - Files: `config/environments/production.rb`, `settings.py`, `.env.production`
- **Secure pattern:**
  ```ruby
  # config/environments/production.rb
  config.consider_all_requests_local = false
  config.action_dispatch.show_exceptions = :all
  ```
- **Severity:** Medium
- **CWE:** CWE-209
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### EH-02: Sensitive Data in Error Messages
- **What to check:** Errors don't include passwords, tokens, internal paths
- **Detection patterns:**
  - Search: `rescue.*render.*params` (rendering request data in error)
  - Search: `rescue.*render.*exception\.message` (raw exception to user)
  - Search: `res\.status\(500\)\.send\(err` (Node sending raw error)
  - Search: `traceback\.format_exc` in response rendering (Python)
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`, `**/*.py`
- **Secure pattern:**
  ```ruby
  rescue StandardError => e
    Rails.logger.error("Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    render json: { error: "An internal error occurred" }, status: 500
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-209
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### EH-03: Missing Security Event Logging
- **What to check:** Login attempts, auth failures, access denials are logged
- **Detection patterns:**
  - Search: `sign_in|authenticate|login` without associated log statement
  - Search: `unauthorized|forbidden|access_denied` without logging
  - Search: `Warden.*after_authentication` callbacks (Devise hooks)
  - Files: `app/controllers/**/*.rb`, `config/initializers/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Log all authentication events
  Warden::Manager.after_authentication do |user, auth, opts|
    Rails.logger.info("AUTH_SUCCESS user=#{user.id} ip=#{auth.request.remote_ip}")
  end
  Warden::Manager.before_failure do |env, opts|
    Rails.logger.warn("AUTH_FAILURE ip=#{env['REMOTE_ADDR']} scope=#{opts[:scope]}")
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-04: Sensitive Data in Logs
- **What to check:** Passwords, tokens, PII not written to logs
- **Detection patterns:**
  - Search: `filter_parameters` config (Rails - should include password, token, secret)
  - Search: `config\.filter_parameters` (check completeness)
  - Search: `logger.*password|logger.*token|logger.*secret|logger.*ssn`
  - Search: `console\.log.*password|console\.log.*token` (Node)
  - Files: `config/initializers/filter_parameter_logging.rb`, `app/**/*.rb`, `**/*.js`
- **Secure pattern:**
  ```ruby
  # config/initializers/filter_parameter_logging.rb
  Rails.application.config.filter_parameters += [
    :password, :password_confirmation, :token, :secret,
    :api_key, :ssn, :credit_card, :cvv
  ]
  ```
- **Severity:** High
- **CWE:** CWE-532
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-05: Missing Audit Trail
- **What to check:** Critical data changes are logged with who/what/when
- **Detection patterns:**
  - Search: `audited|paper_trail|logidze` gems in Gemfile (good)
  - Search: `has_paper_trail|audited` in models
  - Search: audit logging in sensitive operations (payment, role change, delete)
  - Files: `Gemfile`, `app/models/**/*.rb`, `app/services/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Use paper_trail or audited gem
  class User < ApplicationRecord
    has_paper_trail
  end
  ```
- **Severity:** Medium (High for fintech/healthcare)
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-06: Catch-All Exception Handlers
- **What to check:** Broad rescue/catch blocks that swallow security exceptions
- **Detection patterns:**
  - Search: `rescue\s*$|rescue Exception` without re-raising (Ruby)
  - Search: `rescue.*=>.*e\s*$` (catching and ignoring)
  - Search: `catch\s*\(` without error handling logic (JS)
  - Search: `except:$|except Exception` without re-raising (Python)
  - Files: `app/controllers/**/*.rb`, `app/services/**/*.rb`, `**/*.js`, `**/*.py`
- **Secure pattern:**
  ```ruby
  # Catch specific exceptions, not all
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Not found" }, status: 404
  rescue ActionController::ParameterMissing => e
    render json: { error: "Missing parameter: #{e.param}" }, status: 422
  # Let other exceptions propagate to error monitoring
  ```
- **Severity:** Medium
- **CWE:** CWE-755
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### EH-07: Error Page Information Disclosure
- **What to check:** Custom error pages don't reveal framework, version, or config
- **Detection patterns:**
  - Search: custom 404/500 error pages exist
  - Search: `public/404.html|public/500.html` (Rails - should be customized)
  - Search: default framework error pages in use
  - Files: `public/*.html`, `app/views/errors/`, `**/*error*page*`
- **Secure pattern:**
  ```ruby
  # Custom error pages that reveal nothing
  # public/500.html - generic "Something went wrong" page
  ```
- **Severity:** Low
- **CWE:** CWE-209
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### EH-08: Logging Injection
- **What to check:** User input in logs sanitized to prevent log injection/forging
- **Detection patterns:**
  - Search: `logger\.(info|warn|error).*params\[` without sanitization
  - Search: `logger.*#\{params` (Ruby interpolation of params in logs)
  - Search: `console\.log.*req\.(body|params)` (Node logging raw input)
  - Files: `app/controllers/**/*.rb`, `app/services/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  # Strip newlines and control characters from logged user input
  safe_input = user_input.gsub(/[\r\n\t]/, ' ').truncate(200)
  Rails.logger.info("Search query: #{safe_input}")
  ```
- **Severity:** Medium
- **CWE:** CWE-117
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-09: Log Integrity Protection
- **What to check:** Logs cannot be tampered with by application users
- **Detection patterns:**
  - Search: log files writable by application user
  - Search: logs stored only locally without remote backup
  - Search: log rotation configuration
  - Files: `config/environments/**/*.rb`, `log/`, `docker-compose.yml`
- **Secure pattern:** Ship logs to centralized logging service (CloudWatch, Datadog, ELK).
- **Severity:** Low
- **CWE:** CWE-117
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-10: Centralized Logging
- **What to check:** Logs aggregated to central platform for correlation
- **Detection patterns:**
  - Search: `lograge|logstash|fluentd|datadog|cloudwatch|sentry` in dependencies
  - Search: log shipping configuration in infrastructure
  - Search: structured logging format (JSON logs)
  - Files: `Gemfile`, `package.json`, `config/initializers/**/*.rb`, `docker-compose.yml`
- **Secure pattern:**
  ```ruby
  # Use lograge for structured logging
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  ```
- **Severity:** Low
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-11: Alert Thresholds for Security Events
- **What to check:** Automated alerts for suspicious activity patterns
- **Detection patterns:**
  - Search: `alert|notification|threshold` in security monitoring config
  - Search: Sentry/Datadog/PagerDuty integration for security events
  - Search: rate-based alerting on auth failures
  - Files: `config/initializers/**/*.rb`, `.github/workflows/**/*.yml`, `docker-compose.yml`
- **Secure pattern:** Configure alerts for: 5+ auth failures/minute, admin access from new IP, bulk data export.
- **Severity:** Low
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-12: Log Retention Policy
- **What to check:** Logs retained long enough for forensics but not indefinitely
- **Detection patterns:**
  - Search: log rotation/retention configuration
  - Search: `rotate|retention|keep|expire` in log config
  - Search: compliance-required retention periods (HIPAA: 6 years, PCI: 1 year)
  - Files: `config/**/*.rb`, `logrotate.conf`, `docker-compose.yml`
- **Secure pattern:** Retain security logs for at least 90 days, full logs for 30 days.
- **Severity:** Low
- **CWE:** CWE-779
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-13: Correlation IDs
- **What to check:** Request correlation IDs for tracing across services
- **Detection patterns:**
  - Search: `correlation_id|request_id|trace_id|X-Request-Id` in middleware/logging
  - Search: `config\.log_tags` (Rails tagged logging)
  - Search: request ID propagation in service clients
  - Files: `app/controllers/application_controller.rb`, `config/environments/**/*.rb`
- **Secure pattern:**
  ```ruby
  config.log_tags = [:request_id]
  # Propagate in service calls
  headers['X-Request-Id'] = request.request_id
  ```
- **Severity:** Low
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-14: Failed Authorization Logging
- **What to check:** All authorization failures logged with context
- **Detection patterns:**
  - Search: `Pundit::NotAuthorizedError|CanCan::AccessDenied` rescue without logging
  - Search: `403|forbidden` responses without log entry
  - Search: authorization check failures silently returning false
  - Files: `app/controllers/application_controller.rb`, `app/controllers/**/*.rb`
- **Secure pattern:**
  ```ruby
  rescue Pundit::NotAuthorizedError => e
    Rails.logger.warn("AUTHZ_DENIED user=#{current_user&.id} action=#{e.query} record=#{e.record.class}##{e.record.id}")
    head :forbidden
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-15: Data Export Logging
- **What to check:** Bulk data exports and downloads logged
- **Detection patterns:**
  - Search: `export|download|csv|xlsx|pdf` actions without audit logging
  - Search: `send_data|send_file` without logging who downloaded what
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  def export
    AuditLog.create!(user: current_user, action: :export, resource: "users", count: @users.count)
    send_data @users.to_csv, filename: "users_export.csv"
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-16: Admin Action Logging
- **What to check:** All admin actions logged with before/after state
- **Detection patterns:**
  - Search: admin controllers without audit logging
  - Search: `Admin::` or `admin/` controllers without action logging
  - Search: role changes, user management actions without logging
  - Files: `app/controllers/admin/**/*.rb`, `routes/admin/**/*.js`
- **Secure pattern:**
  ```ruby
  class Admin::BaseController < ApplicationController
    after_action :log_admin_action
    def log_admin_action
      AuditLog.create!(admin: current_user, action: action_name, controller: controller_name, params: filtered_params)
    end
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-17: API Rate Limit Logging
- **What to check:** Rate limit violations logged for abuse detection
- **Detection patterns:**
  - Search: `Rack::Attack.*throttle` without `ActiveSupport::Notifications` subscription
  - Search: rate limit middleware without logging
  - Search: `429` responses without logging context
  - Files: `config/initializers/rack_attack.rb`, `middleware/**/*`
- **Secure pattern:**
  ```ruby
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
    Rails.logger.warn("RATE_LIMITED ip=#{payload[:request].ip} path=#{payload[:request].path}")
  end
  ```
- **Severity:** Low
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### EH-18: Configuration Change Logging
- **What to check:** Runtime configuration changes logged
- **Detection patterns:**
  - Search: settings/config update endpoints without audit logging
  - Search: feature flag changes without logging
  - Search: `Flipper|feature_flag.*update|settings.*update` without audit
  - Files: `app/controllers/admin/**/*.rb`, `app/controllers/**/*settings*`
- **Secure pattern:**
  ```ruby
  def update_setting
    old_value = Setting.find(params[:id]).value
    @setting.update!(value: params[:value])
    AuditLog.create!(user: current_user, action: :config_change, details: { key: @setting.key, old: old_value, new: params[:value] })
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures
