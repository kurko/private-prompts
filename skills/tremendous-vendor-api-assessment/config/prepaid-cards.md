---
category: prepaid-cards
display_name: Prepaid Cards
keywords: prepaid, card issuance, card program, virtual card, physical card, card lifecycle
---

# Prepaid Cards Vendor Assessment

## Level 2 Domain Agents

### 1. Account Management Agent
**Scope**: Organization/program setup, account hierarchy, multi-tenant support

**Base Requirements**:
- Programmatic account/program creation
- Multi-tenant support (separate programs per organization)
- Account hierarchy (parent/child accounts)
- Balance management per account
- Account status lifecycle (active, suspended, closed)

### 2. Card Issuance Agent
**Scope**: Creating virtual and physical cards

**Sub-domain agents to spawn**:

#### 2a. Virtual Cards Sub-Agent
- Instant issuance via API
- Card details retrieval (PAN, CVV, expiry)
- Card image/branding customization
- Multi-currency virtual cards

#### 2b. Physical Cards Sub-Agent
- Physical card ordering via API
- Shipping options and tracking
- Card activation flow
- Replacement/reissue process
- Custom branding/design on physical cards
- Bulk card ordering

**Base Requirements**:
- API-driven card creation (no portal-only)
- Card details returned or retrievable via API
- Support for both virtual and physical cards
- Bulk/batch card creation

### 3. Card Lifecycle Agent
**Scope**: Managing cards after issuance

**Base Requirements**:
- Card activation/deactivation via API
- Card status transitions (active, frozen, cancelled, expired)
- PIN management (set, reset)
- Card replacement without new recipient enrollment
- Expiry handling and renewal

### 4. Funding & Balance Agent
**Scope**: Loading funds onto cards, balance management

**Base Requirements**:
- Programmatic card funding/loading
- Balance inquiry via API
- Transaction history retrieval
- Prefunding/pooled funding model clarity
- Unload/withdraw funds from card
- Auto-reload capabilities

### 5. Authorization & Transactions Agent
**Scope**: Transaction processing, controls, and reporting

**Base Requirements**:
- Real-time authorization notifications (webhooks)
- MCC (Merchant Category Code) restrictions
- Spend limits (per-transaction, daily, monthly)
- Geographic restrictions
- ATM withdrawal controls
- Transaction dispute/chargeback API
- Settlement and reconciliation data

### 6. PCI Compliance & Security Agent
**Scope**: PCI-DSS requirements, secure card display

**Base Requirements**:
- **CRITICAL**: iFrame or SDK for displaying card details to recipients
  - **Red Flag if NOT available**: Tremendous would need to build PCI-compliant infrastructure
  - If available: evaluate the SDK/iFrame quality, customization options, mobile support
- Tokenization support
- 3D Secure support
- PCI-DSS certification level
- Data encryption at rest and in transit

**Category-Specific Red Flags**:
- No iFrame/SDK for card display (forces PCI compliance on us)
- Physical cards cannot be shipped internationally
- No programmatic PIN management
- Card details only available via portal (not API)
- No real-time authorization webhooks
- Single-currency only for a multi-currency use case

## Category-Specific Questions Template

These questions should always be investigated for prepaid card vendors:

1. What PCI-DSS certification level does the vendor hold?
2. Is there an iFrame or SDK for securely displaying card details (PAN, CVV)?
3. Can cards be issued in multiple currencies?
4. What is the card network (Visa, Mastercard, both)?
5. Are there per-program BIN assignments?
6. What are the card funding limits?
7. How are chargebacks/disputes handled programmatically?
8. Can MCC restrictions be set per card or per program?
9. What is the physical card production and shipping timeline?
10. Is there a white-label option for the cardholder portal?
