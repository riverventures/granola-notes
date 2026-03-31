# 📝 granola-notes

Meeting memory for AI agents. An [OpenClaw](https://github.com/openclaw/openclaw) skill.

## What it does

Connects your [Granola](https://granola.so) meeting notes to your AI agent. Auto-archives to local disk, syncs across multiple agents via Syncthing, posts summaries to Telegram or Discord, and lets you search past meetings in natural language.

```
"What did Farhad say about the Korean bank consortium?"
```

→ Searches 700+ archived meeting notes, finds the relevant calls, pulls the exact quotes.

## Install

```bash
openclaw skill add riverventures/granola-notes
```

## Features

| Feature | What it does |
|---|---|
| **Auto-archive** | Exports Granola meetings as markdown files to local disk daily |
| **Multi-agent sync** | Syncthing distributes the archive to all your AI agents (laptop, VPS, Pi) |
| **Summary delivery** | Posts meeting summaries + action items to Telegram or Discord after each call |
| **Natural language search** | Ask about any past meeting — who said what, action items, decisions made |

## How it works

```
Granola App → Archive Script → Local Disk → Syncthing → All Your Agents
                                    ↓
                          Telegram / Discord (summaries)
```

1. **Granola** records your meetings with AI-enhanced notes
2. **Archive script** exports new meetings daily as markdown files
3. **Syncthing** syncs the archive to every connected device
4. **Your agent** searches the local archive to answer questions about past meetings
5. **Summaries** get posted to your preferred channel after each meeting

## Why local-first?

- **Fast.** Grep is instant. No API calls, no rate limits.
- **Private.** Meeting transcripts never leave your devices.
- **Resilient.** Works offline. No dependency on Granola's servers for past meetings.
- **Shareable.** Syncthing lets multiple AI agents access the same meeting history without giving each one API credentials.

## Requirements

- [Granola](https://granola.so) app installed and authenticated
- `granola` CLI
- Optional: [Syncthing](https://syncthing.net/) for multi-device sync
- Optional: OpenClaw with Telegram/Discord configured

## Quick Start

```bash
# 1. Set your archive path
export MEETING_ARCHIVE="$HOME/MeetingMemoryShared/SyncedMeetingNotes"
mkdir -p "$MEETING_ARCHIVE/debriefs" "$MEETING_ARCHIVE/prep"

# 2. Run the archive script (or set up a daily cron)
bash scripts/archive-granola.sh

# 3. Start asking questions
# "What action items came out of yesterday's call?"
# "Find all meetings about stablecoins this month"
```

## Example Queries

- "What did we discuss with Zand last month?"
- "Who was in the call on March 16?"
- "What action items came out of the Maya meeting?"
- "Find all meetings about stablecoins"
- "Summarize the last 3 meetings with Farhad"

## Archive Format

```
$MEETING_ARCHIVE/
├── 2026-03-31_Weekly-Pipeline-Review_abc123.md
├── 2026-03-30_Farhad-Axiym-Call_def456.md
├── debriefs/
│   └── 2026-03-31-Weekly-Pipeline-Review.md
└── prep/
    └── 2026-04-01-Client-Lunch-Prep.md
```

Each file contains: title, date, attendees, AI-enhanced summary, and full timestamped transcript.

## Multi-Agent Setup

Run Granola on your primary machine (laptop). Set it as **Send Only** in Syncthing. Set all agent devices (VPS, Pi, other machines) as **Receive Only**. Agents read from their local copy — fast, no API credentials needed, no risk of corruption.

## License

MIT
