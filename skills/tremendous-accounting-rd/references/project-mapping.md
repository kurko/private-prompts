# Project Mapping Rules for R&D Spreadsheet

How Asana tasks map to columns in the R&D accounting spreadsheet.

## Principles

1. **Reuse existing columns.** The user strongly prefers not to create new project columns in the spreadsheet. Before suggesting a new column, check if the work fits an existing one.
2. **Vendor work follows a naming pattern.** On the Catalog team, vendor integrations map to "Vendor New Integration ({Vendor Name})" or a similar existing column.
3. **Group small tasks.** Tasks under ~3 days of effort that do not belong to a named project: group under the nearest related project or combine as "Other Team Catalog tasks."
4. **Flag, do not guess.** When a task does not fit any existing column, flag it for the user with the task name, URL, and a suggested column name. Let the user decide.

## Known spreadsheet columns

Use these EXACT names in output. This table is updated after each monthly run based on user feedback.

### Project columns

| Spreadsheet Column Name | Matching Asana Work |
|---|---|
| Vendor New Integration (Cash App) | Cash App vendor integration tasks |
| Vendor New Integration (Apple Wallet) | Apple Wallet / Add to Wallet - Apple tasks |
| Vendor New Integration (Google Wallet) | Google Wallet / Add to Wallet - Google tasks |
| Vendor New Integration (Galileo) | Galileo prepaid card integration, config consolidation |
| Vendor New Integration (Nium) | Nium international bank transfer tasks |
| W9 | W9 compliance / tax form tasks |
| Webhooks Interface | Webhook-related feature work |
| Draft orders | Draft order feature work |
| Campaign index redesign | Campaign index UI/backend work |
| Catalog reward minimums | Reward minimum threshold tasks |
| NetSuite Integration | NetSuite accounting integration tasks |
| Class action flows enhancements | Class action claim flow improvements |
| Catalog product descriptions | Product description management tasks |
| Vendor Idempotency | Vendor idempotency / deduplication tasks |
| Add to Wallet | Combined Apple+Google wallet work (when not split by vendor) |
| International Prefund Balances | International prefund balance management |
| Settlement Windows | Settlement window configuration tasks |

### Non-capitalizable column (always present)

| Column Name | What goes here |
|---|---|
| Non Capitalizable Projects (General Maintenance / PTO, Parental Leave, Etc) | PTO, holidays, support rotation, parental leave, offsites, general maintenance not tied to an R&D project |

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
| "Galileo" (not a support ticket) | Vendor New Integration (Galileo) |
| "Visa" or "Visa::" | Vendor New Integration (Visa) or nearest vendor column |
| "Nium" (not a support ticket) | Vendor New Integration (Nium) |
| "Apple wallet" or "Add to wallet - Apple" | Vendor New Integration (Apple Wallet) |
| "Google wallet" or "Add to wallet - Google" | Vendor New Integration (Google Wallet) |
| "Add to wallet" (generic) | Add to Wallet |
| "Cash App" | Vendor New Integration (Cash App) |
| "Tillo" | Check if a Tillo vendor column exists, else flag |
| "Amazon" | Check if "Vendor New Integration (Amazon)" exists, else flag |
| "address" or "Address standardization" | Check if column exists, else flag |
| "MCC" or "MCC Restrictions" | Check if column exists, else flag |
| "prepaid card" | Map to relevant vendor (Galileo, Visa) based on context |
| "webhook" | Webhooks Interface |
| "W9" or "tax form" | W9 |
| "NetSuite" | NetSuite Integration |
| "idempotency" (vendor context) | Vendor Idempotency |
| "settlement" | Settlement Windows |
| "intl bank transfer" or "international" (payout) | International Prefund Balances |
| "product description" | Catalog product descriptions |
| "reward minimum" | Catalog reward minimums |
| "class action" or "claim" | Class action flows enhancements |

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
