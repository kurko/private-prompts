# Fintech Security Profile

## Compliance Framework
- PCI DSS v4.0 (if handling card data)
- SOC 2 Type II
- GLBA (financial privacy)
- State money transmitter regulations

## Detection Signals
Keywords that trigger auto-detection: `stripe`, `plaid`, `payment`, `transaction`,
`ledger`, `banking`, `PCI`, `credit_card`, `account_balance`

## Severity Elevations

| Item | Standard Severity | Fintech Severity | Reason |
|------|-------------------|------------------|--------|
| DP-01 (PII plain text) | High | Critical | Financial data subject to PCI DSS |
| EH-05 (Audit trail) | Medium | High | Regulatory requirement |
| AU-07 (MFA) | Medium | High | Required for financial transactions |
| SM-03 (Session expiry) | Medium | High | PCI DSS requirement |
| AC-01 (IDOR) | High | Critical | Account access = financial access |
| CP-05 (Key rotation) | Medium | High | PCI DSS key management requirement |
| EH-04 (Sensitive data in logs) | High | Critical | Card data in logs violates PCI DSS |

## Additional Checks

### FIN-01: Transaction Integrity
- **What to check:** Financial transactions use database transactions with proper isolation
- **Detection patterns:**
  - Search: `transaction do|BEGIN|COMMIT` in payment/transfer flows
  - Search: payment operations without `ActiveRecord::Base.transaction`
  - Search: `isolation.*serializable|isolation.*repeatable` for financial operations
  - Files: `app/services/**/*payment*`, `app/services/**/*transfer*`, `app/models/**/*transaction*`
- **Secure pattern:**
  ```ruby
  ActiveRecord::Base.transaction(isolation: :serializable) do
    account.lock!
    account.update!(balance: account.balance - amount)
    Transfer.create!(from: account, amount: amount, to: recipient)
  end
  ```
- **Severity:** Critical

### FIN-02: Idempotency Keys
- **What to check:** Payment/transfer endpoints support idempotency
- **Detection patterns:**
  - Search: `idempotency_key|Idempotency-Key` header handling
  - Search: `idempotency` in payment controller/service
  - Search: duplicate payment prevention logic
  - Files: `app/controllers/**/*payment*`, `app/services/**/*payment*`
- **Secure pattern:**
  ```ruby
  def create_payment
    idempotency_key = request.headers['Idempotency-Key']
    existing = Payment.find_by(idempotency_key: idempotency_key)
    return render json: existing if existing
    # ... create payment
  end
  ```
- **Severity:** High

### FIN-03: Amount Validation
- **What to check:** Monetary amounts validated for range, precision, and currency
- **Detection patterns:**
  - Search: `amount` params without range validation
  - Search: `Float|float` used for monetary values (precision loss)
  - Search: `BigDecimal|decimal|integer` for money (good)
  - Search: negative amount handling in payment flows
  - Files: `app/controllers/**/*payment*`, `app/models/**/*payment*`, `db/schema.rb`
- **Secure pattern:**
  ```ruby
  validates :amount, numericality: { greater_than: 0, less_than_or_equal_to: 1_000_000 }
  # Use integer cents or BigDecimal, never Float
  add_column :payments, :amount_cents, :bigint, null: false
  ```
- **Severity:** Critical

### FIN-04: Rate Limiting on Financial Operations
- **What to check:** Transfer, payment, and withdrawal endpoints rate-limited
- **Detection patterns:**
  - Search: rate limiting on financial controller actions
  - Search: `Rack::Attack` rules for payment/transfer paths
  - Search: velocity checks (max transactions per hour/day)
  - Files: `config/initializers/rack_attack.rb`, `app/services/**/*payment*`
- **Secure pattern:**
  ```ruby
  Rack::Attack.throttle("payments/user", limit: 10, period: 1.hour) do |req|
    req.env['warden'].user&.id if req.path.start_with?('/payments') && req.post?
  end
  ```
- **Severity:** High

### FIN-05: Audit Trail for Financial Events
- **What to check:** All financial state changes logged with actor, timestamp, before/after
- **Detection patterns:**
  - Search: audit logging in payment/transfer service objects
  - Search: `paper_trail|audited` on financial models
  - Search: balance change logging with before/after values
  - Files: `app/models/**/*payment*`, `app/models/**/*account*`, `app/services/**/*transfer*`
- **Secure pattern:**
  ```ruby
  class Payment < ApplicationRecord
    has_paper_trail
    after_create { AuditLog.create!(event: :payment_created, actor: Current.user, amount: amount, details: attributes) }
  end
  ```
- **Severity:** Critical (regulatory)
