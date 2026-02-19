---
name: tremendous-accounting-rd
description: "Generate monthly R&D time allocation for the accounting spreadsheet. Use when asked to 'fill in R&D', 'R&D tracking', 'accounting spreadsheet', or 'time tracking for accounting'."
---

# R&D Time Tracking for Accounting

Generate monthly time allocation percentages per engineer for the [R&D accounting spreadsheet](https://docs.google.com/spreadsheets/d/1t0FNsliYBHToe57rDB4mtFEEJnNHaHfU2wu8In6gAmY/edit?gid=0#gid=0).

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
   - Request `opt_fields`: `name,completed,completed_at,created_at,assignee.name,projects.name,parent.name,permalink_url`
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
   - Summary table: Category | Est. % | Notes (with task URLs)
   - Asana tasks table: Task name | URL | Status
   - OOO breakdown: PTO days, holiday days, support rotation days
   - Flagged/ambiguous tasks needing user decision
   - Total non-capitalizable %

### Step 3: Assemble and present

After all subagents return:

1. **Present flagged items first.** Ambiguous project mappings, tasks that need a new column, edge cases. Resolve these with the user BEFORE showing the final tables.

2. **Per-engineer detail sections** with:
   - Summary % table
   - Asana tasks table with URLs
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
- **Reference previous month's output** in `~/work/core/ai-notes/` for column name consistency. Read the most recent `r&d-tracking-*.md` file before assembling output.
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
