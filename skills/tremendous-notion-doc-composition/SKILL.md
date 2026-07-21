---
name: tremendous-notion-doc-composition
description: "Compose a document in Alex's private Notion Documents database. Use when Alex says /tremendous-notion-doc-composition, or asks to write, draft, or start a doc in Notion — for example 'write a doc about X in Notion', 'draft this in Notion', 'put this in my docs database'. Also use when he asks where a doc should live, or shares a page from the Documents database."
argument-hint: "<doc topic or source material>"
---

# Notion Doc Composition

Alex writes his working documents in one private Notion database. This skill puts new docs
in that database, with the right properties, in his voice.

## Where docs go

| Item | Value |
|---|---|
| Database | **Documents** — https://app.notion.com/p/3cbb8d8d6d4d4a11b387807ad7e1787e |
| Data source | `collection://1f280be5-fa2e-4d39-94d1-c155edd39d08` |
| Parent page | Alex Private Notes |

Create the page with `notion-create-pages`, and pass the data source above as the parent.
Do not create the page anywhere else. Do not create a new database.

## Properties

Set these on every new doc.

**Status: `drafting`.** Always. This is the whole point of the database: a doc starts as a
draft that Alex then edits. Never set `drafted`, `in review`, or `done` yourself. Those
states record his judgement of the work, not yours.

The full list, so you recognise the states when you read an existing doc:

| Group | Values |
|---|---|
| To-do | `not started`, `paused`, `next` |
| In progress | `drafting`, `in progress`, `drafted`, `in review` |
| Complete | `done`, `archived` |

**Name.** A short, specific title. Say what the doc is about, not what kind of doc it is.
"How to write to vendors" beats "Vendor communication document".

**Tags.** A multi-select. Pick from this fixed list only; do not invent a new tag:

`review-cycle`, `research`, `direction`, `people`, `retrospective`, `decision-tracking`,
`report`, `alignment`, `feedback`

Pick one or two. If none fits, leave Tags empty and say so.

## Voice

**Load the `alex-writing-at-work` skill before you write the body.** The doc must read as
his writing, not as generic AI prose. The database template is intentionally blank, so
there is no fixed structure to follow: let the content decide the shape.

## Drafting is not posting

The vault rule says never post to Notion unless Alex says "send it" or "post it". This
database is the exception, and only this database. It is his private drafting space, so
writing here **is** the draft. Creating the page is the deliverable.

The rule still holds for everything else:

- Do not move the doc out of this database.
- Do not share it, add collaborators, or publish it to the web.
- Do not copy its content into a team space, a Slack channel, or an Asana task.
- Do not change the Status past `drafting`.

If Alex wants the doc somewhere else, he will say so.

## Steps

1. Gather the source material. Open every link he gives you first.
2. Load `alex-writing-at-work`.
3. Draft the body.
4. Create the page in the Documents data source, with `Status: drafting`, a specific Name,
   and one or two Tags.
5. Give him the page URL, the Name, and the Tags you chose. Name any tag you considered and
   rejected, so he can correct you in one line.

## Reporting

State plainly what you created and where. For example:

> Created **How to write to vendors** in Documents, `Status: drafting`, tagged `alignment`.
> https://app.notion.com/p/...
> I considered `research` as well, but the doc argues a position rather than reporting findings.
