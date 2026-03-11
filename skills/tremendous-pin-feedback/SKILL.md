---
name: tremendous-pin-feedback
description: Record feedback or praise for team members to Google Sheets for perf reviews. Use when the user wants to pin feedback, record praise, note someone's contribution, or save a highlight about a team member.
argument-hint: "[slack-or-asana-url]"
---

# Pin Team Member Feedback

Record feedback highlights for team members to use in performance reviews.

## CRITICAL: Read-Only Slack Access

**NEVER write to Slack under any circumstances.** This skill is strictly read-only for Slack:
- ✅ Read thread replies, channel history, user profiles
- ❌ Never post messages, reply to threads, or add reactions

The only write operation this skill performs is posting to the Google Sheet.

## Workflow

1. **Validate input** - If no URL and no description is provided in the arguments, stop immediately and ask the user to provide at least one.
2. **Get the source URL** from the user (Slack thread, Github PR, Asana task, Jira, Notion document and more)
3. **Fetch the content** using an available CLI (e.g gh) or MCP tools (see Slack fallback below)
4. **Follow linked URLs** found in the content to gather deeper context (see Deep Link Traversal below)
5. **Resolve the team member's full name** (see Member Name Resolution below)
6. **Generate feedback text** - 1-2 paragraphs of specific praise or constructive feedback
7. **Post to the sheet** using the script

## Fetching Slack Content

### Primary: MCP Tools (read-only)

Use these MCP tools when available:
- `mcp__slack__slack_get_thread_replies` - Get thread content
- `mcp__slack__slack_get_channel_history` - Get recent channel messages
- `mcp__slack__slack_get_users` / `mcp__slack__slack_get_user_profile` - Resolve user names

### Fallback: Slack Search API

The Slack MCP does not include `search:read` scope. If you need to search for messages
(e.g., finding a thread by keyword rather than URL), use the Slack API directly:

```bash
curl -s "https://slack.com/api/search.messages?query=<encoded-query>" \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN"
```

The `SLACK_BOT_TOKEN` is available in the environment (sourced from `~/.secrets`).

**Search query tips:**
- `in:#channel-name` - Search within a specific channel
- `from:@username` - Messages from a specific user
- `after:2024-01-01` - Date filtering

Response includes `messages.matches[]` with `permalink`, `text`, `user`, `ts`, and `channel`.

## Deep Link Traversal

After fetching the primary source, **scan the content for linked URLs** and follow them to build richer context. This is critical for writing high-quality feedback — a Slack message alone rarely tells the full story.

### How it works

1. **Fetch the primary source** (e.g., a Slack thread).
2. **Scan the fetched content** for URLs pointing to other systems: GitHub PRs, Asana tasks, Notion pages, Jira tickets, other Slack threads, etc.
3. **Follow each link using a subagent.** Spawn a `general-purpose` subagent for each linked URL. Give the subagent a clear, specific prompt so it returns exactly what you need.
4. **Follow transitive links.** If a GitHub PR description links to an Asana task, the subagent MUST follow that link too. Common chains:
   - Slack thread → GitHub PR → Asana task (linked in PR description)
   - Slack thread → Asana task → subtasks or related tasks
   - Asana task → GitHub PR (linked in comments)

### Subagent prompt template for link traversal

When spawning subagents to follow links, use a prompt like:

```
Fetch the content at [URL] and return:
1. **Who** did the work (full name of the author/assignee)
2. **What** was done (summary of the change, task, or discussion)
3. **Impact** — any mentions of why this matters, who it unblocks, or what problem it solves
4. **Linked URLs** — any URLs in the content that point to other systems (GitHub, Asana, Slack, etc.) that I should also follow for more context

For GitHub PRs: read the PR title, description, and linked issues/tasks. Check for Asana/Linear/Jira links in the description.
For Asana tasks: read the task name, description, and comments. Note the assignee and any subtasks.
For Slack threads: read all replies and note substantive interactions.

Be concise. Return facts, not opinions.
```

### What NOT to follow

- Links to dashboards, monitoring, or documentation (unless they describe the work done)
- Links to CI/CD runs or deployment logs
- External links (vendor docs, blog posts, etc.)

## Context Gathering

When reading the source content (including content from followed links), extract and note:

### Project/Feature Name
Identify the project or feature name from:
- Slack: channel name (especially `#project-*` channels, e.g., `#project-wallet` → "Wallet"), thread topic, or explicit project mentions in the message text
- Asana: task name or project name
- GitHub PR: repository name or PR title
- The content itself (look for project names, feature names, or initiative titles)

This name **must** appear in the first sentence of the feedback to provide future context.

### Interactions from Others
When reading threads, comments, or replies (Slack, Asana, GitHub, Jira, Linear, etc.), note responses from others that add substance.

A reply is **substantive** if it describes an impact, asks a question, or adds new information. Encouragement-only replies ("great job", "keep it up", "love it", "thanks for the update") should be ignored.

- ✅ Include: feedback that describes impact ("this helped me plan X"), questions that show engagement, additional context or information
- ❌ Ignore: simple "thank you" or encouragement messages, especially from Alex Oliveira, unless they add specific context
- ❌ Ignore: emoji reactions alone

If substantive interactions exist, summarize them at the end of the feedback (e.g., "In this case, John Doe noted that the update helped them plan their work accordingly.").

## Career Ladder Context

Before writing feedback, spawn an Explore subagent to read the career ladder at:
`~/.private-prompts/skills/tremendous-pin-feedback/career-ladder.md`

This document describes the four competencies we value at Tremendous:
1. **Independence** - acting autonomously, unblocking self, shipping quality work quickly
2. **Project management** - proactive communication, timeline awareness, collaboration
3. **Complexity** - handling technical depth, business domain understanding
4. **Leverage** - code reviews, mentoring, unblocking others, cross-team impact

Use these competencies to frame the feedback. When praising or giving constructive feedback, connect the observed behavior to these competencies where relevant.

## Feedback text format

Summarize this linked content conversation focusing on praising (positive) or
providing feedback (negative) on the person's work on it, one or two paragraphs.

Why are we doing this? This snippet will be used to write their cycle review
later in the year.

### Rules
- Don't use the recipient's name, instead write it in the second person (You)
- **Write from the first person perspective ("I").** These feedback snippets will be copied into perf review documents written by the user. Any reference to the user's own observations, praise, or context should use "I" (e.g., "I noticed your improvement in..." not "Alex noticed your improvement in..."). Never refer to the user by name in the third person.
- **Always include the project/feature name in the first sentence** to provide context for future reading (e.g., "Your work on the Payments Integration project..." or "This message in the Rewards API project...")
- When writing feedback, avoid making specific assumptions about implementation details that aren't explicitly stated.
- Use general language for technical work (e.g., 'submitted clean code' rather than 'submitted a pull request', or 'delivered the feature' rather than 'opened PRs') unless I have provided those specific details.
- Keep the tone professional but warm, not overly formal. I mean, just write like I would.
- For positive feedback, let's tone down words like "excellent", unless I mention it. I don't want it to denote perfection.
- Use professional language suitable for perf reviews
- **If others provided substantive feedback in the thread**, add a sentence at the end summarizing their input (e.g., "Notably, Jane mentioned this helped her plan the QA timeline.")

### Input
The user will provide key focus areas:

- [Person's name]: a hint only (often dictated via voice, may be first name only). You MUST always resolve the full name from the source — see Member Name Resolution below.
- [What they did / context]:
    - If provided, make those areas more prominent
    - If not provided and it's self evident, you can come up with your own feedback, positive or negative.

Write 2-3 paragraphs that:
- Observed: Are specific about what the person did
- Impact: Explain the impact or why it matters
- Start with a tag like `[Positive; P5]` or `[Constructive; P4]` where P4-P5 indicates priority/significance
- Ask: How they could have done it differently.

## Required Environment Variables

The script requires these environment variables to be set in the shell:

- `GSHEET_PUSH_APP_URL` - Google Apps Script web app URL
- `GSHEET_PUSH_APP_SECRET` - Secret key for authentication

## Posting

Use the included script (same directory as skill):

```bash
~/.private-prompts/skills/tremendous-pin-feedback/scripts/post-feedback.sh "<note>" "<member-name>" "<url>"
```

Arguments:
- `note`: The feedback text (1-2 paragraphs). Make sure to escape quotes.
- `member-name`: The team member's full name, lowercased (see Member Name Resolution below)
- `url`: Source URL (Slack thread or Asana task)

The script automatically adds the current timestamp.

## Member Name Resolution

**This is critical. The `member-name` MUST always be the person's full name (first + last), lowercased. Never use a first name alone — it is ambiguous (e.g., there are multiple Victors on the team).**

Resolution rules:
1. **Always resolve the full name from the source**, regardless of what the user says. The user's input (often dictated via voice) may mention a first name only — this is a hint, not the final answer. You MUST cross-reference against the source (Slack profile, Asana user, GitHub author) to get the full name.
   - **Slack**: Call `mcp__slack__slack_get_user_profile` with the user ID. Use the `real_name` field (it always contains the full name). Do NOT use `display_name` — it may be a first name only.
   - **Asana**: The API returns the user's full name in `created_by.name`.
   - **GitHub**: Use the commit author or PR author's full name.
2. **If the source doesn't resolve a full name** (e.g., no URL provided, or the API only returns a first name), and you cannot determine the last name from context, append a flag: e.g., `"victor [last name unclear]"`. Never silently use a first name alone.
3. **Final format**: lowercase the full name. Examples: `"victor antoniazzi"`, `"sarah johnson"`, `"vinicius barboza"`.
4. **Never abbreviate, shorten, or use nicknames.** The sheet uses full names to identify people.

## Example

```bash
~/.private-prompts/skills/tremendous-pin-feedback/scripts/post-feedback.sh \
  "[Positive; P5] Your project update on the Apple / Google Wallet integration is a good example of the improvement in how you communicate status to the team. The message is clear about where things stand with both vendors, with context that helps everyone understand quickly what's happening (like 'we're just middle man here'). This consistent, frequent communication style makes it easy for the whole team to stay informed without needing to ask. Notably, Jane mentioned that the update helped her plan the QA timeline for next sprint." \
  "sarah johnson" \
  "https://tremendous-rewards.slack.com/archives/C01234/p1234567890"
```
