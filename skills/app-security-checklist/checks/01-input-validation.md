# 01 - Input Validation

## Overview
Verify that all input from external sources is validated, sanitized, and
constrained before processing. Input validation is the first line of defense
against injection attacks, buffer overflows, and business logic abuse.

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails | `app/controllers/`, `app/models/` (strong params, validations) |
| Django | `views.py`, `forms.py`, `serializers.py` |
| Express/Node | `routes/`, `middleware/`, `controllers/` |
| Go | `handlers/`, `api/` |
| Spring | `@RequestMapping` controllers, `@Valid` annotations |

## Checklist Items

### IV-01: SQL Injection via String Interpolation
- **What to check:** Raw SQL queries built with string interpolation or concatenation
- **Detection patterns:**
  - Search: `where\s*\(?\s*["'].*#\{` (Ruby string interpolation in where clauses)
  - Search: `where\s*\(?\s*["'].*\+\s*` (string concatenation in where clauses)
  - Search: `execute\s*\(?\s*["'].*#\{` (raw execute with interpolation)
  - Search: `\.query\s*\(\s*["'\x60].*\$\{` (JS template literal in SQL)
  - Search: `cursor\.execute\s*\(\s*f["']` (Python f-string in SQL)
  - Search: `fmt\.Sprintf.*SELECT` (Go fmt in SQL)
  - Files: `app/models/**/*.rb`, `app/controllers/**/*.rb`, `**/*.py`, `**/*.go`
  - Code pattern (vulnerable):
    ```ruby
    User.where("name = '#{params[:name]}'")
    ```
  - Code pattern (vulnerable):
    ```javascript
    db.query(`SELECT * FROM users WHERE id = ${req.params.id}`)
    ```
- **Secure pattern:**
  ```ruby
  User.where(name: params[:name])
  User.where("name = ?", params[:name])
  ```
  ```javascript
  db.query('SELECT * FROM users WHERE id = $1', [req.params.id])
  ```
- **Severity:** Critical
- **CWE:** CWE-89
- **OWASP Top 10:** A03:2021-Injection

### IV-02: Command Injection
- **What to check:** System/exec calls with user-controlled input
- **Detection patterns:**
  - Search: `system\s*\(.*params` (Ruby system call with params)
  - Search: `exec\s*\(.*params` (Ruby exec with params)
  - Search: `` \`.*#\{.*params`` (Ruby backtick with params)
  - Search: `child_process\.exec\(.*req\.` (Node child_process with request data)
  - Search: `subprocess\.(call|run|Popen)\(.*request\.` (Python subprocess with request)
  - Search: `os\.system\(.*request\.` (Python os.system with request)
  - Search: `exec\.Command\(.*r\.(Form|URL|Body)` (Go exec with request)
  - Files: `**/*.rb`, `**/*.py`, `**/*.js`, `**/*.ts`, `**/*.go`
- **Secure pattern:**
  ```ruby
  # Use array form to avoid shell interpretation
  system("convert", input_path, output_path)
  # Or use shellwords
  system("convert #{Shellwords.escape(input_path)}")
  ```
- **Severity:** Critical
- **CWE:** CWE-78
- **OWASP Top 10:** A03:2021-Injection

### IV-03: Path Traversal
- **What to check:** File operations using user-supplied paths without sanitization
- **Detection patterns:**
  - Search: `File\.(read|open|write|delete)\s*\(.*params` (Ruby file ops with params)
  - Search: `send_file\s*\(.*params` (Rails send_file with params)
  - Search: `fs\.(readFile|writeFile|unlink)\(.*req\.` (Node fs with request)
  - Search: `open\(.*request\.` (Python open with request)
  - Search: `os\.(Open|ReadFile)\(.*r\.(Form|URL)` (Go file ops with request)
  - Search: `\.\.\/` or `\.\.\\` in allowed path patterns
  - Files: `app/controllers/**/*.rb`, `**/*.py`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  # Resolve and verify path stays within allowed directory
  path = File.expand_path(params[:filename], UPLOAD_DIR)
  raise "Invalid path" unless path.start_with?(UPLOAD_DIR)
  ```
- **Severity:** High
- **CWE:** CWE-22
- **OWASP Top 10:** A01:2021-Broken Access Control

### IV-04: Missing Strong Parameters (Rails) / Request Validation
- **What to check:** Controller actions accepting unfiltered params
- **Detection patterns:**
  - Search: `params\.permit!` (mass assignment, permits everything)
  - Search: `params\[:` without corresponding `permit` in same controller
  - Search: `params\.to_unsafe_h` (bypasses strong params)
  - Search: `request\.body` without schema validation (Node/Python APIs)
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`, `views.py`
- **Secure pattern:**
  ```ruby
  def user_params
    params.require(:user).permit(:name, :email, :role)
  end
  ```
- **Severity:** High
- **CWE:** CWE-915
- **OWASP Top 10:** A04:2021-Insecure Design

### IV-05: Missing Content-Type Validation
- **What to check:** File uploads accepting any content type
- **Detection patterns:**
  - Search: `has_one_attached|has_many_attached` without content_type validation
  - Search: `multer\(` without fileFilter (Node)
  - Search: `FileField|ImageField` without validators (Django)
  - Files: `app/models/**/*.rb`, `app/uploaders/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  has_one_attached :avatar
  validates :avatar, content_type: ['image/png', 'image/jpeg']
  ```
- **Severity:** Medium
- **CWE:** CWE-434
- **OWASP Top 10:** A04:2021-Insecure Design

### IV-06: Integer Overflow / Type Coercion
- **What to check:** Numeric params used without type checking or bounds validation
- **Detection patterns:**
  - Search: `params\[.*\]\.to_i` without range validation (Ruby)
  - Search: `parseInt\(req\.(params|query|body)` without bounds check (JS)
  - Search: `int\(request\.(GET|POST)` without range check (Python)
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`, `views.py`
- **Secure pattern:**
  ```ruby
  quantity = params[:quantity].to_i
  raise "Invalid quantity" unless (1..10_000).cover?(quantity)
  ```
- **Severity:** Medium
- **CWE:** CWE-190
- **OWASP Top 10:** A03:2021-Injection

### IV-07: NoSQL Injection
- **What to check:** MongoDB/NoSQL queries with unvalidated operator input
- **Detection patterns:**
  - Search: `\.find\(\{.*req\.(body|query|params)` (direct object insertion)
  - Search: `\$where.*req\.` (MongoDB $where with user input)
  - Search: `\.where\(.*params.*\$` (MongoDB operators from params)
  - Files: `**/*.js`, `**/*.ts`, `**/*.py`
- **Secure pattern:**
  ```javascript
  // Sanitize: strip MongoDB operators from user input
  const sanitized = mongo.sanitize(req.body.query);
  db.collection.find({ name: sanitized });
  ```
- **Severity:** Critical
- **CWE:** CWE-943
- **OWASP Top 10:** A03:2021-Injection

### IV-08: XML External Entity (XXE) Injection
- **What to check:** XML parsers with external entity processing enabled
- **Detection patterns:**
  - Search: `Nokogiri::XML\(` without `NOENT` flag check (Ruby)
  - Search: `LIBXML_NOENT` (enabling entity substitution)
  - Search: `etree\.parse\(` without `resolve_entities=False` (Python)
  - Search: `DocumentBuilderFactory` without `setFeature.*disallow-doctype-decl` (Java)
  - Search: `xml2js\.parseString` without `explicitRoot` (Node)
  - Files: `**/*.rb`, `**/*.py`, `**/*.java`, `**/*.js`
- **Secure pattern:**
  ```ruby
  Nokogiri::XML(xml_string) { |config| config.nonet.noent }
  ```
- **Severity:** High
- **CWE:** CWE-611
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### IV-09: Server-Side Request Forgery (SSRF)
- **What to check:** HTTP requests made with user-controlled URLs
- **Detection patterns:**
  - Search: `HTTParty\.(get|post)\(.*params` (Ruby HTTP with user URL)
  - Search: `Faraday\.(get|post)\(.*params` (Ruby Faraday with user URL)
  - Search: `Net::HTTP\.(get|post)\(.*params` (Ruby Net::HTTP)
  - Search: `fetch\(.*req\.(body|query|params)` (Node fetch with user URL)
  - Search: `axios\.(get|post)\(.*req\.` (Node axios with user URL)
  - Search: `requests\.(get|post)\(.*request\.` (Python requests with user URL)
  - Search: `http\.(Get|Post)\(.*r\.(Form|URL)` (Go http with user URL)
  - Files: `app/controllers/**/*.rb`, `app/services/**/*.rb`, `**/*.js`, `**/*.py`
- **Secure pattern:**
  ```ruby
  # Allowlist approach
  ALLOWED_HOSTS = ['api.example.com', 'cdn.example.com'].freeze
  uri = URI.parse(params[:url])
  raise "Blocked host" unless ALLOWED_HOSTS.include?(uri.host)
  ```
- **Severity:** High
- **CWE:** CWE-918
- **OWASP Top 10:** A10:2021-Server-Side Request Forgery

### IV-10: ReDoS (Regular Expression Denial of Service)
- **What to check:** User input matched against vulnerable regex patterns
- **Detection patterns:**
  - Search: `=~.*params` or `match\(.*params` with nested quantifiers
  - Search: `Regexp\.new\(.*params` (user-controlled regex)
  - Search: `new RegExp\(.*req\.` (JS user-controlled regex)
  - Search: `re\.compile\(.*request\.` (Python user-controlled regex)
  - Look for: nested quantifiers `(a+)+`, `(a*)*`, `(a|b)*a`
  - Files: `**/*.rb`, `**/*.js`, `**/*.py`
- **Secure pattern:**
  ```ruby
  # Use Regexp.timeout (Ruby 3.2+) or reject user-controlled regex
  Regexp.timeout = 1.0
  # Better: use literal matching instead of regex for user input
  ```
- **Severity:** Medium
- **CWE:** CWE-1333
- **OWASP Top 10:** A06:2021-Vulnerable and Outdated Components

### IV-11: HTTP Parameter Pollution
- **What to check:** Duplicate parameter names with different interpretations
- **Detection patterns:**
  - Search: `params\[:.*\]` used in both query string and body without disambiguation
  - Search: `req\.query.*req\.body` (same param from both sources)
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  # Be explicit about parameter source
  user_id = request.query_parameters[:user_id]  # NOT params[:user_id]
  ```
- **Severity:** Medium
- **CWE:** CWE-235
- **OWASP Top 10:** A04:2021-Insecure Design

### IV-12: Mass Assignment Beyond Strong Params
- **What to check:** Models with unprotected attributes updated from external input
- **Detection patterns:**
  - Search: `\.update\(params` or `\.update!\(params` (direct params to update)
  - Search: `\.new\(params` or `\.create\(params` (direct params to create)
  - Search: `assign_attributes\(params` (direct params to assign)
  - Search: `attr_accessible` (Rails 3 pattern, outdated)
  - Files: `app/controllers/**/*.rb`, `app/models/**/*.rb`
- **Secure pattern:**
  ```ruby
  @user.update(user_params)  # Uses strong params method
  ```
- **Severity:** High
- **CWE:** CWE-915
- **OWASP Top 10:** A01:2021-Broken Access Control

### IV-13: Header Injection
- **What to check:** HTTP response headers set with user-controlled values
- **Detection patterns:**
  - Search: `response\.headers\[.*\]\s*=\s*.*params` (Ruby header from params)
  - Search: `res\.setHeader\(.*req\.` (Node header from request)
  - Search: `redirect_to\s*params` (open redirect via header)
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`, `middleware/**/*`
- **Secure pattern:**
  ```ruby
  # Validate redirect targets against allowlist
  redirect_to params[:return_to] if ALLOWED_REDIRECTS.include?(params[:return_to])
  ```
- **Severity:** Medium
- **CWE:** CWE-113
- **OWASP Top 10:** A03:2021-Injection

### IV-14: GraphQL-Specific Injection
- **What to check:** GraphQL resolvers without depth/complexity limits, introspection in production
- **Detection patterns:**
  - Search: `max_depth` or `max_complexity` in GraphQL schema config
  - Search: `introspection` in schema config (should be disabled in prod)
  - Search: `resolve\(.*->.*\{` without authorization in resolver
  - Files: `app/graphql/**/*.rb`, `**/*schema*.js`, `**/*resolver*.js`
- **Secure pattern:**
  ```ruby
  class AppSchema < GraphQL::Schema
    max_depth 10
    max_complexity 200
    disable_introspection_entry_points if Rails.env.production?
  end
  ```
- **Severity:** Medium (depth/complexity), High (auth bypass in resolvers)
- **CWE:** CWE-400 (depth), CWE-862 (auth)
- **OWASP Top 10:** A01:2021-Broken Access Control

### IV-15: Deserialization of Untrusted Data
- **What to check:** Deserializing user-controlled data with unsafe methods
- **Detection patterns:**
  - Search: `Marshal\.load` (Ruby - allows arbitrary code execution)
  - Search: `YAML\.load\(` without `permitted_classes` (Ruby)
  - Search: `pickle\.loads?\(` (Python - allows arbitrary code execution)
  - Search: `eval\(.*params` or `eval\(.*req\.` (any language)
  - Search: `JSON\.parse.*reviver` with complex logic (JS)
  - Search: `ObjectInputStream` (Java - deserialization gadgets)
  - Files: `**/*.rb`, `**/*.py`, `**/*.java`, `**/*.js`
- **Secure pattern:**
  ```ruby
  YAML.safe_load(data, permitted_classes: [Symbol, Date])
  JSON.parse(data)  # JSON is safe by default
  ```
- **Severity:** Critical
- **CWE:** CWE-502
- **OWASP Top 10:** A08:2021-Software and Data Integrity Failures
