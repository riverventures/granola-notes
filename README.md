# granola-notes

Meeting memory for AI agents.

`granola-notes` is a local-first skill for turning Granola meeting notes into a searchable archive that works across both **OpenClaw** and **Hermes**.

Instead of re-querying Granola for every meeting question, the skill exports notes to markdown, stores them locally, and lets your agent search the archive fast.

## Why use it

- one archive, multiple agents
- works with OpenClaw and Hermes
- faster than repeated live Granola reads
- more reliable when Granola auth flakes out
- clean setup for post-meeting debriefs, prep notes, and action-item lookup

## Best use cases

- “What did we decide on the partner call?”
- “Pull action items from the investor meeting.”
- “Summarize the last leadership sync.”
- “Search all meetings for the new product line.”
- “Archive today’s Granola notes to disk.”

## Compatibility

### OpenClaw
Use it as a normal OpenClaw skill.
OpenClaw can search the archive, quote meetings, and optionally send short summaries through Telegram, Discord, or another channel.

### Hermes
Use the same archive path and let Hermes read the markdown directly.
Hermes does not need Granola live on every query if the archive is synced and current.

## Core model

Archive once. Query forever.

The Granola CLI is for collecting notes.
The local markdown archive is for daily agent use.

## Files

- `SKILL.md` — main runtime instructions
- `scripts/archive-granola.sh` — export notes from Granola into the archive

## Setup

1. Install and authenticate Granola on the primary machine.
2. Choose an archive directory.
3. Run the archive script.
4. Sync the archive to any other machine that needs meeting access.
5. Point OpenClaw or Hermes at the same markdown archive.

## Example archive path

```bash
export MEETING_ARCHIVE="$HOME/meetings/granola"
mkdir -p "$MEETING_ARCHIVE"
```

## Archive meetings

```bash
bash scripts/archive-granola.sh
```

## Recommended pattern

- primary machine: Granola app + CLI + archive script
- secondary machines or agents: read-only synced archive
- queries: archive first, live CLI second

## Search behavior

The agent should:
1. search the archive
2. open the best matching note
3. extract decisions, quotes, and next steps
4. only fall back to live Granola if the archive is stale or missing

## Security

Meeting notes are sensitive.
Treat the archive as private workspace data.
Do not dump raw transcripts into public channels.
Do not expose runtime secrets, device IDs, tokens, or account details.

## Good output style

For most meeting questions, return:
- the answer
- the meeting/date reference
- next actions or blockers if relevant

If posting a summary externally, keep it tight.
No transcript spam.

## Who this is for

- founders
- chiefs of staff
- business development teams
- operators who live inside meeting-heavy pipelines
- teams running multiple local AI agents with shared memory

## License

MIT
