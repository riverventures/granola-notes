---
name: granola-notes
description: Manage Granola meeting notes with a local-first archive that works across OpenClaw and Hermes agents. Auto-archive notes to local disk, search past meetings in natural language, quote decisions and action items, and optionally deliver short summaries through the active runtime.
---

# granola-notes

Use Granola as meeting memory, not as a live dependency for every question.

This skill is built around one idea: archive once, query forever.
That makes it work well for both OpenClaw and Hermes.

## Works with

- OpenClaw agents
- Hermes agents
- Any local agent runtime that can:
  - read markdown files
  - run shell commands
  - search a synced meeting archive

The archive and search flow is runtime-agnostic.
Channel posting is runtime-specific.

## Core workflow

1. Export Granola notes with the Granola CLI on the primary machine.
2. Save each meeting as markdown in a stable local archive path.
3. Sync that archive across machines if multiple agents need access.
4. Answer meeting questions from the local archive first.
5. Only use live Granola CLI lookups when the archive is stale or missing.
6. If the runtime supports outbound messaging, send short post-meeting summaries.

## Why this is robust

- local archive is faster than repeated live reads
- both OpenClaw and Hermes can read the same markdown files
- agent behavior stays consistent even if Granola auth breaks for a while
- synced archives let multiple agents share the same meeting memory

## Requirements

- Granola app installed and authenticated
- `granola` CLI available
- local archive path on disk
- optional Syncthing or another file sync layer for multi-machine use
- optional runtime messaging layer if you want summaries sent to Telegram, Discord, or elsewhere

## Recommended archive pattern

Set a stable archive directory, for example:

```bash
export MEETING_ARCHIVE="$HOME/meetings/granola"
mkdir -p "$MEETING_ARCHIVE"
```

Archive meetings into dated markdown files with predictable names.

## Search flow

For most requests:
1. search the local archive
2. open the most relevant markdown file
3. answer directly with the decision, quote, or action item
4. cite the meeting name or date when useful

### Good queries
- what did Maya say about Zand
- what were the action items from the Axiym call
- did Nick agree to the 5bps incentive
- summarize the last meeting with R3

## Archive script

Use the included script to export meetings from Granola into the local archive.

```bash
bash scripts/archive-granola.sh
```

Run it on the machine that has working Granola auth.
If Hermes runs on another box, sync the archive there rather than forcing Hermes to talk to Granola live every time.

## Fallback to live Granola CLI

Only fall back to Granola CLI when the archive is stale or missing.

Examples:

```bash
granola meeting list --search "keyword"
granola meeting list --date 2026-03-16
granola meeting list --attendee "john@example.com"
granola meeting view <meeting-id>
granola meeting enhanced <meeting-id>
granola meeting transcript <meeting-id> --timestamps
```

## Runtime guidance

### In OpenClaw
- prefer local archive search over repeated live API reads
- if posting a summary, keep it short: decision, action items, blockers
- use the message layer only for concise debriefs, not raw transcript dumps

### In Hermes
- point Hermes at the same local archive path
- read and search the markdown archive directly
- treat the archive as the source of truth unless it is stale
- keep Hermes prompts focused on extraction, synthesis, and follow-ups, not live Granola dependency

## Output

Default output:
- direct answer to the meeting question
- quote or meeting reference when useful
- concise extraction of decisions, next steps, and blockers
- optional short runtime-specific summary delivery if supported

## Rules

- **DO NOT write** into the synced archive on receive-only devices
- default to the local archive for all queries
- only fall back to Granola CLI if the archive is stale, missing, or clearly incomplete
- when posting summaries, never include the raw transcript, summaries and action items only
- never expose API keys, Syncthing device IDs, or chat IDs in logs or output
- if Granola auth is broken, say so clearly and stop before hallucinating notes

## Directory structure

```text
$MEETING_ARCHIVE/
├── 2026-03-31_Weekly-Pipeline-Review_abc123.md
├── 2026-03-30_Farhad-Axiym-Call_def456.md
├── 2026-03-28_Maya-Alex-Sync_ghi789.md
├── debriefs/
│   ├── 2026-03-31-Weekly-Pipeline-Review.md
│   └── 2026-03-30-Farhad-Axiym-Call.md
└── prep/
    └── 2026-04-01-KAST-Lunch-Prep.md
```
