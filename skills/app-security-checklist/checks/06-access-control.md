# 06 - Access Control

## Overview
Verify authorization mechanisms enforce least privilege, prevent IDOR, and
handle role/permission boundaries correctly.

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails | `app/controllers/`, `app/policies/` (Pundit), `app/models/ability.rb` (CanCanCan) |
| Django | `views.py`, `permissions.py`, `@permission_required` decorators |
| Express/Node | `middleware/auth.js`, `middleware/permissions.js`, route guards |
| Go | Middleware handlers, `authz/` package |

## Checklist Items

### AC-01: Insecure Direct Object Reference (IDOR)
- **What to check:** All object lookups scoped to current user's authorized objects
- **Detection patterns:**
  - Search: `find\(params\[:id\]\)` without scope (Rails)
  - Search: `find_by\(id: params\[:id\]\)` without user scope
  - Search: `Model\.objects\.get\(pk=` without user filter (Django)
  - Search: `findById\(req\.params\.id\)` without ownership check (Node)
  - Files: `app/controllers/**/*.rb`, `**/*.py`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  # Scope to current user
  @order = current_user.orders.find(params[:id])
  # Or use Pundit
  @order = Order.find(params[:id])
  authorize @order
  ```
- **Severity:** High
- **CWE:** CWE-639
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-02: Missing Authorization Checks
- **What to check:** Every controller action has explicit authorization
- **Detection patterns:**
  - Search: `before_action :authorize` or `after_action :verify_authorized` (Pundit)
  - Search: `authorize!` or `load_and_authorize_resource` (CanCanCan)
  - Search: controllers without any authorization callback
  - Search: `skip_authorization` or `skip_before_action.*authorize` usage
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`, `**/views.py`
- **Secure pattern:**
  ```ruby
  class ApplicationController < ActionController::Base
    include Pundit::Authorization
    after_action :verify_authorized, except: :index
    after_action :verify_policy_scoped, only: :index
  end
  ```
- **Severity:** Critical
- **CWE:** CWE-862
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-03: Horizontal Privilege Escalation
- **What to check:** Users cannot access other users' resources by changing IDs
- **Detection patterns:**
  - Search: resource lookups without ownership/membership validation
  - Search: `User.find(params[:id])` in non-admin controllers
  - Search: update/delete actions without verifying resource belongs to current user
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  # Always scope to current user's accessible resources
  @document = policy_scope(Document).find(params[:id])
  ```
- **Severity:** High
- **CWE:** CWE-639
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-04: Vertical Privilege Escalation
- **What to check:** Role checks cannot be bypassed by modifying request
- **Detection patterns:**
  - Search: `role` or `admin` in params that get assigned to user
  - Search: `params.*role|params.*admin|params.*is_admin` in update actions
  - Search: role checks only on frontend, not backend
  - Files: `app/controllers/**/*.rb`, `app/models/user*.rb`
- **Secure pattern:**
  ```ruby
  # Never permit role changes from params
  def user_params
    params.require(:user).permit(:name, :email)  # NOT :role, :admin
  end
  ```
- **Severity:** Critical
- **CWE:** CWE-269
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-05: Missing Function-Level Access Control
- **What to check:** Administrative functions protected at every layer
- **Detection patterns:**
  - Search: `admin` namespace/routes without role verification middleware
  - Search: admin controllers without `before_action` checking admin role
  - Search: `/admin/` routes accessible without authentication
  - Files: `config/routes.rb`, `app/controllers/admin/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  namespace :admin do
    before_action :require_admin
    resources :users
  end
  ```
- **Severity:** Critical
- **CWE:** CWE-285
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-06: Default Deny
- **What to check:** Authorization defaults to deny, not allow
- **Detection patterns:**
  - Search: `unless.*admin` or `if.*!admin` (deny-by-exception pattern)
  - Search: authorization logic that falls through to allow
  - Search: `rescue.*AccessDenied` (verify it returns 403, not silently allows)
  - Files: `app/policies/**/*.rb`, `app/controllers/application_controller.rb`
- **Secure pattern:**
  ```ruby
  # Pundit: default deny
  class ApplicationPolicy
    def initialize(user, record)
      @user = user
      @record = record
    end
    def index? = false
    def show? = false
    def create? = false
    def update? = false
    def destroy? = false
  end
  ```
- **Severity:** High
- **CWE:** CWE-276
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-07: Permission Inheritance
- **What to check:** Child resource permissions don't exceed parent permissions
- **Detection patterns:**
  - Search: nested resource access without checking parent authorization
  - Search: `has_many.*through` access paths without scope
  - Search: child resources accessible via direct URL without parent context
  - Files: `app/controllers/**/*.rb`, `config/routes.rb`
- **Secure pattern:**
  ```ruby
  # Always load child through authorized parent
  @project = current_user.projects.find(params[:project_id])
  @task = @project.tasks.find(params[:id])
  ```
- **Severity:** Medium
- **CWE:** CWE-863
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-08: Multi-Tenancy Isolation
- **What to check:** All queries scoped to current tenant in multi-tenant apps
- **Detection patterns:**
  - Search: `unscoped|unscope` in controllers (breaks tenant scope)
  - Search: `ActsAsTenant|Apartment|current_tenant` configuration
  - Search: models without tenant association in multi-tenant app
  - Search: queries without `.where(tenant_id:` in multi-tenant app
  - Files: `app/models/**/*.rb`, `app/controllers/**/*.rb`, `config/initializers/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Use ActsAsTenant or equivalent
  set_current_tenant_through_filter
  before_action :set_tenant
  # All queries auto-scoped to current tenant
  ```
- **Severity:** Critical
- **CWE:** CWE-639
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-09: API Endpoint Authorization
- **What to check:** API endpoints have same authorization as web endpoints
- **Detection patterns:**
  - Search: `Api::` or `api/` controllers without authorization
  - Search: API routes without authentication middleware
  - Search: `skip_before_action.*authenticate` in API controllers
  - Files: `app/controllers/api/**/*.rb`, `config/routes.rb`, `routes/api/**/*.js`
- **Secure pattern:**
  ```ruby
  module Api
    class BaseController < ApplicationController
      before_action :authenticate_api_user!
      before_action :authorize_api_access
    end
  end
  ```
- **Severity:** High
- **CWE:** CWE-862
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-10: File Access Authorization
- **What to check:** File downloads/uploads authorized, not just authenticated
- **Detection patterns:**
  - Search: `send_file|send_data` without authorization check
  - Search: `url_for.*blob|rails_blob_path` without authorization
  - Search: S3 presigned URLs generated without authorization
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  def download
    @document = current_user.documents.find(params[:id])
    authorize @document, :download?
    send_file @document.file.path
  end
  ```
- **Severity:** High
- **CWE:** CWE-862
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-11: Feature Flag Authorization
- **What to check:** Feature flags don't bypass authorization checks
- **Detection patterns:**
  - Search: `feature.*enabled|flipper|feature_flag` used to skip auth
  - Search: feature flags that expose admin functionality to regular users
  - Files: `app/controllers/**/*.rb`, `config/initializers/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Feature flag controls visibility, NOT authorization
  if Flipper.enabled?(:new_feature, current_user)
    authorize @resource, :use_new_feature?  # Still authorize
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-863
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-12: Bulk Operation Authorization
- **What to check:** Bulk actions authorize every item, not just the first
- **Detection patterns:**
  - Search: `where\(id: params\[:ids\]\)` without scope
  - Search: bulk update/delete without per-item authorization
  - Search: `update_all|delete_all|destroy_all` with user-provided IDs
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  def bulk_update
    @items = policy_scope(Item).where(id: params[:ids])
    @items.each { |item| authorize item, :update? }
    @items.update_all(status: params[:status])
  end
  ```
- **Severity:** High
- **CWE:** CWE-862
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-13: Cascade Delete Authorization
- **What to check:** Deleting parent doesn't delete unauthorized children
- **Detection patterns:**
  - Search: `dependent: :destroy` on associations with separate access control
  - Search: `ON DELETE CASCADE` in migrations for sensitive resources
  - Files: `app/models/**/*.rb`, `db/migrate/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Use dependent: :restrict_with_error for sensitive children
  has_many :shared_documents, dependent: :restrict_with_error
  ```
- **Severity:** Medium
- **CWE:** CWE-863
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-14: Export/Report Authorization
- **What to check:** Data export endpoints authorized and scoped
- **Detection patterns:**
  - Search: `export|download|report|csv|pdf` in controller actions
  - Search: export actions without authorization checks
  - Search: exports pulling `all` records without scope
  - Files: `app/controllers/**/*.rb`, `routes/**/*.js`
- **Secure pattern:**
  ```ruby
  def export
    authorize :report, :export?
    @data = policy_scope(Record).where(date: params[:range])
    respond_to { |format| format.csv { send_data @data.to_csv } }
  end
  ```
- **Severity:** High
- **CWE:** CWE-862
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-15: Webhook Endpoint Authorization
- **What to check:** Webhook receivers verify sender authenticity
- **Detection patterns:**
  - Search: `webhook` in routes/controllers
  - Search: `skip_before_action.*authenticate` on webhook endpoints
  - Search: `verify_signature|verify_webhook` in webhook handlers
  - Files: `app/controllers/**/*webhook*`, `config/routes.rb`
- **Secure pattern:**
  ```ruby
  def webhook
    payload = request.raw_post
    sig = request.headers['X-Signature']
    expected = OpenSSL::HMAC.hexdigest('SHA256', ENV['WEBHOOK_SECRET'], payload)
    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(sig, expected)
  end
  ```
- **Severity:** High
- **CWE:** CWE-345
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### AC-16: Admin Impersonation Controls
- **What to check:** Admin "act as user" feature is logged and restricted
- **Detection patterns:**
  - Search: `impersonate|act_as|sudo|become` in controllers
  - Search: session manipulation allowing admin to act as another user
  - Search: impersonation without audit logging
  - Files: `app/controllers/**/*.rb`, `app/controllers/admin/**/*.rb`
- **Secure pattern:**
  ```ruby
  def impersonate
    authorize :admin, :impersonate?
    AuditLog.create!(admin: current_user, target: User.find(params[:id]), action: :impersonate)
    session[:impersonating_user_id] = params[:id]
  end
  ```
- **Severity:** High
- **CWE:** CWE-269
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-17: Delegation/Proxy Authorization
- **What to check:** Delegated access follows principle of least privilege
- **Detection patterns:**
  - Search: `delegate|proxy|on_behalf_of|acting_as` in auth logic
  - Search: OAuth scopes that grant overly broad access
  - Search: API tokens without scope restrictions
  - Files: `app/models/**/*.rb`, `app/controllers/**/*.rb`, `config/initializers/**/*.rb`
- **Secure pattern:**
  ```ruby
  class ApiToken < ApplicationRecord
    serialize :scopes, Array
    def can?(action)
      scopes.include?(action.to_s)
    end
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-269
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-18: Service-to-Service Authorization
- **What to check:** Internal service calls authenticated and authorized
- **Detection patterns:**
  - Search: internal API calls without authentication headers
  - Search: `localhost|127\.0\.0\.1|internal` API calls without auth
  - Search: service-to-service tokens/keys in config
  - Files: `app/services/**/*.rb`, `lib/**/*.rb`, `**/*client*.rb`
- **Secure pattern:**
  ```ruby
  # Use service tokens for internal APIs
  class InternalApiClient
    def initialize
      @token = ENV.fetch('INTERNAL_API_TOKEN')
    end
    def get(path)
      HTTP.auth("Bearer #{@token}").get("#{base_url}#{path}")
    end
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-287
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### AC-19: Time-Based Access Restrictions
- **What to check:** Time-limited access tokens/invites properly expire
- **Detection patterns:**
  - Search: `invite|invitation` tokens without expiry
  - Search: `share_link|shared_link` without expiration
  - Search: temporary access grants without time check
  - Files: `app/models/**/*.rb`, `app/controllers/**/*.rb`, `db/migrate/**/*.rb`
- **Secure pattern:**
  ```ruby
  class Invitation < ApplicationRecord
    scope :valid, -> { where("expires_at > ?", Time.current) }
    validates :expires_at, presence: true
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-613
- **OWASP Top 10:** A01:2021-Broken Access Control

### AC-20: Geo-Based Access Restrictions
- **What to check:** Geographic restrictions enforced server-side if required
- **Detection patterns:**
  - Search: `country|region|geo|ip_country` in access control logic
  - Search: geo-blocking only on frontend (bypassable)
  - Search: compliance-required geographic restrictions (GDPR, data residency)
  - Files: `app/controllers/**/*.rb`, `app/middleware/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Server-side geo check for compliance
  before_action :enforce_geo_restrictions
  def enforce_geo_restrictions
    country = GeoIP.lookup(request.remote_ip)&.country_code
    head :forbidden if BLOCKED_COUNTRIES.include?(country)
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-284
- **OWASP Top 10:** A01:2021-Broken Access Control
