---
name: Notion Note
description: Use when the user asks to save, capture, or file a note in their Notion Second Brain.
---

# Notion Note

Create one note in the user's Notion Second Brain, in the `Notes` database,
linked to exactly one existing Area and exactly one existing Topic. Write in
English and separate topics with `##` headings.

This skill requires the Notion MCP server. If it is unavailable, say so instead
of inventing a result.

## Second Brain model

The workspace follows the PARA model documented in `How to use Second Brain`:

- `Areas` organize ongoing responsibilities.
- `Projects`, `Goals`, `Tasks` and `Events` are productivity objects.
- `Notes`, `References`, `Highlights` and `Notebooks` are knowledge objects.
- `Topics` connect Areas to knowledge objects.
- Notes belong to the `Notes` database and can relate to an Area, Topics,
  Projects, Tasks, other Notes, References and Highlights.

Read the guide when you need the current rules:
https://app.notion.com/p/1893bb9526db80098b98dae41ad12c0f

## Before writing

1. Search for an existing note with the same subject. If it already exists,
   update it instead of creating a duplicate.
2. Find the target Area with `notion-search` or by querying the Areas data
   source. Every note needs exactly one existing Area; never create one unless
   the user explicitly asks.
3. Find the target Topic with `notion-search` or by querying the Topics data
   source. Every note needs exactly one existing Topic. Never create a Topic;
   if no existing Topic fits, ask the user which one to use.
4. Choose the note type.
5. Read `notion://docs/notion-flavored-markdown-spec` before writing if you are
   not sure about the supported Markdown syntax.

## Choose the note type

| Type | Use when |
| --- | --- |
| `Fleeting` | Quick capture, raw thought or something to process later. |
| `Literature` | Notes from an external source: book, article, video, course. |
| `Project` | Work tied to an active project or a specific initiative. |
| `Permanent` | Durable reference or reusable knowledge worth keeping. |

If the user does not specify the type and the content makes it clear, choose it
and state the choice in the final report. If it is genuinely ambiguous, ask one
short question.

## Note structure

- Set the title in the `Name` property. Do not repeat it as an H1 in the content.
- Separate topics with `##` (H2) headings.
- Use short paragraphs and bullet lists. Use tables only when they make
  structured data clearer.
- Keep the note self-contained: context, the point, and the next step.
- Write in English unless the user explicitly asks for another language.
- Never include credentials, tokens, private keys or sensitive personal data.

Adapt this skeleton; do not force every section:

```markdown
## Context

Why this note exists.

## Key points

- ...
- ...

## Details

...

## Next steps

- ...
```

## Destination and properties

Create the page in the `Notes` data source:

`collection://1273bb95-26db-814c-961d-000b7a173d25`

Use `notion-create-pages` with:

- `parent`: `{ "type": "data_source_id", "data_source_id": "1273bb95-26db-814c-961d-000b7a173d25" }`
- `pages[0].properties.Name`: the note title
- `pages[0].properties.Type`: one of `Fleeting`, `Literature`, `Project`, `Permanent`
- `pages[0].properties.Area`: an array with the URL of the selected Area
- `pages[0].properties.Topics`: an array with the URL of the selected Topic
- `allow_async`: `false`, so the page and its URL are returned immediately

Optionally set `Projects` or `Related Notes` only when the user names an
existing object; otherwise leave them blank.

The existing Topics data source is:

`collection://1273bb95-26db-813a-9632-000b6dfd71de`

Pick the Topic that best matches the note and use its page URL in the `Topics`
relation. If no existing Topic fits, ask the user instead of creating one.

If the data source ID changes, search for the `Notes` database under
`Second Brain / Databases` and use its `collection://` URL.

## Areas

The existing Areas data source is:

`collection://1273bb95-26db-813f-b610-000be8d0c4de`

Pick the Area that best matches the note. Use the page URL in the `Area`
relation. If no existing Area fits, ask the user instead of creating one.

## Updating an existing note

When the user asks to add to or change an existing note:

1. Find it with `notion-search`.
2. Fetch it with `notion-fetch` and preserve its content.
3. Use `notion-update-page`; do not create a duplicate.

## After creating

1. Fetch the created page with `notion-fetch`.
2. Verify the title, type, Area, Topic and content.
3. Report the page URL and where it was filed.
4. Mention any optional relation left blank and offer to link it.

## Rules

- Use the existing `Notes` database, exactly one existing Area and exactly one
  existing Topic.
- Never create Areas or Topics unless the user explicitly asks. When no
  existing Area or Topic fits, ask the user.
- Never create Projects, Goals or new select options unless the user explicitly
  asks.
- Do not create a duplicate note for a subject that already exists.
- Do not claim the note was saved without checking the created page.
- Keep the note in English and its topics separated by H2 headings.
