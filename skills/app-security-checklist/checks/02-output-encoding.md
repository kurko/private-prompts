# 02 - Output Encoding

## Overview
Verify that all output rendered in browsers, APIs, logs, or other consumers
is properly encoded to prevent injection attacks. Output encoding is the
primary defense against XSS.

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails | `app/views/**/*.erb`, `app/helpers/`, `app/javascript/` |
| Django | `templates/**/*.html`, `templatetags/` |
| React/Vue/Angular | `src/**/*.jsx`, `src/**/*.tsx`, `src/**/*.vue` |
| Express | `views/**/*.ejs`, `views/**/*.pug` |

## Checklist Items

### OE-01: Unescaped HTML Output (XSS)
- **What to check:** User data rendered without HTML escaping
- **Detection patterns:**
  - Search: `raw\s` or `\.html_safe` in views/helpers (Rails)
  - Search: `<%==` (Rails unescaped ERB tag)
  - Search: `\|safe` in templates (Django/Jinja2)
  - Search: `mark_safe\(` (Django)
  - Search: `dangerouslySetInnerHTML` (React)
  - Search: `v-html=` (Vue)
  - Search: `\[innerHTML\]=` (Angular)
  - Search: `\!{` or `!=` (Pug/Jade unescaped)
  - Files: `app/views/**/*.erb`, `**/*.html`, `**/*.jsx`, `**/*.tsx`, `**/*.vue`
- **Secure pattern:**
  ```erb
  <%# Rails: default ERB tag auto-escapes %>
  <%= user.name %>
  <%# If raw HTML is needed, sanitize first %>
  <%= sanitize(user.bio, tags: %w[p br strong em]) %>
  ```
- **Severity:** High
- **CWE:** CWE-79
- **OWASP Top 10:** A03:2021-Injection

### OE-02: JavaScript Context Injection
- **What to check:** User data embedded in JavaScript blocks without JS encoding
- **Detection patterns:**
  - Search: `<script>.*#\{` (Ruby interpolation in script tags)
  - Search: `<script>.*\{\{` (template interpolation in script tags)
  - Search: `var.*=.*<%=` (ERB output in JS context)
  - Search: `JSON\.parse\(.*<%=` without `json_escape`
  - Files: `app/views/**/*.erb`, `**/*.html`, `**/*.ejs`
- **Secure pattern:**
  ```erb
  <script>
    var userData = <%= json_escape(user.to_json) %>;
  </script>
  ```
- **Severity:** High
- **CWE:** CWE-79
- **OWASP Top 10:** A03:2021-Injection

### OE-03: URL Context Injection
- **What to check:** User data in href/src attributes allowing javascript: URLs
- **Detection patterns:**
  - Search: `href=["']<%=.*params` (user data in href)
  - Search: `href=.*\{\{.*user` (template data in href)
  - Search: `src=["']<%=.*params` (user data in src)
  - Search: `window\.location\s*=\s*.*params` (JS redirect from params)
  - Files: `app/views/**/*.erb`, `**/*.html`, `**/*.jsx`
- **Secure pattern:**
  ```erb
  <%# Validate URL scheme %>
  <% if url.start_with?('https://') %>
    <a href="<%= url %>">Link</a>
  <% end %>
  ```
- **Severity:** High
- **CWE:** CWE-79
- **OWASP Top 10:** A03:2021-Injection

### OE-04: CSS Context Injection
- **What to check:** User data in style attributes or CSS blocks
- **Detection patterns:**
  - Search: `style=["'].*#\{` (interpolation in inline styles)
  - Search: `style=["'].*\{\{` (template data in inline styles)
  - Search: `<style>.*#\{` (interpolation in style blocks)
  - Files: `app/views/**/*.erb`, `**/*.html`, `**/*.vue`
- **Secure pattern:**
  ```erb
  <%# Use CSS class names, not inline styles from user input %>
  <div class="<%= sanitize_css_class(params[:theme]) %>">
  ```
- **Severity:** Medium
- **CWE:** CWE-79
- **OWASP Top 10:** A03:2021-Injection

### OE-05: Log Injection / Log Forging
- **What to check:** User input written to logs without sanitization
- **Detection patterns:**
  - Search: `logger\.(info|warn|error|debug)\(.*params` (Rails)
  - Search: `console\.log\(.*req\.(body|params|query)` (Node)
  - Search: `logging\.(info|warning|error)\(.*request\.` (Python)
  - Files: `app/controllers/**/*.rb`, `app/services/**/*.rb`, `**/*.js`, `**/*.py`
- **Secure pattern:**
  ```ruby
  # Sanitize newlines to prevent log forging
  Rails.logger.info("User login: #{params[:email].gsub(/[\r\n]/, '')}")
  ```
- **Severity:** Medium
- **CWE:** CWE-117
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### OE-06: Email Header Injection
- **What to check:** User input in email headers (To, CC, BCC, Subject)
- **Detection patterns:**
  - Search: `mail\(to:.*params` or `mail\(subject:.*params` (Rails mailer)
  - Search: `sendMail\(.*req\.` (Node nodemailer with request data)
  - Search: `send_mail\(.*request\.` (Python smtp with request data)
  - Files: `app/mailers/**/*.rb`, `**/*.js`, `**/*.py`
- **Secure pattern:**
  ```ruby
  # Validate email format before using in headers
  raise "Invalid email" unless params[:email].match?(URI::MailTo::EMAIL_REGEXP)
  mail(to: params[:email], subject: "Welcome")
  ```
- **Severity:** Medium
- **CWE:** CWE-93
- **OWASP Top 10:** A03:2021-Injection

### OE-07: API Response Data Leakage
- **What to check:** API responses including sensitive fields not meant for the client
- **Detection patterns:**
  - Search: `\.to_json` or `\.as_json` without `only:` or `except:` filter
  - Search: `render json:.*\.all` (rendering all attributes)
  - Search: `JSON\.stringify\(.*user` without field selection
  - Search: `res\.json\(.*findOne` (returning full DB object)
  - Files: `app/controllers/**/*.rb`, `app/serializers/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  render json: @user.as_json(only: [:id, :name, :email])
  # Or use a serializer
  render json: UserSerializer.new(@user)
  ```
- **Severity:** Medium
- **CWE:** CWE-200
- **OWASP Top 10:** A01:2021-Broken Access Control

### OE-08: Template Injection (SSTI)
- **What to check:** User input used as template content (not template data)
- **Detection patterns:**
  - Search: `ERB\.new\(.*params` (Ruby ERB from user input)
  - Search: `render\s+inline:.*params` (Rails inline render with params)
  - Search: `Template\(.*request\.` (Django template from request)
  - Search: `Liquid::Template\.parse\(.*params` (Liquid template from params)
  - Search: `nunjucks\.renderString\(.*req\.` (Nunjucks from request)
  - Files: `app/controllers/**/*.rb`, `**/*.py`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  # Never use user input as template source
  # Pass user input as template variables instead
  ERB.new(FIXED_TEMPLATE).result_with_hash(name: params[:name])
  ```
- **Severity:** Critical
- **CWE:** CWE-1336
- **OWASP Top 10:** A03:2021-Injection

### OE-09: Content-Type Mismatch
- **What to check:** Responses served with wrong Content-Type allowing content sniffing
- **Detection patterns:**
  - Search: `content_type.*text/html` on non-HTML responses
  - Search: `send_data.*content_type` without `X-Content-Type-Options: nosniff`
  - Search: `res\.send\(` without explicit content type (Node)
  - Files: `app/controllers/**/*.rb`, `config/initializers/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  # Set nosniff header globally
  config.action_dispatch.default_headers['X-Content-Type-Options'] = 'nosniff'
  ```
- **Severity:** Low
- **CWE:** CWE-116
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### OE-10: Markdown/Rich Text Rendering Without Sanitization
- **What to check:** User-submitted markdown or rich text rendered without sanitization
- **Detection patterns:**
  - Search: `markdown\(.*\.body` or `markdown\(.*\.content` without sanitize
  - Search: `marked\(.*user` or `marked\.parse\(` without sanitize option (Node)
  - Search: `ActionText` with custom rendering overrides
  - Files: `app/views/**/*.erb`, `app/helpers/**/*.rb`, `**/*.jsx`, `**/*.tsx`
- **Secure pattern:**
  ```ruby
  # Use a sanitizing markdown renderer
  sanitize(markdown(user.bio), tags: ALLOWED_TAGS)
  ```
- **Severity:** Medium
- **CWE:** CWE-79
- **OWASP Top 10:** A03:2021-Injection
