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
4. **Identify the team member** being highlighted
5. **Generate feedback text** - 1-2 paragraphs of specific praise or constructive feedback
6. **Post to the sheet** using the script

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

## Context Gathering

When reading the source content, extract and note:

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
- Don't use their name, instead write it in the second person (You)
- **Always include the project/feature name in the first sentence** to provide context for future reading (e.g., "Your work on the Payments Integration project..." or "This message in the Rewards API project...")
- When writing feedback, avoid making specific assumptions about implementation details that aren't explicitly stated.
- Use general language for technical work (e.g., 'submitted clean code' rather than 'submitted a pull request', or 'delivered the feature' rather than 'opened PRs') unless I have provided those specific details.
- Keep the tone professional but warm, not overly formal. I mean, just write like I would.
- For positive feedback, let's tone down words like "excellent", unless I mention it. I don't want it to denote perfection.
- Use professional language suitable for perf reviews
- **If others provided substantive feedback in the thread**, add a sentence at the end summarizing their input (e.g., "Notably, Jane mentioned this helped her plan the QA timeline.")

### Input
The user will provide key focus areas:

- [Person's name]: if not provided, you can fallback/rely on the URL's authorship
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
- `member-name`: Team member's name (lowercase, matches Slack display name)
- `url`: Source URL (Slack thread or Asana task)

The script automatically adds the current timestamp.

## Example

```bash
~/.private-prompts/skills/tremendous-pin-feedback/scripts/post-feedback.sh \
  "[Positive; P5] Your project update on the Apple / Google Wallet integration is a good example of the improvement in how you communicate status to the team. The message is clear about where things stand with both vendors, with context that helps everyone understand quickly what's happening (like 'we're just middle man here'). This consistent, frequent communication style makes it easy for the whole team to stay informed without needing to ask. Notably, Jane mentioned that the update helped her plan the QA timeline for next sprint." \
  "sarah" \
  "https://tremendous-rewards.slack.com/archives/C01234/p1234567890"
```
