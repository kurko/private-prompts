---
name: tremendous-accounting-rd
description: "Generate monthly R&D time allocation for the accounting spreadsheet, and find, review, or fix existing monthly R&D reports and the sheet's Project tab. Use when asked to 'fill in R&D', 'R&D tracking', 'accounting spreadsheet', 'time tracking for accounting', 'the accounting for <month>', 'where is the R&D report', 'project tab', or to settle decisions in an R&D report."
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

Alex manages **two teams** since the Catalog split on 2026-08-03: **Catalog** and **Prepaid Cards**. One report covers both; all engineers below sit in Alex's block on the monthly tab.

**Roster (per Alex, 2026-09-15; Dionne confirmed 2026-10-06 — include these engineers moving forward):**

| Engineer | Team | Country | Asana GID | Notes |
|---|---|---|---|---|
| Victor Antoniazzi | Prepaid Cards | Brazil | `1204547985434746` | Moved from Catalog 2026-08-03. Focus: Paynetics (EU/UK prepaid program) |
| Sarah Laine | Prepaid Cards | US | `1215477244324838` | Moved from Catalog 2026-08-03. Started 2026-06-08 |
| Emily Ayers | Prepaid Cards | US | `1206356018012780` | Joined Alex's team 2026-08-03 (previously Chloe Isacke's). First included: August 2026 run. Taking over Add to Wallet from Filipe (gradual handoff, Aug 2026) |
| Victor David Santos | Catalog | Brazil | `1200341780572475` | |
| Julie Mao | Catalog | US | `1205266575630349` | |
| Julie Miller | Catalog | US | `1207919732271562` | Still finalizing prepaid-cards projects started before the team split (Galileo ledger, etc.) |
| Filipe Costa | Catalog | Brazil | `1204163251557610` | Handed Add to Wallet to Emily during Aug 2026 (worked side by side); handoff time on the project counts as project R&D |
| Dionne Stanfield | Catalog | US | `1216099555672581` | Started July 2026 (July was her ramp month). Her row was missing from the July and August tabs; check it exists and tell Alex to add it if not |

**Excluded:**

| Engineer | Country | Asana GID | Status |
|---|---|---|---|
| Vinicius Barboza | Brazil | `1199708178186870` | Excluded since July 2026 run (under Britney Wright's block) |

**Team split context:** [Prepaid Cards team kick-off](https://www.notion.so/tremendous/3aeeed2e006880b5ae05c1e01d046241) (Notion, Aug 2026) — objectives, who owns what, and the Add to Wallet handoff plan.

**Asana IDs:**

| Resource | GID |
|---|---|
| Workspace | `752389237742425` |
| Team Catalog board | `1201647585774820` |
| Team Prepaid Cards board | `1200309809032918` |
| Support rotation schedule | `1211885557232421` |
| Support tickets board | `1198207191493787` |

**Slack:** `#team-prepaid-cards` (team channel) plus per-project channels such as `#project-add-to-wallet` — useful when task evidence is thin.

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

Note on tool naming: the Notion MCP may be exposed as `mcp__claude_ai_Notion__notion-search` / `notion-fetch` (claude.ai connector) instead of `mcp__notion__*`. Use ToolSearch to load whichever exists before calling.

**If either service fails: STOP IMMEDIATELY.** Report which service is inaccessible and do not proceed. The user must fix access before continuing. Do not attempt to generate a report with partial data, as the output will be unreliable (non-capitalizable percentages will be wildly inflated without Notion OOO data).

### Step 1b: Verify engineer GIDs (first run only)

If any engineer GID in the config above is "TBD", use `mcp__asana__asana_typeahead_search` to look up each engineer by name in workspace `752389237742425`, resource_type `user`. Once verified, tell the user to update this file with the correct GIDs so future runs skip this step.

### Step 1c: Pull OOO once (orchestrator)

Query the Engineering Calendar data source directly with ONE SQL call via `notion-query-data-sources` (data source `collection://43c0f83d-daca-45fa-beab-06efceacc415`): select Title, Type, Team, People, and the Dates start/end columns for entries overlapping the target month. From the results derive each engineer's PTO days, public holidays (People lists confirm who observes which holiday), support rotation windows, and offsites. Pass this to each subagent as AUTHORITATIVE OOO so they skip Notion entirely - this proved more reliable than per-subagent Notion searches (June 2026 run).

### Step 1d: Read the sheet once (orchestrator)

With `gog sheets get ... --json`, read:
- The target month tab's header row and Name column, to get current column letters and row numbers. Both move between months (Taylor rebuilds the tab) and within a month (Alex inserts columns and rows while filling).
- The Project tab, columns A-F. Pass each subagent the map of existing project name → Percent R&D. Existing projects keep that rate everywhere in the report (see Step 3, item 3).

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

3. **Use the authoritative OOO from Step 1c** (passed in the subagent prompt). Subagents do NOT query Notion. Only if the orchestrator could not pull the calendar should a subagent fall back to `notion-fetch` with database ID `21e266b7-da09-43ab-a307-efe19b4943d8` (workspace_search mode, never ai_search).

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
   - The R&D percentage: for a project that already has a Project-tab row, state that row's Percent R&D (from the map in Step 1d). Use the category defaults in `references/project-mapping.md` only for proposed new projects. (August 2026: three descriptions said "100% R&D" for Vendor New Integration (Galileo), which is 70% on the Project tab.)
   
   Individual task names belong in the Asana tasks table, not the Project Description.

### Step 3: Assemble and present

After all subagents return:

1. **Open the report with a single "Start here" block that categorizes EVERY flagged item by the ACTION it requires, as a scannable table.** Alex finds this task high-cognitive-load and actively dislikes it; he wants to know in seconds what needs him. A flat bullet list of "flags" failed twice because decision-items and FYI-items looked identical and he had to read all of them to find the one that needed a choice. Requirements:
   - **First line: a one-sentence load summary** so he knows the scope before reading anything. E.g. "Your load: 1 decision, 2 columns to create. Then fill the grid and sign off." If there are no decisions, say so explicitly: "No decisions needed; 1 column to create."
   - **Then a table with columns `Action | Item | Where`.** The Action column uses exactly one of these labels so his eye can filter on it:
     - **DECIDE** - needs his judgment and blocks sign-off. Phrase the Item as a yes/no or A/B question with your recommended answer stated inline, so accepting is one glance. Any change to an existing Project row's Percent R&D is a DECIDE (see item 3).
     - **CREATE** - mechanical setup, no judgment: a column to add, a Project-tab row to paste, a status to set. Point to the paste-ready content below.
   - The `Where` column names the section with the detail (e.g. "Vinicius section", "Project tab"). **Keep every Item to ONE line**; push all reasoning into the per-engineer sections, never into this table.
   - Do NOT put FYI rows in this table. Everything with no required action goes in a short **"FYI (no action)"** section at the very BOTTOM, one line each.
   - NEVER present as DECIDE: a column to create, a Project-tab row to paste, a confirmed finding, or a borderline mapping where you applied a sensible default (state the default under FYI). If it does not block sign-off and needs no judgment, it is not a DECIDE.
   (Feedback from the May 2026 run: "categorize by action... I had to read all of them to understand if I needed to decide on anything. My cognitive load on this task is very high.")

2. **Spreadsheet-ready summary table** - immediately after Start here (tables at the TOP of the document, evidence sections after; Alex works top-down from the doc while filling the sheet). Requirements:
   - EXACT column names from the monthly tab, WITH the tab's column letters in the header (read the monthly tab's header row and name column first to compute letters and row numbers)
   - **No acronyms or initialisms in the header project names** (per Alex, Aug 2026 run): never "CVII", "VNI", "SEA" as a substitute for the name. Spell the project out ("Vendor New Integration (Galileo)", "Catalog Vendor Integration Improvements"). Dropping filler words to shorten is fine; initialisms are not.
   - Engineer INITIALS below each percentage (`60%<br>J Mao`) - Obsidian doesn't freeze the leftmost column when scrolling right, so each cell must self-identify. Initials: VA, VS, J Mao, J Miller, FC, SL, EA, DS (disambiguate the Julies as J Mao / J Miller)
   - Include only columns with values; each row sums to ~100%
   - Keep engineers as rows here, matching the monthly tab. A transposed (projects-as-rows) grid was trialed June 2026 and Alex doesn't use it. The Project-tab section (item 3) is the opposite case: projects as rows, because the Project tab is laid out that way.

3. **Missing Project tab rows** - compare every monthly-tab column that carries a value against the Project tab. List rows that need adding, each paste-ready with: Year, Project name (matching the column EXACTLY), Description (accounting style: what it is + engineering work + why it's R&D), Percent R&D, Status, and **Support link for the Notes column (F)** - the Asana umbrella task URL for the project (other managers do this; Alex wants it standard). Watch for renamed near-duplicates before proposing a row (e.g., "Catalog Vendors Integration Improvements" row = "Catalog Vendor Integration Improvements" column; "International payouts (Nium, int'l bank transfer)" row = the Nium column). Also flag existing rows with blank Status cells and mis-pasted descriptions.
   - **Layout: one table, one row per project, columns in Project-tab order** - `| Year | Project name | Description | Percent R&D | Status | Notes |` (A-F). Alex selects cells across columns in Obsidian reading view and pastes them into the sheet in one go (verified October 2026: all six columns landed in their own cells). A per-project `Field | Value` table forces one paste per cell, so use it only if Alex asks. State the target rows (e.g. "New rows 176-178") from the live Project tab.
   - Fixes to existing rows use the same column order with a leading `Row` column (`| Row | Project name | Description | Percent R&D | Status | Notes |`), so Alex selects Description→Notes and pastes at column C of that row. Put the reason for each fix in a bullet under the table, not in the cells.
   - **Existing Project rows serve every month.** Accounting aggregates all months with the row's current Percent R&D, so changing it (e.g. 70% → 100%) also rewrites every earlier month. Keep the % by default. When the kind of work changed substantially, raise a DECIDE with Alex's two options: (a) a new project (Project row + monthly column) from this month on, or (b) move the % to the halfway point (e.g. 70% → 85%) and say so in the description. Before claiming the work changed, check earlier reports for how long that work has been booked to the project. (August 2026: the Galileo ledger work had been booked to Vendor New Integration (Galileo) at 70% since April, so it was not new.)
   - **Append, don't replace, on existing rows.** Keep the current description and add `Update (Month YYYY): …` at the end; the old text documents the earlier months. Add Notes links next to existing ones; don't swap them out.
   - **Names must match character for character** between each monthly-tab header and its Project row. Flag mismatches as a CREATE to align them (August 2026: "Prepaid card product customization" vs "…customizations", "Incomm" vs "InComm").

4. **Quick reference: Non-capitalizable % per engineer**

```
| Engineer | PTO | Holidays | Support Rotation | Total Non-cap |
|---|---|---|---|---|
```

5. **Per-engineer detail sections** (after all tables) with:
   - Summary % table (Category | Est. % | Project Description). The Project Description column should contain accounting-ready descriptions that explain the R&D nature of the work, not task-level bullet lists. These descriptions should be reusable as Project tab entries on the spreadsheet.
   - Asana tasks table with URLs (this is where individual task names go)
   - OOO section

### Step 4: Save output

Save the full report to the vault (canonical): `orgs/tremendous/accounting/R&D {YYYY}-{MM}.md`, and copy it to the legacy path `~/work/core/ai-notes/r&d-tracking-{month}-{year}.md`. Link the report from today's daily note, then commit and push the vault.

### Step 5: Post-fill review (after Alex enters the numbers)

When Alex says he's filled the sheet, verify his entries cell-by-cell against the report:

1. Re-read the monthly tab; don't reuse the report's letters or row numbers. Alex inserts columns and rows while filling (August 2026: 7 inserted columns moved non-cap from AZ to BG, and Emily moved from row 35 to 51). Read from the header row down in one JSON call and map each filled cell to its header name, selecting Alex's rows by the manager column. Counting empty cells by eye is error-prone:
   ```bash
   gog sheets get <sheet_id> "<Tab>!A<header_row>:<last_col><last_row>" --account work --json > grid.json
   jq -r '.values as $v | $v[0] as $h | $v[1:][] | select(.[2] == "Alex") as $r | [range(5; $r | length)] | map(select($r[.] != "")) | map("\($h[.])=\($r[.])") | "\($r[1]): " + join("; ")' grid.json
   ```
   Compare each line against the report and confirm each row's Total check (column E) is 100%. A value in the wrong column still sums to 100, so check placement, not just totals. June 2026 caught a 5% entered one column left of target and a missing Total formula on a newly inserted row.
2. Check the manager sign-off cell (Alex Oliveira block, top of tab).
3. Re-read the Project tab: confirm new rows were added, Status cells aren't blank, descriptions aren't mis-pasted, and Notes (column F) has the Asana support link.
4. Update the report's "Start here" to reflect what's done vs remaining, and record any user corrections in `references/project-mapping.md`. When Alex answers a DECIDE, mark it DECIDED with the date and update every place that described the options (summary-table note, non-cap quick reference, the engineer's section), so the report shows one answer.

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
- **First month on Alex's team** (new hire or internal transfer): propose a conservative split with a ramp-up share in non-cap, even when PRs shipped ("reduce, don't zero"; Alex adjusts up). Call it ramp-up or "first month on the team". If the start date falls after the month's first working day, the days before it also go to non-cap (Sarah, June 2026). The second month gets no ramp discount unless the output shows one. Precedents: Dionne July 2026 (35/15/50), Emily August 2026 (70% non-cap).
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
- Previous output: the most recent `orgs/tremendous/accounting/R&D YYYY-MM.md` in the vault (format reference; the format has changed a lot since January 2026)
- **Slack channel `#project-engineering-accounting`** - Monthly instructions from Taylor (accounting). Check before every run for deadline and month-specific requirements. Use `slack-readonly-cli` to read.
