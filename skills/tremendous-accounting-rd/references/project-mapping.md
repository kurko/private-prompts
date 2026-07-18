# Project Mapping Rules for R&D Spreadsheet

How Asana tasks map to columns in the R&D accounting spreadsheet.

## Principles

1. **Reuse existing columns.** The user strongly prefers not to create new project columns in the spreadsheet. Before suggesting a new column, check if the work fits an existing one.
2. **Vendor work follows a naming pattern.** On the Catalog team, vendor integrations map to "Vendor New Integration ({Vendor Name})" or a similar existing column.
3. **Group small tasks.** Tasks under ~3 days of effort that do not belong to a named project: group under the nearest related project or combine as "Other Team Catalog tasks."
4. **Flag, do not guess.** When a task does not fit any existing column, flag it for the user with the task name, URL, and a suggested column name. Let the user decide.

## Spreadsheet structure

The R&D spreadsheet has one tab per month, each with the same column layout. Columns are added over time as new projects start. The Project tab contains descriptions and R&D percentages that accounting uses for capitalization memos.

### "New Integration" vs "Integration Improvements"

The spreadsheet distinguishes between building new vendor capabilities and improving existing ones. This distinction matters for R&D capitalization:

- **Vendor New Integration (Galileo/Nium/Apple Wallet/Google Wallet/Cash App)**: New features, new vendor launches, new product categories. 100% R&D.
- **Vendor Integration Improvements**: Reactive maintenance and improvements across all vendors. Mix of novel (reverse-engineering undocumented APIs, building new error states) and routine (known fix patterns, timeouts, incident response). ~70% R&D.
- **Vendor Integration Improvements (Galileo)**: Same as above but Galileo-specific. Used for ledger debugging, anomaly monitors, transaction fixes. ~70% R&D.
- **Vendor Integration Improvements (Amazon)**: Amazon-specific reactive work. ~70% R&D.
- **Catalog vendor refactor**: Architectural rewrite of vendor integration code (namespace refactor, shared interfaces, new base classes). 100% R&D.

**How to classify Galileo work:**
- Prepaid card namespace refactor, new GalileoManager, new shared interfaces, bulk cards → "Vendor New Integration (Galileo)"
- Ledger mismatch debugging, anomaly monitors, transaction ID fixes, auth response code changes → "Vendor Integration Improvements (Galileo)"
- MCC restricted cards → "MCC Restrictions (Galileo)" (separate column)

### Known spreadsheet columns

Use these EXACT names in output. This table is updated after each monthly run based on user feedback.

### Project columns (100% R&D)

| Spreadsheet Column Name | Matching Asana Work |
|---|---|
| Vendor New Integration (Cash App) | Cash App vendor integration tasks |
| Vendor New Integration (Apple Wallet) | Apple Wallet / Add to Wallet - Apple tasks |
| Vendor New Integration (Google Wallet) | Google Wallet / Add to Wallet - Google tasks |
| Vendor New Integration (Galileo) | Galileo prepaid card integration: namespace refactor, new managers, bulk cards |
| Vendor New Integration (Nium, int'l bank transfer) | Nium international bank transfer tasks, new Nium features (RFI alerts, new currency support). NIUM ONLY - Zelle/US Bank is a separate column, do not fold it here |
| Catalog - Zelle | Zelle payouts via US Bank: US Bank API client, mTLS auth, enrollment checks, order create/retrieve, balance lookups, UsBankManager, funds movement. This is a US Bank integration, NOT Nium (column named "Catalog - Zelle" by Alex, June 2026) |
| Catalog vendor refactor | Architectural rewrite: shared interfaces, base classes, vendor contract patterns |
| MCC Restrictions (Galileo) | MCC/MID restricted prepaid cards: pilot, GA release, automation |
| Catalog Venmo username | Venmo-specific product work (username confirmation, handle payouts) |
| Class action flows enhancements | Class action claim flow improvements, Selection-at-Claim, campaign management |
| Catalog product descriptions | Product description management tasks, API exposure |
| Catalog reward minimums | Reward minimum threshold tasks |
| Catalog addresses | Address standardization, address entity work |
| Catalog and payout monitoring | Monitoring improvements across vendor payouts |
| Catalog product subcategories | Product categorization, data structure changes |
| W9 | W9 compliance / tax form tasks |
| Webhooks Interface | Webhook-related feature work |
| Draft orders | Draft order feature work |
| NetSuite Integration | NetSuite accounting integration tasks |
| Vendor idempotency (Galileo) | Vendor idempotency / deduplication tasks |
| Catalog Wallet Products (SEA) | Making SEA digital wallets (GCash, DANA, GoPay, OVO, ShopeePay) publicly available: pricing tiers, catalog recategorization, fee calculation, custom pricing migration |
| Looking Glass | AI-facing read-only endpoints for inspecting Rails data (payouts, merchant cards, prepaid cards) |
| Consumer business fake door test | Big-bet initiative validating recipient interest in a new consumer line of business (Britney Wright's initiative; Vinicius worked it May 2026) |
| Visa products selector refactor | Refactor of the hard-coded Visa/prepaid card product selection logic into configurable, data-driven abstractions (Julie Miller, started May 2026). Do NOT fold this into Vendor New Integration (Galileo) - it has its own column per Alex, June 2026 |
| Settlement Windows | Settlement window configuration tasks |
| Stablecoin Payouts | Stablecoin/crypto payout method exploration and in-product testing |
| Vendor New Integration (Galileo Bulk Cards) | Galileo bulk physical card issuance with Arroweye embossing: card issuance, tracking, notifications, direct shipping |
| Vendor New Integration (Onbe) | International prepaid card routing via Onbe: substitution/routing engine issuing Onbe CAD/GBP/EUR cards to international recipients instead of US-issued Visa cards (Victor Antoniazzi, started June 2026) |
| Prepaid card custom images | Client-uploaded custom logos/images on Visa prepaid card recipient pages: org-level logo storage, admin CRUD, Branded Visa modal, recipient rendering, demo flows (Sarah Laine, started June 2026) |

### Project tab descriptions for new columns

When a new column is added, a corresponding row must be added to the **Project tab** with a description that makes the R&D nature apparent to accounting/auditors, plus the project's **Asana umbrella task URL in the Notes column (F)** as a support link (standard since July 2026; other managers do the same). Use this style (one paragraph, what it is + engineering work + why it's R&D):

| Column | Year | Description | % R&D |
|---|---|---|---|
| Vendor New Integration (Galileo Bulk Cards) | 2026 | Building a bulk physical card issuance pipeline through Galileo and Arroweye embossing. Engineers designed the card issuance integration, shipment tracking ingestion from the embossing vendor, email notification delivery for bulk orders, and LAP (Letters and Parcels) direct shipping validation. The work involves integrating two vendor APIs (Galileo for card issuance, Arroweye for physical embossing/fulfillment) with different data formats and coordinating end-to-end card lifecycle across both systems. | 100% |
| Stablecoin Payouts | 2026 | Exploration and in-product testing of stablecoin (cryptocurrency) as a new payout method for reward recipients. Engineers are evaluating the technical feasibility of integrating blockchain-based payment rails into the existing payout infrastructure, designing the recipient redemption experience, and building in-product test flows to validate the approach before committing to a full integration. This is a new payment category with no existing vendor patterns to reuse. | 100% |

### Project columns (~70% R&D)

| Spreadsheet Column Name | Matching Asana Work |
|---|---|
| Vendor Integration Improvements | Generic catch-all for reactive vendor work across all vendors: bug fixes, Wogi issues, retry logic, timeout investigations, Venmo/PayPal exploratory work, misc catalog tasks that don't fit a specific column |
| Vendor Integration Improvements (Galileo) | Galileo-specific reactive work: ledger debugging, balance mismatches, anomaly monitors, auth code fixes |
| Vendor Integration Improvements (Amazon) | Amazon-specific reactive work |

### Non-capitalizable column (always present)

| Column Name | What goes here |
|---|---|
| General Maintenance / Non Capitalizable Time (PTO, Parental Leave, Ect) | PTO, holidays, support rotation, parental leave, offsites, general maintenance not tied to an R&D project |

### Splitting "Other Team Catalog tasks"

The R&D report uses "Other Team Catalog tasks" as a catch-all. Before entering into the spreadsheet, this must be split into specific columns:

- Vendor-specific bug fixes (Wogi, Xoxoday, etc.) → "Vendor Integration Improvements"
- MCC restrictions work → "MCC Restrictions (Galileo)"
- Product description work → "Catalog product descriptions"
- Reward minimums work → "Catalog reward minimums"
- Address-related work → "Catalog addresses"
- Product subcategories → "Catalog product subcategories"
- Monitoring improvements → "Catalog and payout monitoring"
- Venmo/PayPal exploratory work → "Vendor Integration Improvements"
- If none of the above fit → "Vendor Integration Improvements" as generic catch-all

## Mapping heuristics

### By Asana project membership

| Asana Project (GID) | Default Column |
|---|---|
| Team Catalog (`1201647585774820`) | Map by task/parent name to a specific project column |
| Support rotation (`1211885557232421`) | Non Capitalizable |
| Support tickets (`1198207191493787`) | Non Capitalizable |

### By task name patterns

| Pattern in task name | Maps to |
|---|---|
| "Galileo" + refactor/namespace/shared interface/manager/bulk cards | Vendor New Integration (Galileo) |
| "Galileo" + ledger/mismatch/anomaly/transaction fix/auth code | Vendor Integration Improvements (Galileo) |
| "Galileo" (ambiguous, not support ticket) | Flag for user - could be either New or Improvements |
| "MCC" or "MCC Restrictions" or "restricted cards" | MCC Restrictions (Galileo) |
| "Visa" or "Visa::" (bug fix) | Vendor Integration Improvements |
| "Nium" + new feature (RFI alerts, new currency) | Vendor New Integration (Nium, int'l bank transfer) |
| "Nium" + bug fix/webhook/NSF/timeout | Vendor Integration Improvements |
| "Apple wallet" or "Add to wallet - Apple" | Vendor New Integration (Apple Wallet) |
| "Google wallet" or "Add to wallet - Google" | Vendor New Integration (Google Wallet) |
| "Cash App" | Vendor New Integration (Cash App) |
| "Wogi" or "Xoxoday" or "Tillo" or other vendor bug | Vendor Integration Improvements |
| "prepaid card" + refactor/namespace | Vendor New Integration (Galileo) or Catalog vendor refactor |
| "prepaid card" + bug/fix | Vendor Integration Improvements (Galileo) |
| "webhook" | Webhooks Interface |
| "W9" or "tax form" | W9 |
| "NetSuite" | NetSuite Integration |
| "idempotency" (vendor context) | Vendor idempotency (Galileo) |
| "settlement" | Settlement Windows |
| "intl bank transfer" or "international" (payout, Nium) | Vendor New Integration (Nium, int'l bank transfer) |
| "Zelle" or "US Bank" or "UsBankManager" or "US Bank API client" | Catalog - Zelle - NEVER Nium |
| "product description" | Catalog product descriptions |
| "reward minimum" | Catalog reward minimums |
| "class action" or "claim" or "selection-at-claim" | Class action flows inhancements |
| "address" or "Address standardization" | Catalog addresses |
| Seeds improvements, retry logic, timeout investigation | Vendor Integration Improvements |
| Venmo/PayPal/Zelle exploratory work | Vendor Integration Improvements |
| "Venmo" + username/handle/confirmation | Catalog Venmo username |
| "stablecoin" or "crypto" (payout context) | Stablecoin Payouts |
| "bulk cards" or "Arroweye" or "embossing" or "LAP direct shipping" | Vendor New Integration (Galileo Bulk Cards) |
| "wallet products" or "GCash" or "DANA" or "GoPay" or "OVO" or "ShopeePay" or "SEA wallets" | Catalog Wallet Products (SEA) |
| "Looking Glass" or "AI agents to inspect Rails data" | Looking Glass |

### Support rotation and tickets

ALL work done during a support rotation period is non-capitalizable, regardless of what the ticket involves. This includes:
- The rotation assignment itself (project `1211885557232421`)
- Individual tickets worked (project `1198207191493787`)

Do not split support rotation time across R&D columns.

## Edge cases

- **Tech debt / refactoring tied to a project:** If a refactoring task (e.g., "TilloClient: improve signature generation") is clearly part of ongoing vendor work, attribute it to that vendor's column.
- **Tech debt / refactoring NOT tied to a project:** Group under nearest related project or flag for user.
- **Bug fixes:** If the fix is part of a named project (e.g., fixing a Galileo issue during integration), attribute to that project. Standalone production bugs are maintenance (non-capitalizable unless R&D is involved).
- **Investigations:** Investigative tasks ("Investigate why X") are part of the project they relate to. If unrelated, flag for user.
- **Cross-project work:** When an engineer works on multiple vendor integrations, split percentage based on relative effort.
- **Subtasks:** Aggregate under the parent task's project mapping.

## Feedback log

After each monthly run, update this section with mapping corrections from the user.

<!-- Add corrections below as they come in, format: YYYY-MM: correction -->
- 2026-02 (Jan run): Gaps between Asana tasks are NOT PTO. Engineers do code review, planning, and investigation that doesn't appear as tasks. Only mark time as non-capitalizable with positive evidence (Notion OOO, support rotation assignment, public holiday). Default uncertain time toward R&D.
- 2026-02 (Jan run): Victor D Santos's tadmin bank redaction fix and data pull for product announcement are project-adjacent R&D work, not maintenance.
- 2026-02 (Jan run): Filipe Costa's Google Wallet blocked time is still R&D (planning/investigation counts). Don't classify blocked-by-vendor time as non-capitalizable.
- 2026-02 (Jan v3 run): Asana MCP `asana_search_tasks` can hang indefinitely. Use `asana_typeahead_search` for the access check (fast, reliable). Do NOT spawn subagents for the access check step.
- 2026-02 (Jan v3 run): Notion `ai_search` mode returns empty for "Engineering Calendar". MUST use `workspace_search` mode. The database ID is `21e266b7-da09-43ab-a307-efe19b4943d8`.
- 2026-04 (Mar run): The spreadsheet distinguishes "Vendor New Integration" (new features, 100% R&D) from "Vendor Integration Improvements" (reactive/maintenance, ~70% R&D). Galileo has both columns. Map refactor/new-feature work to New, ledger/bug-fix work to Improvements.
- 2026-04 (Mar run): "Other Team Catalog tasks" must be split into specific spreadsheet columns before entering data. Don't use it as a single bucket - map to MCC Restrictions, Catalog product descriptions, Vendor Integration Improvements, etc.
- 2026-04 (Mar run): Don't include column numbers in the skill file - they shift when new columns are added to the spreadsheet. Use column names only.
- 2026-05 (Apr run): Summary tables per engineer must list categories in alphabetical order to match the spreadsheet's column layout. General Maintenance/Non-cap always goes last.
- 2026-05 (Apr run): When a new column is needed, include a copy-pasteable Project tab entry (Year, Project name, Description, Percent R&D, Status) in the report so the user can add it directly.
- 2026-05 (Apr run): Read the previous month's report in the vault for user edits/corrections before assembling the new month.
- 2026-05 (Apr run): User prefers dedicated project columns over the "Catalog Vendor Integration Improvements" catch-all. When an engineer's R&D time is dominated by one identifiable project (e.g., Venmo username work, Looking Glass), create a specific column for it rather than lumping it into the generic bucket.
- 2026-05 (Apr run): User classified smaller miscellaneous tasks (Nexamp investigation, fee passing, Xoxoday webhooks, Davinci refactor, Zelle brief) as non-capitalizable rather than forcing them into "Catalog Vendor Integration Improvements." When tasks are small and don't clearly tie to a named R&D project, the user may prefer non-cap over a generic R&D catch-all. Flag these for the user rather than auto-assigning to Vendor Improvements.
- 2026-05 (Apr run): "Class action flows inhancements" spelling was fixed to "Class action flows enhancements" in the April tab.
- 2026-05 (Apr run): New columns added in April: "Catalog Venmo username", "Catalog Wallet Products (SEA)", "Looking Glass", "Stablecoin Payouts", "Vendor New Integration (Galileo Bulk Cards)". Column layout is now fully alphabetical.
- 2026-06 (May run): `asana_search_tasks` with modified_on filters silently under-returns - it missed Victor S's Zelle/US Bank subtasks and Julie Miller's high-priority "Visa products selector refactor". Have subagents verify each engineer's in-progress umbrella tasks via get_task/stories, and have the orchestrator cross-check the month's eng update (`notes/ai-tasks/Monthly Eng Update - *.md` in the vault) before assembling.
- 2026-06 (May run): Check which manager block each engineer sits in on the monthly tab before assembling - Vinicius Barboza appeared under Britney Wright's block (Consumer business fake door test 38%), with his row pre-filled by Britney on a 21-weekday basis. Reconcile splits with the other manager instead of overwriting.
- 2026-06 (May run): Company offsites (e.g., Lisbon Engineering offsite May 18-22) are non-capitalizable for ALL engineers - 25% on the 20-day basis. The Notion calendar entry is Company-wide with empty People; it still applies to everyone.
- 2026-06 (May run): "Vendor New Integration (Cash App)" column exists on the 2026 sheet - Cash App Direct work (Julie Mao) maps there.
- 2026-06 (May run, post-review): Zelle/US Bank is its OWN column, which Alex created and named "Catalog - Zelle" (NOT "Vendor New Integration (...)", NOT Nium). The April report wrongly folded Zelle into "Vendor New Integration (Nium, int'l bank transfer)". Any "Zelle", "US Bank", "UsBankManager" task → "Catalog - Zelle". Nium int'l is for Nium only.
- 2026-06 (May run): SEA wallets ("Make wallet products publicly available") had zero May engineering - blocked in "Waiting for product" Apr 20-Jun 2. Don't allocate blocked-and-idle months to the project (different from actively-blocked time where planning continues).
- 2026-06 (May run, post-review): Alex created a dedicated "Visa products selector refactor" column. Julie Miller's May split: selector refactor 10%, Vendor New Integration (Galileo) 5% (ledger generic workers only). Card-product-selector work never goes under VNI (Galileo).
- General lesson (May run): when a project doesn't fit an existing column, Alex would rather create a NEW dedicated column than fold it into a loosely-related existing one (Zelle into Nium, selector into Galileo were both wrong). Default to proposing a new column with a paste-ready Project tab description, not a forced fit.
- 2026-06 (May run, post-review): Report format - lead with "Decision needed" (only true decisions, with recommendations); missing columns/Project-tab rows are NOT decisions, Alex creates them himself and only needs the paste-ready description; push everything informational to a one-line-per-item FYI section at the bottom.
- 2026-07 (Jun run): The June tab renamed the selector column to "Catalog - Visa products selector refactor" (with the "Catalog -" prefix). Use the monthly tab's exact spelling each month.
- 2026-07 (Jun run): Nium INR/UPI re-enablement ("New Nium errors - INR") stays under "Catalog Vendor Integration Improvements" (May precedent), NOT Vendor New Integration (Nium).
- 2026-07 (Jun run): Victor A's Galileo uniqueness-token work maps to "Catalog Vendor Integration Improvements (Galileo)" - the Project tab's 2025 "Vendor Idempotency" row has no monthly column.
- 2026-07 (Jun run): New columns added: "Vendor New Integration (Onbe)" and "Prepaid card custom images". New-hire partial months: pre-employment days go to non-cap so the row sums to 100% on the 20-day basis (Sarah Laine, started Jun 8).
- 2026-07 (Jun run): Production soft-launch follow-ups (Cash App, closed Jun 2-16) are still R&D, not post-completion maintenance - Taylor's maintenance rule applies only after substantial completion.
- 2026-07 (Jun run, post-fill): Report FORMAT (confirmed preferences): (1) Document order: Start here → spreadsheet-ready summary table → missing Project-tab rows → non-cap quick ref → per-engineer detail sections. Tables at the TOP, evidence after. (2) The spreadsheet-ready table (engineers as rows) is the one Alex uses; the transposed layout was dropped. Include the monthly tab's column LETTERS in the table header AND the engineer's INITIALS below each percentage (`85%<br>J Miller`) because Obsidian doesn't freeze the leftmost column when scrolling right. Initials: VA, VS, J Mao, J Miller, FC, SL (disambiguate the Julies with J Mao / J Miller). (3) Compare monthly-tab columns that carry values against the Project tab and list ALL missing Project rows with paste-ready descriptions - watch for renamed near-duplicates ("Catalog Vendors Integration Improvements" row vs "Catalog Vendor Integration Improvements" column are the same project).
- 2026-07 (Jun run, post-fill): After Alex fills the sheet, REVIEW his entries cell-by-cell against the report using narrow gog ranges (wide ranges make empty-cell counting error-prone). June caught: a 5% entered one column left of target (AP53 Bulk Cards instead of AQ53 Nium RFI), and the Total-check formula missing on a newly inserted row (E57). Also verify the manager sign-off cell.
- 2026-07 (Jun run): Orchestrator can query the Notion Engineering Calendar data source (`collection://43c0f83d-daca-45fa-beab-06efceacc415`) with one SQL call via notion-query-data-sources for ALL June OOO entries, then pass authoritative OOO to subagents - more reliable than per-subagent Notion searches. Check the manager blocks AND the Project tab for mis-pasted descriptions (June: "Catalog - Zelle" row contained the selector refactor text; Cash App Project row from May was never pasted).
