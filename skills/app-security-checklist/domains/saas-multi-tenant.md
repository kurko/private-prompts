# SaaS Multi-Tenant Security Profile

## Compliance Framework
- SOC 2 Type II
- ISO 27001
- Customer-specific compliance requirements

## Detection Signals
Keywords that trigger auto-detection: `tenant`, `organization`, `workspace`,
`team`, `multi_tenant`, `current_tenant`, `ActsAsTenant`, `apartment`

## Severity Elevations

| Item | Standard Severity | Multi-Tenant Severity | Reason |
|------|-------------------|-----------------------|--------|
| AC-01 (IDOR) | High | Critical | IDOR = cross-tenant access |
| AC-08 (Multi-tenancy isolation) | Critical | Critical | Core requirement |
| DB-10 (Row-level security) | Critical | Critical | Data isolation foundation |
| DP-07 (PII in caches) | Medium | High | Cache = cross-tenant leak vector |
| EH-05 (Audit trail) | Medium | High | SOC 2 requirement |

## Additional Checks

### MT-01: Cross-Tenant Data Leakage
- **What to check:** ALL database queries scoped to current tenant
- **Detection patterns:**
  - Search: queries without tenant scope: `Model.find\(|Model.where\(` without tenant
  - Search: `unscoped|unscope` usage (breaks tenant scope)
  - Search: `all` without tenant filter
  - Search: joins that bypass tenant scoping
  - Files: `app/models/**/*.rb`, `app/controllers/**/*.rb`, `app/services/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Use ActsAsTenant to auto-scope all queries
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    acts_as_tenant :organization
  end
  ```
- **Severity:** Critical

### MT-02: Tenant Isolation in Background Jobs
- **What to check:** Async jobs preserve and enforce tenant context
- **Detection patterns:**
  - Search: `perform_later|perform_async` without tenant context
  - Search: job classes without tenant_id argument
  - Search: `Current\.organization|ActsAsTenant\.current_tenant` in jobs (may be nil)
  - Files: `app/jobs/**/*.rb`, `app/workers/**/*.rb`
- **Secure pattern:**
  ```ruby
  class TenantJob < ApplicationJob
    def perform(tenant_id, *args)
      tenant = Organization.find(tenant_id)
      ActsAsTenant.with_tenant(tenant) do
        execute(*args)
      end
    end
  end
  ```
- **Severity:** Critical

### MT-03: Tenant Isolation in Caches
- **What to check:** Cache keys include tenant identifier
- **Detection patterns:**
  - Search: `Rails\.cache\.(fetch|write|read)` without tenant in key
  - Search: `cache_key` methods without tenant prefix
  - Search: Redis operations without tenant namespace
  - Search: fragment caching without tenant variation
  - Files: `app/controllers/**/*.rb`, `app/models/**/*.rb`, `app/views/**/*.erb`
- **Secure pattern:**
  ```ruby
  # Include tenant in all cache keys
  Rails.cache.fetch("tenant_#{current_tenant.id}/users/#{user.id}") { ... }
  # Or use a cache key prefix
  config.cache_store = :redis_cache_store, { namespace: -> { "tenant_#{ActsAsTenant.current_tenant&.id}" } }
  ```
- **Severity:** High

### MT-04: Tenant Admin Privilege Boundaries
- **What to check:** Tenant admins cannot affect other tenants
- **Detection patterns:**
  - Search: admin actions that operate across tenants
  - Search: `admin` role without tenant scoping
  - Search: super-admin vs tenant-admin distinction
  - Files: `app/controllers/admin/**/*.rb`, `app/policies/**/*.rb`
- **Secure pattern:**
  ```ruby
  class TenantAdminPolicy < ApplicationPolicy
    def manage_users?
      user.admin? && user.organization_id == record.organization_id
    end
  end
  ```
- **Severity:** Critical

### MT-05: Tenant Data Export Isolation
- **What to check:** Data export/backup scoped to requesting tenant
- **Detection patterns:**
  - Search: export actions without tenant filtering
  - Search: `Model.all` in export logic without tenant scope
  - Search: data dump scripts without tenant parameter
  - Files: `app/controllers/**/*export*`, `app/services/**/*export*`, `lib/tasks/**/*.rake`
- **Secure pattern:**
  ```ruby
  def export
    ActsAsTenant.with_tenant(current_tenant) do
      @data = ExportService.new(current_tenant).generate
      send_data @data, filename: "#{current_tenant.slug}_export.csv"
    end
  end
  ```
- **Severity:** Critical
