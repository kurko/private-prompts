---
name: tremendous-accounting-rd
description: "Generate monthly R&D time allocation for the accounting spreadsheet. Use when asked to 'fill in R&D', 'R&D tracking', 'accounting spreadsheet', or 'time tracking for accounting'."
---

# R&D Time Tracking for Accounting

Generate monthly time allocation percentages per engineer for the R&D accounting spreadsheet. The spreadsheet changes each year — find the current one by checking `#project-engineering-accounting` in Slack (see Step 0b below).

**Canonical instructions:** [Engineering Team & accounting](https://www.notion.so/tremendous/Engineering-Team-accounting-5d1a50ce422e48598515b2482438ab5c) — defines why we track R&D (tax capitalization + R&D tax credit), what counts as R&D activity, the two-spreadsheet structure (projects DB + monthly allocations), and that EMs update in the first week of each month. Managers are excluded from tracking. When in doubt about whether something qualifies as R&D, refer to this doc.

Known spreadsheets:
- **2025:** [2025 Engineering Team Accounting](https://docs.google.com/spreadsheets/d/1t0FNsliYBHToe57rDB4mtFEEJnNHaHfU2wu8In6gAmY/edit?gid=0#gid=0)
- **2026:** [2026 Engineering Team Accounting](https://docs.google.com/spreadsheets/d/19V1okuVnfi20DbYwIcd9QmK6LoF1V7rXaQ6KuFbP55E/edit?gid=2132556610#gid=2132556610)

## Objective

Pull Asana tasks and OOO data for a target month, group them into spreadsheet-compatible project categories, and output percentage allocations per engineer. The output maps directly to columns in the spreadsheet.

## Configuration

Update these values when team composition or Asana structure changes.

**Team: Catalog** (Manager: Alex Oliveira)

| Engineer | Country | Asana GID |
|---|---|---|
| Vinicius Barboza | Brazil | `1199708178186870` |
| Victor Antoniazzi | Brazil | `1204547985434746` |
| Victor David Santos | Brazil | `1200341780572475` |
| Julie Mao | US | `1205266575630349` |
| Julie Miller | US | `1207919732271562` |
| Filipe Costa | Brazil | `1204163251557610` |

**Asana IDs:**

| Resource | GID |
|---|---|
| Workspace | `752389237742425` |
| Team Catalog board | `1201647585774820` |
| Support rotation schedule | `1211885557232421` |
| Support tickets board | `1198207191493787` |

## Workflow

### Step 0: Determine target month

Run `date` to get today's date. The target month is the **previous calendar month** unless the user specifies otherwise. If ambiguous, ask using AskUserQuestion. Confirm with the user: "Generating R&D tracking for [Month Year]. Correct?"

Compute: `month_start` (first day) and `month_end` (last day) of the target month.

### Step 0b: Check `#project-engineering-accounting` for the latest instructions

Before gathering data, read the latest message from Taylor in `#project-engineering-accounting`. Use `slack-readonly-cli search "in:#project-engineering-accounting from:taylor" --count 5`.

Extract and report to the user:
- **Current spreadsheet URL** (changes yearly — update the "Known spreadsheets" list above if a new year's sheet appears)
- **Suggested deadline** for the current month
- **Any month-specific instructions** — Taylor sometimes adds new requirements. Examples from past months:
  - "Substantially complete" column added to the Projects tab (managers should mark projects as complete or ongoing; complete ones get removed next month; maintenance after completion goes under "General Maintenance/Non-Capitalizable Time")
  - Earlier deadlines when switching from estimates to actuals
  - New team members or projects that need to be added to the sheet

If the latest message contains new instructions that affect how percentages should be calculated or how the spreadsheet should be filled, flag them prominently to the user before proceeding.

### Step 1: Verify service access (MANDATORY, hard stop on failure)

Before any data gathering, verify that both Asana and Notion are accessible. Do NOT use subagents for this step (Asana MCP calls can hang indefinitely inside subagents). Run the checks directly:

1. **Asana check:** Call `mcp__asana__asana_typeahead_search` with workspace `752389237742425`, query `"Vinicius"`, resource_type `user`. This is a fast call that confirms Asana connectivity. Do NOT use `asana_search_tasks` for the check (it can hang).
2. **Notion check:** Call `mcp__notion__notion-search` for "Engineering Calendar" with `content_search_mode: "workspace_search"`. **CRITICAL: You MUST use `workspace_search` mode.** The default `ai_search` mode returns empty results. The Engineering Calendar database ID is `21e266b7-da09-43ab-a307-efe19b4943d8`. Then call `mcp__notion__notion-fetch` with that ID to confirm read access.

**If either service fails: STOP IMMEDIATELY.** Report which service is inaccessible and do not proceed. The user must fix access before continuing. Do not attempt to generate a report with partial data, as the output will be unreliable (non-capitalizable percentages will be wildly inflated without Notion OOO data).

### Step 1b: Verify engineer GIDs (first run only)

If any engineer GID in the config above is "TBD", use `mcp__asana__asana_typeahead_search` to look up each engineer by name in workspace `752389237742425`, resource_type `user`. Once verified, tell the user to update this file with the correct GIDs so future runs skip this step.

### Step 2: Gather data (parallel subagents)

Spawn **one Opus subagent per engineer** in parallel. Each subagent receives:
- The engineer's name, country, and Asana GID
- The target month date range
- The project mapping rules (read `references/project-mapping.md` in this skill directory)
- The holiday list for their country (read `references/holidays-and-ooo.md` in this skill directory)

**Each subagent must:**

1. **Search Asana tasks** using `mcp__asana__asana_search_tasks`:
   - `workspace`: `752389237742425`
   - `assignee_any`: engineer's GID
   - Search for tasks where work happened during the target month. Use `modified_on.after` and `modified_on.before` with the month boundaries.
   - Do NOT filter by project (this captures tasks across all boards: Team Catalog, Support, Class-Action, etc.)
   - Request `opt_fields`: `name,completed,completed_at,created_at,start_on,assignee.name,projects.name,parent.name,permalink_url,custom_fields`
   - For tasks with a parent, note the parent name (helps group subtasks)

2. **Detect support rotation** by searching project `1211885557232421` for assignments to this engineer in the target month. Also search project `1198207191493787` for support tickets assigned to them.

3. **Search Notion for OOO** (each subagent searches independently for resilience). Use `mcp__notion__notion-fetch` with the Engineering Calendar database ID `21e266b7-da09-43ab-a307-efe19b4943d8` to get calendar entries. Alternatively, use `mcp__notion__notion-search` with query matching the engineer's name AND `content_search_mode: "workspace_search"` (NEVER use `ai_search` mode, it returns empty). Look for entries matching this engineer in the target month. Extract: date range, type (PTO, holiday, medical, offsite). If a Notion call fails, retry up to 2 times before reporting the failure.

4. **Check the public holiday list** for the engineer's country in `references/holidays-and-ooo.md`. Count working days lost to holidays.

5. **Categorize each task** using the mapping rules in `references/project-mapping.md`:
   - Map to a spreadsheet column name
   - Estimate effort as fraction of the month
   - Flag tasks that do not map cleanly to any existing column

6. **Calculate percentages** per the rules below.

7. **Return structured data:**
   - Summary table: Category | Est. % | Project Description
   - Asana tasks table: Task name | URL | Started | Completed | Category
     - **Started**: Use `start_on` if set; otherwise fall back to `created_at`. Check custom fields for a `started_at` field as well.
     - **Completed**: Use `completed_at`. Show "In Progress" if not completed.
   - OOO breakdown: PTO days, holiday days, support rotation days
   - Flagged/ambiguous tasks needing user decision
   - Total non-capitalizable %

   **Project Description column guidance:** The "Project Description" in the summary table is NOT a list of task names. It is a 2-3 sentence project-level description written for accounting, explaining what the engineering work involves and why it qualifies as R&D. It should read like a Project tab entry on the R&D spreadsheet. Focus on:
   - The engineering domain and scope (e.g., "Improving class action disbursement flows" not "bypass fix, reminder emails, campaign editing fixes")
   - What makes the work technically novel (e.g., "designing new campaign management patterns," "reverse-engineering undocumented API behavior," "building a new shared abstraction layer")
   - The R&D percentage context from `references/project-mapping.md` (e.g., "100% R&D" or "~70% R&D, ~30% routine maintenance")
   
   Individual task names belong in the Asana tasks table, not the Project Description.

### Step 3: Assemble and present

After all subagents return:

1. **Open the report with a single "Start here" block that categorizes EVERY flagged item by the ACTION it requires, as a scannable table.** Alex finds this task high-cognitive-load and actively dislikes it; he wants to know in seconds what needs him. A flat bullet list of "flags" failed twice because decision-items and FYI-items looked identical and he had to read all of them to find the one that needed a choice. Requirements:
   - **First line: a one-sentence load summary** so he knows the scope before reading anything. E.g. "Your load: 1 decision, 2 columns to create. Then fill the grid and sign off." If there are no decisions, say so explicitly: "No decisions needed; 1 column to create."
   - **Then a table with columns `Action | Item | Where`.** The Action column uses exactly one of these labels so his eye can filter on it:
     - **DECIDE** - needs his judgment and blocks sign-off. Phrase the Item as a yes/no or A/B question with your recommended answer stated inline, so accepting is one glance.
     - **CREATE** - mechanical setup, no judgment: a column to add, a Project-tab row to paste, a status to set. Point to the paste-ready content below.
   - The `Where` column names the section with the detail (e.g. "Vinicius section", "Project tab"). **Keep every Item to ONE line**; push all reasoning into the per-engineer sections, never into this table.
   - Do NOT put FYI rows in this table. Everything with no required action goes in a short **"FYI (no action)"** section at the very BOTTOM, one line each.
   - NEVER present as DECIDE: a column to create, a Project-tab row to paste, a confirmed finding, or a borderline mapping where you applied a sensible default (state the default under FYI). If it does not block sign-off and needs no judgment, it is not a DECIDE.
   (Feedback from the May 2026 run: "categorize by action... I had to read all of them to understand if I needed to decide on anything. My cognitive load on this task is very high.")

2. **Per-engineer detail sections** with:
   - Summary % table (Category | Est. % | Project Description). The Project Description column should contain accounting-ready descriptions that explain the R&D nature of the work, not task-level bullet lists. These descriptions should be reusable as Project tab entries on the spreadsheet.
   - Asana tasks table with URLs (this is where individual task names go)
   - OOO section

3. **Spreadsheet-ready summary table** using EXACT column names from the spreadsheet:

```
| Engineer | [Project Col 1] | [Project Col 2] | ... | Non Capitalizable |
|---|---|---|---|---|
| Vinicius Barboza | 45% | 35% | ... | 10% |
```

Each row should sum to ~100%.

4. **Quick reference: Non-capitalizable % per engineer**

```
| Engineer | PTO | Holidays | Support Rotation | Total Non-cap |
|---|---|---|---|---|
```

### Step 4: Save output

Save the full report to `~/work/core/ai-notes/r&d-tracking-{month}-{year}.md` (e.g., `r&d-tracking-jan-2026.md`).

## Calculation rules

- **Baseline:** 1 month = ~4 weeks = ~20 working days. Always use 20 as the denominator, regardless of actual weekday count for the month.
- **1 day off = 5%, 1 week = 25%**
- **Support rotation:** Count working days on rotation. ALL support rotation time is non-capitalizable, including any tickets worked during rotation.
- **Task effort estimation:**
  - Full-month or primary project: estimate by relative weight
  - Tasks completed in a few days: ~5-10%
  - Subtasks under a parent: aggregate under the parent project
  - Tasks under 2-3 days: group with related tasks
- **Non-capitalizable items:** PTO, public holidays, support rotation, company offsites, onboarding/training with no R&D output
- **Percentages must sum to ~100%** per engineer. Round to nearest 5%.
- **When in doubt, lean toward R&D.** Engineers do planning, code review, investigation, and architectural work that doesn't always produce Asana tasks. Gaps between tasks are NOT automatically PTO or maintenance. Only classify time as non-capitalizable when there is positive evidence (Notion OOO entry, support rotation assignment, public holiday). Flag uncertainty for the user but default the percentage toward R&D, not non-capitalizable.

## Rules

- **Subagent architecture is mandatory.** One subagent per engineer. The orchestrator must not load Asana task data into its own context.
- **Use Opus model** for all subagents. These outputs feed into tax accounting.
- **Every Asana task must include its URL** for fact-checking.
- **Read-only.** Never write to Slack, Asana, or Notion.
- **Reference previous month's output.** Reports live in two places: `orgs/tremendous/accounting/R&D YYYY-MM.md` (vault, canonical) and `~/work/core/ai-notes/r&d-tracking-*.md` (legacy). Check both; prefer the vault copy. Read the most recent report before assembling output for column name consistency. **Also read user comments/edits** in the previous month's report — the user may have corrected project names, adjusted percentages, added/removed columns, or left notes about what they actually used. Apply those corrections to the current month.
- **Asana search scope:** Search the whole workspace filtered by assignee + date range. Do NOT limit to the Team Catalog board only, as engineers may have tasks on support, class-action, or other boards.
- **Asana timeouts:** Set `max_turns` to 15 for subagents that call Asana tools to prevent hanging.
- **No fallback mode.** If Asana or Notion is inaccessible, stop completely. Do not generate partial reports. The January 2026 test run showed that without Notion OOO data, non-capitalizable percentages were inflated by 20-35% per engineer.

## Feedback incorporation

After each run, the user may provide corrections like:
- "Task X should be under column Y"
- "Create a new column for Z"
- "Group A and B together"

When this happens, update `references/project-mapping.md` with the correction so future runs use it automatically.

## Reference files

- `references/project-mapping.md` - Task-to-column mapping rules and known projects
- `references/holidays-and-ooo.md` - Public holidays by country, OOO detection logic
- Previous output: `~/work/core/ai-notes/r&d-tracking-jan-2026.md` (January 2026 for format reference)
- **Slack channel `#project-engineering-accounting`** - Monthly instructions from Taylor (accounting). Check before every run for deadline and month-specific requirements. Use `slack-readonly-cli` to read.
