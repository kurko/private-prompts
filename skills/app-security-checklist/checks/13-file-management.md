# 13 - File Management

## Overview
Verify file upload, download, storage, and processing security.

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails | `app/models/` (Active Storage), `app/uploaders/` (CarrierWave), `app/controllers/` |
| Django | `models.py` (FileField), `views.py`, `MEDIA_ROOT` config |
| Express/Node | `multer` config, `routes/`, `controllers/`, S3 config |
| Go | File handling in handlers, upload middleware |

## Checklist Items

### FM-01: Unrestricted File Upload
- **What to check:** File uploads validated for type, size, and content
- **Detection patterns:**
  - Search: `has_one_attached|has_many_attached` without validation
  - Search: `multer\(` without `fileFilter` or `limits` (Node)
  - Search: `FileField|ImageField` without validators (Django)
  - Search: `CarrierWave` uploaders without `content_type_allowlist`
  - Files: `app/models/**/*.rb`, `app/uploaders/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  has_one_attached :document
  validates :document, content_type: ['application/pdf', 'image/png', 'image/jpeg'],
                       size: { less_than: 10.megabytes }
  ```
- **Severity:** High
- **CWE:** CWE-434
- **OWASP Top 10:** A04:2021-Insecure Design

### FM-02: Path Traversal in File Operations
- **What to check:** File paths sanitized before use
- **Detection patterns:**
  - Search: `send_file\(.*params` (Rails send_file with user input)
  - Search: `File\.(read|open|write)\(.*params` (Ruby file ops with params)
  - Search: `fs\.(readFile|createReadStream)\(.*req\.` (Node)
  - Search: `\.\.` or `%2e%2e` in path validation logic
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  path = File.expand_path(params[:filename], ALLOWED_DIR)
  raise "Path traversal detected" unless path.start_with?(ALLOWED_DIR)
  send_file path
  ```
- **Severity:** High
- **CWE:** CWE-22
- **OWASP Top 10:** A01:2021-Broken Access Control

### FM-03: Executable File Upload
- **What to check:** Uploaded files cannot be executed on the server
- **Detection patterns:**
  - Search: upload directory within web-accessible path
  - Search: `public/uploads|static/uploads` directory configuration
  - Search: web server configured to execute files in upload directory
  - Search: `.php|.jsp|.asp|.sh|.py|.rb` in allowed upload extensions
  - Files: `config/storage.yml`, `nginx.conf`, `app/uploaders/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Store uploads outside web root (Active Storage default)
  # Or use cloud storage (S3, GCS)
  config.active_storage.service = :amazon  # Not :local in production
  ```
- **Severity:** Critical
- **CWE:** CWE-434
- **OWASP Top 10:** A04:2021-Insecure Design

### FM-04: Missing Antivirus Scanning
- **What to check:** Uploaded files scanned for malware (high-risk apps)
- **Detection patterns:**
  - Search: `clamav|clam_scan|virus_scan|malware` in dependencies/code
  - Search: file scanning integration in upload pipeline
  - Files: `Gemfile`, `package.json`, `app/services/**/*upload*`
- **Secure pattern:**
  ```ruby
  # Scan uploads with ClamAV
  after_save :scan_attachment
  def scan_attachment
    return unless document.attached?
    result = ClamScan.scan(document.download)
    document.purge if result.virus?
  end
  ```
- **Severity:** Medium (Low for internal apps)
- **CWE:** CWE-434
- **OWASP Top 10:** A04:2021-Insecure Design

### FM-05: Insecure Temporary File Handling
- **What to check:** Temp files created securely and cleaned up
- **Detection patterns:**
  - Search: `Tempfile\.new|File\.open.*tmp` without ensure/cleanup
  - Search: predictable temp file paths (`/tmp/myapp_`)
  - Search: `mktemp` without `-t` flag
  - Files: `app/services/**/*.rb`, `lib/**/*.rb`, `**/*.js`
- **Secure pattern:**
  ```ruby
  Tempfile.create(['upload', '.pdf']) do |f|
    f.write(data)
    process(f)
  end  # Auto-deleted
  ```
- **Severity:** Low
- **CWE:** CWE-377
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### FM-06: File Download Authorization
- **What to check:** File downloads authorized, not just authenticated
- **Detection patterns:**
  - Search: `send_file|send_data|rails_blob_path` without authorization
  - Search: Active Storage URLs without authorization check
  - Search: S3 presigned URLs generated without ownership verification
  - Files: `app/controllers/**/*.rb`, `config/routes.rb`
- **Secure pattern:**
  ```ruby
  def download
    @document = current_user.documents.find(params[:id])
    authorize @document, :download?
    redirect_to @document.file.url(disposition: :attachment)
  end
  ```
- **Severity:** High
- **CWE:** CWE-862
- **OWASP Top 10:** A01:2021-Broken Access Control

### FM-07: File Name Sanitization
- **What to check:** Uploaded file names sanitized to prevent attacks
- **Detection patterns:**
  - Search: `original_filename` used directly without sanitization
  - Search: uploaded filename used in file path construction
  - Search: `filename.*params|filename.*original` without sanitize
  - Files: `app/controllers/**/*.rb`, `app/uploaders/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Active Storage generates safe filenames by default
  # For custom uploads:
  safe_name = ActiveStorage::Filename.new(original_name).sanitized
  ```
- **Severity:** Medium
- **CWE:** CWE-73
- **OWASP Top 10:** A03:2021-Injection

### FM-08: Storage Bucket Permissions
- **What to check:** S3/GCS buckets have restrictive ACLs, not public
- **Detection patterns:**
  - Search: `acl.*public|public.*acl|PublicRead` in storage config
  - Search: `block_public_access.*false` in infrastructure
  - Search: S3 bucket policy allowing `*` principal
  - Files: `config/storage.yml`, `terraform/**/*.tf`, `s3-policy.json`
- **Secure pattern:**
  ```yaml
  # config/storage.yml
  amazon:
    service: S3
    access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
    secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
    region: us-east-1
    bucket: my-private-bucket
    # No public: true
  ```
- **Severity:** High
- **CWE:** CWE-732
- **OWASP Top 10:** A01:2021-Broken Access Control

### FM-09: Signed URLs for Private Files
- **What to check:** Private files served via time-limited signed URLs
- **Detection patterns:**
  - Search: `url\(expires_in:` or presigned URL generation
  - Search: direct S3 URLs without signing
  - Search: `public.*true` on file serving
  - Files: `app/controllers/**/*.rb`, `app/models/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Active Storage with expiring URLs
  @document.file.url(expires_in: 5.minutes, disposition: :inline)
  ```
- **Severity:** Medium
- **CWE:** CWE-862
- **OWASP Top 10:** A01:2021-Broken Access Control

### FM-10: Image Processing Vulnerabilities
- **What to check:** Image processing libraries secured against malicious images
- **Detection patterns:**
  - Search: `ImageMagick|MiniMagick|RMagick|image_processing` in dependencies
  - Search: ImageMagick policy file existence (`/etc/ImageMagick-*/policy.xml`)
  - Search: `variant|resize|transform` on uploaded images
  - Files: `Gemfile`, `package.json`, `app/models/**/*.rb`
- **Secure pattern:**
  ```xml
  <!-- /etc/ImageMagick-7/policy.xml -->
  <policy domain="coder" rights="none" pattern="MVG" />
  <policy domain="coder" rights="none" pattern="SVG" />
  <policy domain="coder" rights="none" pattern="PDF" />
  <policy domain="resource" name="memory" value="256MiB"/>
  ```
- **Severity:** High
- **CWE:** CWE-94
- **OWASP Top 10:** A06:2021-Vulnerable and Outdated Components

### FM-11: PDF Generation Security
- **What to check:** PDF generation doesn't allow SSRF or file inclusion
- **Detection patterns:**
  - Search: `wkhtmltopdf|Prawn|PDFKit|puppeteer` in dependencies
  - Search: `render_to_string|html_to_pdf` with user-controlled HTML
  - Search: PDF generation from user-supplied URLs
  - Files: `Gemfile`, `package.json`, `app/services/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Restrict wkhtmltopdf network access
  PDFKit.new(html, disable_local_file_access: true, disable_external_links: true)
  ```
- **Severity:** Medium
- **CWE:** CWE-918
- **OWASP Top 10:** A10:2021-Server-Side Request Forgery

### FM-12: CSV Injection
- **What to check:** Exported CSV data sanitized to prevent formula injection
- **Detection patterns:**
  - Search: `to_csv|CSV\.generate` without sanitization
  - Search: `=|+|-|@` characters allowed at start of CSV cell values
  - Search: CSV export of user-generated content
  - Files: `app/controllers/**/*.rb`, `app/services/**/*.rb`, `lib/**/*.rb`
- **Secure pattern:**
  ```ruby
  def sanitize_csv_value(value)
    return value unless value.is_a?(String)
    value.start_with?('=', '+', '-', '@', "\t", "\r") ? "'#{value}" : value
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-1236
- **OWASP Top 10:** A03:2021-Injection

### FM-13: Zip Bomb Protection
- **What to check:** Zip/archive extraction limited in size and depth
- **Detection patterns:**
  - Search: `Zip::File|rubyzip|adm-zip|JSZip` without size limits
  - Search: `extract|unzip` without checking decompressed size
  - Search: `zipfile\.ZipFile` (Python) without size check
  - Files: `app/services/**/*.rb`, `lib/**/*.rb`, `**/*.js`, `**/*.py`
- **Secure pattern:**
  ```ruby
  MAX_UNCOMPRESSED_SIZE = 100.megabytes
  Zip::File.open(zip_path) do |zip|
    total = zip.sum { |entry| entry.size }
    raise "Zip bomb detected" if total > MAX_UNCOMPRESSED_SIZE
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-409
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### FM-14: Symlink Attack Prevention
- **What to check:** File operations don't follow symlinks to access unauthorized files
- **Detection patterns:**
  - Search: `File\.read|File\.open` without checking for symlinks
  - Search: user-uploadable archives that could contain symlinks
  - Search: `File\.symlink\?` or `File\.lstat` usage (good - checking)
  - Files: `app/services/**/*.rb`, `lib/**/*.rb`
- **Secure pattern:**
  ```ruby
  path = File.realpath(user_path)
  raise "Symlink detected" unless path.start_with?(SAFE_DIR)
  ```
- **Severity:** Medium
- **CWE:** CWE-59
- **OWASP Top 10:** A01:2021-Broken Access Control

### FM-15: File Metadata Stripping
- **What to check:** Uploaded images have EXIF/metadata stripped
- **Detection patterns:**
  - Search: `exif|metadata|strip` in image processing pipeline
  - Search: `mini_magick|image_processing` without metadata removal
  - Search: uploaded images served with original EXIF (may contain GPS)
  - Files: `app/models/**/*.rb`, `app/uploaders/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Strip EXIF data from uploaded images
  has_one_attached :photo do |attachable|
    attachable.variant :display, strip: true, resize_to_limit: [800, 800]
  end
  ```
- **Severity:** Low
- **CWE:** CWE-200
- **OWASP Top 10:** A01:2021-Broken Access Control
