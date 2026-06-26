---
name: tremendous-exception-task
description: Turn a Sentry exception alert into a well-structured Asana task. Use when Alex pastes a Slack link from #bot-exceptions-backend, a Sentry issue URL, or says "make a task for this exception", "track this Sentry error", "create an Asana task from this alert", "turn this exception into a task". Investigates the Sentry issue and the code, writes the task with the team's conventions, and creates it in the Team Catalog project with Vendor/Priority/Status set.
argument-hint: "[slack-permalink-or-sentry-url]"
---

# Exception → Asana Task

Alex monitors `#bot-exceptions-backend` (Slack channel `C0906JG9N1G`), where a
Sentry bot posts backend exception alerts. When one is worth tracking, he
investigates and files an Asana task in **Team Catalog**. This skill automates
that: ingest the alert, investigate, write the task, create it.

## What you receive

One of these (the user usually pastes a single link):

- **A Slack permalink** to a thread in `#bot-exceptions-backend` — the richest
  input. The parent message is the Sentry bot alert (contains the Sentry issue
  link, error class, culprit); replies often contain human triage ("probably
  not actionable?", "should we swallow it?", a cc to someone). Read the whole
  thread — the discussion shapes the task's framing and priority.
- **A Sentry issue URL** directly — no Slack discussion, just the issue.
- **Both** — use both.

If you get a Slack link, extract the Sentry URL from the thread. If you only get
a Sentry link, proceed without Slack context.

## Step 1 — Read the inputs

Read every link before writing anything. The links are the primary data, not
background confirmation.

**Slack thread** (if given a Slack link):
```bash
~/.private-prompts/bin/slack-readonly-cli message "<slack-permalink>"
```
This returns the single message. To get the full thread, use the parent
`thread_ts` it reports with the channel id:
```bash
~/.private-prompts/bin/slack-readonly-cli message "C0906JG9N1G:<thread_ts>"
```
The parent message's blocks contain the Sentry issue link (look for
`tremendous-y0.sentry.io/issues/<id>`), the error class, and the culprit
(e.g. `Sidekiq/ExecutePayoutWorker`). Capture human replies — they tell you
whether this is noise to swallow, a real bug, or already understood.

**Sentry issue:**
```bash
~/.claude/skills/tool-sentry/sentry-readonly-cli "<sentry-issue-url>"
```
This prints the error, the in-app stacktrace (your code first), event/user
counts, first/last seen, tags (`queue`, `transaction`, `release`,
`retry_count`), and breadcrumbs (the HTTP call / SQL that preceded the crash).
Note the **event count and time window** — "4 events, all within 2 seconds,
stopped" is a transient blip; "94 events since December, still growing" is a
regression. This distinction drives priority.

## Step 2 — Investigate the code

The Sentry stacktrace names in-app frames with file:line. Read them to find the
root cause, following the team's "claims are coordinates" rule — verify what the
code actually does rather than trusting the error message. For vendor errors,
the relevant client is usually under `lib/catalog_vendors/<vendor>/client.rb`
and the calling service under `app/services/<vendor>/`. Confirm:

- What call failed and why (e.g. a 404 on `POST /payments`).
- Whether it is handled, retried, or swallowed today (look at `raise_on_error`,
  the error class raised, and how `ErrorHandlingService` / the worker treats it).
- Whether it self-resolves or sits in a retry loop forever.

Keep the investigation proportional to the task. A transient blip needs a
sentence of root cause; a systematic bug warrants tracing the retry flow.

## Step 3 — Detect the vendor

Map the exception to the **Vendor** custom field when it is vendor-specific.
Infer the vendor from, in order of reliability:

1. The file path: `lib/catalog_vendors/<vendor>/...` → that vendor.
2. The error message ("Unexpected response from Hyperwallet…").
3. The Sentry `queue` tag (e.g. `rate_limited_hyperwallet_high`).

Match the name (case-insensitive) to the Vendor option GID in
[reference.md](reference.md). If the exception is not tied to a vendor (a
generic app error), leave Vendor unset.

## Step 4 — Judge priority, status, and tags

Use judgment grounded in the Sentry signal and the Slack discussion. Defaults
below match how Alex files a fresh "track this" exception (the two lightweight
examples were both Low / Ready for work). Escalate when impact is real.

| Signal | Priority | Status | Notes |
|--------|----------|--------|-------|
| Transient blip, self-resolved, low volume | **Low** | Ready for work | Default. Often just needs error handling / noise suppression. |
| Ongoing regression, growing event count | **Medium/High** | Ready for work | Real bug. |
| Actively blocking payouts / money movement | **High** | Ready for work | Trace the full flow; recipients are affected. |
| Thread says "not actionable, should we swallow it?" | **Low** | Ready for work or Monitoring | Frame the task as: silence the noise or add handling. |
| Cause unclear, needs a human call | Low/Medium | Requires discussion | |

Set **Tag** (multi-select) when an obvious one fits — `bug`, `observability`
(noise/alerting), `incident-remediation`, `bug prevention`, `vendors`. Leave it
unset rather than forcing a poor fit; the lightweight examples had no tag.
Leave **Eng estimate** unset unless the scope is genuinely obvious.

GIDs for every field and option are in [reference.md](reference.md).

## Step 5 — Write the task body

Follow the team's `write-task` skill conventions (the `/write-task` skill is the
source of truth for prose style — short vs full template, tl;dr rules, Asana
HTML formatting). Key points for this skill:

- **Title**: `Exception: <concise description>` for a tracking ping (e.g.
  "Exception: Hyperwallet 404 on POST /payments"), or a problem-focused title
  for a deeper bug (e.g. "Galileo errors out with non-ASCII email addresses").
  Make it scannable in a list of 50+ items.
- **Template choice**: short (Background + Proposed changes) for a transient
  blip or simple noise-suppression; full (tl;dr + Background + Why is it
  important? + Proposed changes) for a systematic bug or anything that will sit
  in the backlog needing context.
- **Always include the Sentry and Slack links** at the bottom as `<a>` links —
  every example task does. Format with `html_notes`.
- **Asana HTML**: use `<b>` for section headers (not `<h2>` — it adds ugly
  spacing), real newlines (not `<br/>`), `<code>` for identifiers, `<ul>/<li>`
  sparingly. Bold the `tl;dr` label.

Do not paste Sentry screenshots — attaching images needs an upload step; the
Sentry link is sufficient.

## Step 6 — Create the task in Asana

Create with `asana_create_task`. Fixed values:

- `project_id`: `1201647585774820` (Team Catalog)
- `section_id`: `1206602220889093` (**Quick wins**) for a lightweight tracking
  task; `1202971212086474` (**Up next**) or `1203904722071016` (**Backlog**)
  for something with more scope. Default to Quick wins for exception pings.
- `assignee`: leave unset (these go in unassigned, like the examples) unless
  the user says otherwise.
- `html_notes`: the body from Step 5.
- `custom_fields`: a JSON string mapping field GID → value (option GID for
  enums, array for the multi-select Tag). See [reference.md](reference.md) for
  the exact shape. Always set Vendor (when detected), Priority, and Status.

After creating, report the new task's `permalink_url` back to the user, state
which template you used and why, and summarize the Vendor/Priority/Status you
set so a wrong inference is easy to spot.

## Step 7 — Offer the Slack reply (opt-in)

Alex's manual flow usually ends by replying in the Slack thread, e.g. "I created
a task to track, but not urgent." Posting to a shared channel is outward-facing,
so **do not post automatically** — offer it, and only post on explicit
confirmation, using the Slack MCP tool `slack_reply_to_thread` (per
CLAUDE.local.md, never raw curl). Keep the reply short and link the task.

## Notes

- This skill **reads** Slack and Sentry and **writes** one Asana task. The only
  outward action (Slack reply) is gated behind confirmation.
- If the Sentry issue can't be fetched (token missing), tell the user to set
  `SENTRY_AUTH_TOKEN` per the `tool-sentry` skill, and continue with whatever
  Slack context you have rather than guessing at the stacktrace.
- Workspace GID for all Asana calls: `752389237742425`.
