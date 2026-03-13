# Tremendous Domain Model

Use this context to detect mismatches between a vendor's data model and Tremendous's model.

## Key Domain Concepts

| Concept | Description |
|---------|-------------|
| **Organization** | A company that uses Tremendous to send rewards/payments. Has members, funding sources, campaigns. |
| **Member** | A user within an organization. Has roles and permissions. |
| **Order** | A batch of rewards/payments created by an organization. Contains multiple rewards. |
| **Reward** | A single payment/gift within an order. Has a recipient, product, amount. |
| **Recipient** | The person receiving a reward. Identified by email or phone. May receive from many organizations. |
| **Funding Source** | How the organization pays: bank account, credit card, or balance. |
| **Campaign** | A template for how rewards are delivered (branding, products available, messaging). |
| **Product / Catalog Item** | What can be sent: gift card, prepaid card, bank transfer, PayPal, Venmo, etc. |

## Common Mismatch Patterns to Flag

### 1:1 Beneficiary-per-Customer
- **Tremendous model**: A recipient can receive rewards from many organizations. Recipients are not "owned" by one organization.
- **Red Flag if**: Vendor requires creating a unique beneficiary per customer/organization. This creates data duplication and complicates recipient management.

### No Batch Operations
- **Tremendous model**: Orders contain many rewards (sometimes thousands). We need bulk creation and processing.
- **Concern if**: Vendor only supports single-item operations. We'd need to loop and manage our own batching.

### KYC Scope Mismatch
- **Tremendous model**: KYC is performed at the organization level, not per-recipient.
- **Concern if**: Vendor requires KYC per recipient/beneficiary. This would add friction for every reward sent.

### Co-mingled Funds
- **Tremendous model**: Organizations have their own funding sources and balances. Funds must be clearly separated.
- **Red Flag if**: Vendor co-mingles funds across customers or has a pooled model without clear attribution.

### Fund Movement
- **Tremendous model**: We need programmatic fund movement (prefunding, withdrawals, balance management).
- **Concern if**: Fund movement requires manual intervention, emails, or portal-only actions.

### Currency Handling
- **Tremendous model**: We deal with multiple currencies. Use Money objects with explicit currency codes.
- **Concern if**: Vendor assumes a single currency or has unclear FX handling.

### Status/Lifecycle Mapping
- **Tremendous model**: Rewards have clear lifecycle states (created, sent, delivered, redeemed, etc.).
- **Concern if**: Vendor's status model doesn't map cleanly to our lifecycle, or has ambiguous intermediate states.
