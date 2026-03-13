---
category: crypto-stablecoin
display_name: Crypto / Stablecoin
keywords: crypto, stablecoin, blockchain, wallet, USDC, USDT, digital assets, conversion, trading
---

# Crypto / Stablecoin Vendor Assessment

## Level 2 Domain Agents

### 1. Wallet Management Agent
**Scope**: Creating and managing wallets/accounts for holding crypto

**Base Requirements**:
- Programmatic wallet creation
- Multi-currency wallet support (different chains, different tokens)
- Balance inquiry per wallet
- Wallet address generation
- Wallet status lifecycle
- Internal transfers between wallets (move funds between own wallets)
- Wallet activation flow (self-service vs manual/account-manager gated)

### 2. Payments & Transfers Agent
**Scope**: Sending and receiving crypto payments

**Sub-domain agents to spawn**:

#### 2a. Inbound Payments Sub-Agent
- Receiving crypto payments (deposit addresses, payment channels)
- Payment detection and confirmation
- Confirmation thresholds (how many block confirmations?)
- Overpayment/underpayment handling

#### 2b. Outbound Payments Sub-Agent
- Sending crypto to external wallets
- Fee estimation and handling (who pays gas/network fees?)
- Transaction speed options (priority fees)
- Batch/bulk transfers

**Base Requirements**:
- API-driven send and receive
- Transaction status tracking
- Multi-chain support (which blockchains?)
- Supported tokens/coins list

### 3. Conversions & Trading Agent
**Scope**: Converting between crypto and fiat, or between crypto assets

**Base Requirements**:
- Crypto-to-fiat conversion
- Fiat-to-crypto conversion
- Crypto-to-crypto swaps
- Quote/rate retrieval before execution
- Rate lock duration (how long is a quote valid?)
- Slippage handling
- Conversion limits (min/max)
- Automated conversion rules (e.g., auto-convert incoming crypto to fiat)
- Fee/spread transparency in conversion quotes

### 4. Fiat On/Off Ramp Agent
**Scope**: Moving money between traditional banking and crypto

**Base Requirements**:
- Bank transfer to fund crypto wallet
- Crypto to bank withdrawal
- Supported fiat currencies
- Settlement times for fiat movements
- Wire vs ACH vs SEPA support

### 5. Compliance & Regulatory Agent
**Scope**: Crypto-specific compliance requirements

**Base Requirements**:
- Travel Rule compliance (FATF)
- Transaction monitoring / AML screening
- Sanctions screening on wallet addresses
- Reporting capabilities (SAR, CTR equivalents)
- Jurisdiction restrictions (which countries supported?)
- Licensing information (money transmitter, VASP, etc.)

**Category-Specific Red Flags**:
- No multi-chain support (locked to one blockchain)
- No fiat off-ramp (can't convert back to traditional currency)
- Unclear fee structure (hidden fees in conversion rates)
- No Travel Rule compliance (regulatory risk)
- Single stablecoin support only (e.g. USDT but not USDC)
- No programmatic conversion (portal-only trading)
- Custody model unclear (who holds the private keys?)
- No batch/bulk operations is a **Concern** (not Red Flag) for crypto vendors -- Tremendous can decompose orders into individual API calls via async job queues

**Note on custody jargon**: When reporting custody model, define terms for the reader:
- **Omnibus custody**: All customers' crypto pooled in a single wallet/account, with virtual segregation in the vendor's ledger. If vendor becomes insolvent, legal claim to specific funds may be unclear.
- **Segregated custody**: Each customer's crypto in a separate wallet. Clearer ownership but higher operational cost.
- **Qualified custodian**: A regulated entity (e.g., Fireblocks, Anchorage) that holds the private keys under regulatory oversight.

## Category-Specific Questions Template

These questions should always be investigated. The self-answering phase must attempt to answer each one from public docs before including in the vendor questions document.

1. Which blockchains/networks are supported?
2. Which stablecoins/tokens are supported?
3. What is the custody model (self-custody, qualified custodian, omnibus)?
4. How are network fees handled (passed through, absorbed, flat fee)?
5. What is the conversion spread/markup?
6. How long are quoted rates locked?
7. What is the settlement time for fiat on/off ramp?
8. Is there Travel Rule compliance for cross-border transfers?
9. What licenses does the vendor hold and in which jurisdictions?
10. How are failed/stuck transactions handled?
11. Does the vendor carry insurance/crime coverage for custodied assets?
12. Can payment rules or automated conversion rules be managed via API?
