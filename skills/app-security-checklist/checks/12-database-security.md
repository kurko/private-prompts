# 12 - Database Security

## Overview
Verify database access controls, query safety, connection security, and
data integrity protections.

## Tech Stack Adaptations

| Stack | Where to look |
|-------|---------------|
| Rails/ActiveRecord | `config/database.yml`, `app/models/`, `db/migrate/` |
| Django/ORM | `settings.py` (DATABASES), `models.py`, `migrations/` |
| Node/Sequelize/Prisma | `config/database.js`, `prisma/schema.prisma`, `models/` |
| Go/sqlx | Database config, query files, migration files |

## Checklist Items

### DB-01: SQL Injection Beyond Input Validation
- **What to check:** Raw SQL in models, scopes, and query objects
- **Detection patterns:**
  - Search: `execute\(|exec_query\(|find_by_sql\(` with string interpolation
  - Search: `connection\.select_\w+\(.*#\{` (Rails raw connection queries)
  - Search: `Arel\.sql\(.*#\{` (Arel with interpolation)
  - Search: `\.select\(.*#\{|\.order\(.*#\{|\.group\(.*#\{` (interpolation in query methods)
  - Search: `\.pluck\(Arel\.sql` with user input
  - Files: `app/models/**/*.rb`, `app/services/**/*.rb`, `lib/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Use bind parameters even in raw SQL
  ActiveRecord::Base.connection.exec_query(
    "SELECT * FROM users WHERE status = $1", "SQL", [status]
  )
  ```
- **Severity:** Critical
- **CWE:** CWE-89
- **OWASP Top 10:** A03:2021-Injection

### DB-02: Excessive Database Privileges
- **What to check:** Application database user has minimal required privileges
- **Detection patterns:**
  - Search: database user configuration (should not be superuser/root)
  - Search: `GRANT ALL|SUPERUSER|root` in database setup scripts
  - Search: migration user vs application user separation
  - Files: `config/database.yml`, `db/setup.sql`, `scripts/**/*`
- **Secure pattern:**
  ```sql
  -- Separate users for migration and application
  CREATE USER app_user WITH PASSWORD '...';
  GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES TO app_user;
  -- Migration user has more privileges, only used during deploy
  ```
- **Severity:** Medium
- **CWE:** CWE-250
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### DB-03: Missing Database Constraints
- **What to check:** NOT NULL, unique, foreign key constraints match model validations
- **Detection patterns:**
  - Search: `validates.*presence` without `null: false` in migration
  - Search: `validates.*uniqueness` without `unique: true` index
  - Search: `belongs_to` without foreign key constraint in migration
  - Search: `add_reference` without `foreign_key: true`
  - Files: `app/models/**/*.rb`, `db/migrate/**/*.rb`, `db/schema.rb`
- **Secure pattern:**
  ```ruby
  # Migration
  add_column :users, :email, :string, null: false
  add_index :users, :email, unique: true
  add_reference :orders, :user, foreign_key: true, null: false
  ```
- **Severity:** Medium
- **CWE:** CWE-20
- **OWASP Top 10:** A04:2021-Insecure Design

### DB-04: Unencrypted Database Connections
- **What to check:** Database connections use SSL/TLS
- **Detection patterns:**
  - Search: `sslmode` in database.yml or connection string
  - Search: `ssl.*false|sslmode.*disable` (bad)
  - Search: `sslmode.*require|sslmode.*verify` (good)
  - Search: `?ssl=true` in connection strings
  - Files: `config/database.yml`, `.env*`, `docker-compose.yml`
- **Secure pattern:**
  ```yaml
  production:
    adapter: postgresql
    url: <%= ENV['DATABASE_URL'] %>
    sslmode: verify-full
    sslrootcert: config/rds-combined-ca-bundle.pem
  ```
- **Severity:** High
- **CWE:** CWE-319
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### DB-05: Database Credential Management
- **What to check:** DB credentials not hardcoded, stored in environment/secrets
- **Detection patterns:**
  - Search: `password:` in database.yml not from ENV
  - Search: hardcoded connection strings with credentials
  - Search: `DATABASE_URL` with embedded password in committed files
  - Files: `config/database.yml`, `.env*`, `docker-compose.yml`
- **Secure pattern:**
  ```yaml
  production:
    url: <%= ENV['DATABASE_URL'] %>
  ```
- **Severity:** High
- **CWE:** CWE-798
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### DB-06: Connection Pooling Security
- **What to check:** Connection pool sized appropriately, connections not shared across tenants
- **Detection patterns:**
  - Search: `pool:` in database.yml (check size is reasonable)
  - Search: PgBouncer/connection pooler configuration
  - Search: connection pool per-tenant in multi-tenant apps
  - Files: `config/database.yml`, `pgbouncer.ini`, `docker-compose.yml`
- **Secure pattern:**
  ```yaml
  production:
    pool: <%= ENV.fetch('RAILS_MAX_THREADS', 5) %>
    checkout_timeout: 5
  ```
- **Severity:** Low
- **CWE:** CWE-400
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### DB-07: Query Timeout Configuration
- **What to check:** Database query timeouts set to prevent long-running queries
- **Detection patterns:**
  - Search: `statement_timeout|lock_timeout` in database config
  - Search: `connect_timeout|read_timeout` in database.yml
  - Search: `Timeout::timeout` wrapping database operations
  - Files: `config/database.yml`, `config/initializers/**/*.rb`
- **Secure pattern:**
  ```yaml
  production:
    variables:
      statement_timeout: 30000   # 30 seconds
      lock_timeout: 10000        # 10 seconds
  ```
- **Severity:** Medium
- **CWE:** CWE-400
- **OWASP Top 10:** A05:2021-Security Misconfiguration

### DB-08: Prepared Statement Usage
- **What to check:** Prepared statements enabled to prevent SQL injection
- **Detection patterns:**
  - Search: `prepared_statements:.*false` in database config
  - Search: `prepare: false` in query options
  - Files: `config/database.yml`, `config/initializers/**/*.rb`
- **Secure pattern:**
  ```yaml
  production:
    prepared_statements: true  # Default in Rails
  ```
- **Severity:** Medium
- **CWE:** CWE-89
- **OWASP Top 10:** A03:2021-Injection

### DB-09: Database Audit Logging
- **What to check:** Database-level audit logging enabled for sensitive tables
- **Detection patterns:**
  - Search: `pgaudit|audit_log|log_statement` in database config
  - Search: database trigger-based audit trails
  - Search: `log_min_duration_statement` (PostgreSQL slow query log)
  - Files: `config/database.yml`, `db/migrate/**/*.rb`, `terraform/**/*.tf`
- **Secure pattern:**
  ```sql
  -- PostgreSQL: enable pgaudit
  ALTER SYSTEM SET pgaudit.log = 'write, ddl';
  ```
- **Severity:** Medium
- **CWE:** CWE-778
- **OWASP Top 10:** A09:2021-Security Logging and Monitoring Failures

### DB-10: Row-Level Security (Multi-Tenant)
- **What to check:** Database enforces tenant isolation at row level
- **Detection patterns:**
  - Search: `ROW LEVEL SECURITY|RLS|POLICY` in migrations
  - Search: `ActsAsTenant|acts_as_tenant|set_current_tenant` configuration
  - Search: `default_scope.*tenant` in models
  - Files: `app/models/**/*.rb`, `db/migrate/**/*.rb`, `config/initializers/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Application-level (ActsAsTenant)
  class ApplicationRecord < ActiveRecord::Base
    acts_as_tenant :organization
  end
  # Or database-level (PostgreSQL RLS)
  # CREATE POLICY tenant_isolation ON orders USING (tenant_id = current_setting('app.tenant_id'))
  ```
- **Severity:** Critical (multi-tenant apps)
- **CWE:** CWE-639
- **OWASP Top 10:** A01:2021-Broken Access Control

### DB-11: Backup Encryption
- **What to check:** Database backups encrypted at rest
- **Detection patterns:**
  - Search: backup scripts without encryption
  - Search: `pg_dump|mysqldump` without piping to encryption
  - Search: S3 backup bucket without server-side encryption
  - Files: `bin/*`, `lib/tasks/**/*.rake`, `terraform/**/*.tf`
- **Secure pattern:**
  ```bash
  pg_dump $DATABASE_URL | gzip | aws s3 cp - s3://backups/$(date +%Y%m%d).sql.gz --sse aws:kms
  ```
- **Severity:** High
- **CWE:** CWE-311
- **OWASP Top 10:** A02:2021-Cryptographic Failures

### DB-12: Migration Rollback Safety
- **What to check:** Migrations are reversible and don't cause data loss
- **Detection patterns:**
  - Search: `remove_column|drop_table` without data backup step
  - Search: migrations without `reversible` or `down` method
  - Search: `change_column` that narrows data type
  - Files: `db/migrate/**/*.rb`
- **Secure pattern:**
  ```ruby
  class RemoveObsoleteColumn < ActiveRecord::Migration[7.0]
    def up
      safety_assured { remove_column :users, :legacy_field }
    end
    def down
      add_column :users, :legacy_field, :string
    end
  end
  ```
- **Severity:** Medium
- **CWE:** CWE-404
- **OWASP Top 10:** A04:2021-Insecure Design

### DB-13: Seed Data Security
- **What to check:** Seed files don't contain real credentials or PII
- **Detection patterns:**
  - Search: `seeds.rb` with real email addresses, passwords, or API keys
  - Search: seed data using production credentials
  - Files: `db/seeds.rb`, `db/seeds/**/*.rb`
- **Secure pattern:**
  ```ruby
  # Use faker, not real data
  User.create!(email: "admin@example.com", password: SecureRandom.hex(16))
  ```
- **Severity:** Low
- **CWE:** CWE-798
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures

### DB-14: Database Version
- **What to check:** Database server version is supported and patched
- **Detection patterns:**
  - Search: database version in docker-compose or infrastructure config
  - Search: `image: postgres:|image: mysql:` version tags
  - Search: database version pinning in deployment scripts
  - Files: `docker-compose.yml`, `terraform/**/*.tf`, `Dockerfile`
- **Secure pattern:** Use actively supported database versions. Update regularly.
- **Severity:** Medium
- **CWE:** CWE-1104
- **OWASP Top 10:** A06:2021-Vulnerable and Outdated Components

### DB-15: Connection String Injection
- **What to check:** Database connection strings not constructed from user input
- **Detection patterns:**
  - Search: `params` or `request` data used in database connection
  - Search: dynamic database selection from user input
  - Search: connection string built with string concatenation
  - Files: `app/controllers/**/*.rb`, `config/**/*.rb`
- **Secure pattern:** Database connections configured from ENV only, never from user input.
- **Severity:** Critical
- **CWE:** CWE-89
- **OWASP Top 10:** A03:2021-Injection

### DB-16: NoSQL-Specific Security
- **What to check:** MongoDB/Redis/etc. security configurations
- **Detection patterns:**
  - Search: `mongodb://` without authentication
  - Search: `redis://` without password (should use AUTH)
  - Search: `bind_ip.*0\.0\.0\.0` (MongoDB exposed to all interfaces)
  - Search: `protected-mode no` in Redis config
  - Files: `config/**/*.yml`, `.env*`, `docker-compose.yml`, `mongoid.yml`
- **Secure pattern:**
  ```yaml
  # MongoDB with auth
  production:
    clients:
      default:
        uri: <%= ENV['MONGODB_URI'] %>  # mongodb://user:pass@host/db?authSource=admin
  ```
- **Severity:** High
- **CWE:** CWE-287
- **OWASP Top 10:** A07:2021-Identification and Authentication Failures
