---
category: merchant-gift-cards
display_name: Merchant Gift Cards
keywords: gift card, merchant, catalog, redemption, fulfillment, e-gift, digital gift card, brand
---

# Merchant Gift Cards Vendor Assessment

## Level 2 Domain Agents

### 1. Catalog Management Agent
**Scope**: Available brands, products, and catalog access

**Base Requirements**:
- Programmatic catalog retrieval
- Brand/product search and filtering
- Catalog updates (new brands, discontinued brands, price changes)
- Denomination options (fixed vs variable)
- Multi-country/regional catalog support
- Catalog metadata (brand logos, descriptions, terms)

### 2. Order & Fulfillment Agent
**Scope**: Placing and fulfilling gift card orders

**Sub-domain agents to spawn**:

#### 2a. Digital/E-Gift Sub-Agent
- Real-time digital delivery
- Delivery mechanism (API response, email, SMS)
- Card code format and security
- Customization (messaging, branding)

#### 2b. Physical Gift Card Sub-Agent (if applicable)
- Physical card ordering
- Shipping and tracking
- Activation flow
- Bulk ordering

**Base Requirements**:
- API-driven order placement
- Batch/bulk ordering
- Order status tracking
- Order cancellation/reversal
- Real-time vs async fulfillment

### 3. Funding & Pricing Agent
**Scope**: How orders are paid for, pricing models

**Base Requirements**:
- Prepaid vs postpaid funding model
- Discount/margin structure per brand
- FX handling for international brands
- Balance/credit management
- Invoice and billing cycle

### 4. Redemption & Lifecycle Agent
**Scope**: What happens after the gift card is delivered

**Base Requirements**:
- Balance check API
- Transaction history per card
- Card expiry policies
- Partial redemption support
- Card status (active, redeemed, expired, voided)

### 5. Reconciliation & Reporting Agent
**Scope**: Financial reconciliation and reporting

**Base Requirements**:
- Transaction reports via API
- Settlement reconciliation
- Unused/expired card reporting
- Dispute/chargeback handling

**Category-Specific Red Flags**:
- No real-time digital fulfillment (async-only with long delays)
- Limited catalog (<50 brands for target market)
- No batch/bulk ordering
- Card codes returned in plain text without encryption
- No order cancellation or reversal mechanism
- Postpaid-only funding (no balance/prepaid option)
- No programmatic catalog access (portal-only browsing)

## Category-Specific Questions Template

1. How many brands are available in [target country]?
2. What is the average fulfillment time for digital gift cards?
3. What is the discount/margin structure?
4. Is funding prepaid or postpaid? Can we maintain a balance?
5. How are catalog updates communicated (webhook, polling, manual)?
6. What happens when a brand is discontinued mid-order?
7. Can gift card codes be retrieved later if the initial delivery fails?
8. What is the return/cancellation policy?
9. Are there minimum order quantities or values?
10. How is FX handled for international brands?
