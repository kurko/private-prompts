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
| Vendor New Integration (Nium, int'l bank transfer) | Nium international bank transfer tasks, new Nium features (RFI alerts, new currency support) |
| Catalog vendor refactor | Architectural rewrite: shared interfaces, base classes, vendor contract patterns |
| MCC Restrictions (Galileo) | MCC/MID restricted prepaid cards: pilot, GA release, automation |
| Class action flows inhancements | Class action claim flow improvements, Selection-at-Claim, campaign management |
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
| Settlement Windows | Settlement window configuration tasks |

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
| "Galileo" (ambiguous, not support ticket) | Flag for user — could be either New or Improvements |
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
| "intl bank transfer" or "international" (payout) | Vendor New Integration (Nium, int'l bank transfer) |
| "product description" | Catalog product descriptions |
| "reward minimum" | Catalog reward minimums |
| "class action" or "claim" or "selection-at-claim" | Class action flows inhancements |
| "address" or "Address standardization" | Catalog addresses |
| Seeds improvements, retry logic, timeout investigation | Vendor Integration Improvements |
| Venmo/PayPal/Zelle exploratory work | Vendor Integration Improvements |

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
- 2026-04 (Mar run): "Other Team Catalog tasks" must be split into specific spreadsheet columns before entering data. Don't use it as a single bucket — map to MCC Restrictions, Catalog product descriptions, Vendor Integration Improvements, etc.
- 2026-04 (Mar run): Don't include column numbers in the skill file — they shift when new columns are added to the spreadsheet. Use column names only.
