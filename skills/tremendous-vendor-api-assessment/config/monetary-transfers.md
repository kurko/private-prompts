---
category: monetary-transfers
display_name: Monetary / International Transfers
keywords: bank transfer, wire, ACH, SEPA, FX, foreign exchange, payout, remittance, corridor, beneficiary
---

# Monetary / International Transfers Vendor Assessment

## Level 2 Domain Agents

### 1. Beneficiary Management Agent
**Scope**: Creating and managing payment recipients

**Base Requirements**:
- Programmatic beneficiary creation
- Beneficiary data requirements per country/corridor
- Beneficiary validation (bank account verification)
- Beneficiary update and deletion
- Beneficiary reuse across payments (not 1:1 with payer)

### 2. Payment Initiation Agent
**Scope**: Creating and sending payments

**Sub-domain agents to spawn**:

#### 2a. Domestic Payments Sub-Agent
- ACH, wire, local payment rails
- Same-day vs standard settlement
- Payment scheduling

#### 2b. International Payments Sub-Agent
- Supported corridors (country pairs)
- Payment rails per corridor (SWIFT, local rails)
- Required payment metadata per country (purpose codes, regulatory fields)
- Intermediary bank handling

**Base Requirements**:
- API-driven payment creation
- Batch/bulk payment support
- Payment status tracking
- Payment cancellation (before settlement)
- Supported currencies and corridors

### 3. FX & Conversion Agent
**Scope**: Foreign exchange rates and currency conversion

**Base Requirements**:
- Real-time rate quotes
- Rate lock duration and mechanism
- FX markup/spread transparency
- Forward contracts or rate hedging
- Multi-currency account support
- Auto-conversion vs manual conversion

### 4. Funding & Settlement Agent
**Scope**: How funds flow and settle

**Base Requirements**:
- Prefunding requirements (pre-deposit vs post-settlement)
- Settlement timelines per corridor
- Settlement currency options
- Reconciliation data and reports
- Fund segregation (not co-mingled)
- Balance management and top-up

### 5. Inbound Funds / Collections Agent
**Scope**: Receiving payments from third parties

**Base Requirements**:
- Virtual account numbers for collection
- Payment matching and reconciliation
- Supported inbound payment methods
- Notification on receipt
- Multi-currency collection accounts

### 6. Compliance & Regulatory Agent
**Scope**: Transfer-specific compliance

**Base Requirements**:
- Sanctions screening on transfers
- Purpose of payment codes
- Regulatory reporting
- Country-specific requirements (e.g. India's FIRA)
- Transaction limits per corridor

**Category-Specific Red Flags**:
- Beneficiary-per-customer model (conflicts with Tremendous's multi-recipient model)
- Co-mingled funds across customers
- No programmatic fund movement (manual top-up only)
- Limited corridor coverage for target markets
- Unclear FX markup (hidden fees in rates)
- No batch/bulk payment support
- Settlement times >5 business days for key corridors
- No payment cancellation mechanism

## Category-Specific Questions Template

1. What corridors are supported and what are the settlement times?
2. What is the FX markup/spread structure?
3. Is prefunding required, and what are the minimum balance requirements?
4. How is beneficiary data validated before payment?
5. What payment rails are used per corridor (SWIFT, local ACH, etc.)?
6. Can payments be cancelled after initiation but before settlement?
7. What regulatory fields are required per country?
8. How are returned/rejected payments handled?
9. Is there a virtual account/IBAN for collections?
10. What is the reconciliation process (reports, webhooks, API)?
