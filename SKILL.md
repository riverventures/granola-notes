---
name: granola-notes
description: Manage Granola meeting notes — auto-archive to local disk, sync across agents via Syncthing, post summaries to Telegram or Discord, and search past meetings with natural language. Use when the user asks about meetings, meeting notes, transcripts, what was discussed in a call, action items from meetings, meeting search, or anything related to Granola.
---

# granola-notes

Meeting memory for AI agents. Archive, sync, search, and share your Granola meeting notes.

## Requirements

- [Granola](https://granola.so) app installed and authenticated
- `granola` CLI (installed with the app)
- Optional: [Syncthing](https://syncthing.net/) for multi-device/multi-agent sync
- Optional: OpenClaw with Telegram or Discord channel configured (for summary delivery)

## Setup

### 1. Configure Archive Path

Set your local archive directory. This is where meeting notes are stored on disk.

```bash
# Default path (customize to your preference)
MEETING_ARCHIVE="$HOME/MeetingMemoryShared/SyncedMeetingNotes"
mkdir -p "$MEETING_ARCHIVE"
mkdir -p "$MEETING_ARCHIVE/debriefs"
mkdir -p "$MEETING_ARCHIVE/prep"
```

### 2. Configure Syncthing (Optional — for multi-agent sync)

If you run multiple OpenClaw instances (e.g., laptop + VPS + Pi), Syncthing keeps the archive in sync across all of them.

```bash
# Install Syncthing
brew install syncthing  # macOS
# or: apt install syncthing  # Linux

# Start Syncthing
syncthing  # Opens web UI at http://localhost:8384

# Add your archive folder as a shared folder
# Set remote devices as "receive-only" if they shouldn't write back
```

**Key setup decisions:**
- Primary device (where Granola runs): **Send Only**
- Agent devices (VPS, Pi, other machines): **Receive Only**
- This ensures agents can read meeting data but can't corrupt the archive

### 3. Configure Summary Delivery (Optional)

Tell the skill where to post meeting summaries. Set in your OpenClaw workspace config or TOOLS.md:

```markdown
## Meeting Summaries
- Delivery: telegram  (or: discord)
- Telegram chat ID: <your-chat-id>
- Discord channel: #meeting-notes (or channel ID)
```

## Features

### 1. Auto-Archive to Local Disk

The skill archives Granola meeting notes as markdown files on your local disk. Each note includes the title, date, attendees, AI-enhanced summary, and full transcript.

**Archive format:**
```
YYYY-MM-DD_Meeting-Title-Slug_hashid.md
```

**Archive script** (run via cron or manually):

```bash
#!/bin/bash
# archive-granola.sh — Export new Granola meetings to local disk
ARCHIVE_DIR="${MEETING_ARCHIVE:-$HOME/MeetingMemoryShared/SyncedMeetingNotes}"

# Get meetings from the last 24 hours
MEETINGS=$(granola meeting list --since "$(date -v-1d +%Y-%m-%d)" --limit 50 2>/dev/null)

echo "$MEETINGS" | while read -r line; do
    MEETING_ID=$(echo "$line" | awk '{print $1}')
    [ -z "$MEETING_ID" ] && continue
    
    # Skip if already archived
    if ls "$ARCHIVE_DIR"/*"$MEETING_ID"* 2>/dev/null | grep -q .; then
        continue
    fi
    
    # Get meeting date and title for filename
    DATE=$(granola meeting view "$MEETING_ID" 2>/dev/null | grep -i "date" | head -1 | awk '{print $2}')
    TITLE=$(granola meeting view "$MEETING_ID" 2>/dev/null | grep -i "title" | head -1 | sed 's/.*: //' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | head -c 50)
    
    FILENAME="${DATE}_${TITLE}_${MEETING_ID}.md"
    
    # Export enhanced notes
    {
        echo "# Meeting: $(granola meeting view "$MEETING_ID" | grep -i "title" | head -1 | sed 's/.*: //')"
        echo "**Date:** $DATE"
        echo ""
        echo "## Summary"
        granola meeting enhanced "$MEETING_ID" 2>/dev/null
        echo ""
        echo "## Transcript"
        granola meeting transcript "$MEETING_ID" --timestamps 2>/dev/null
    } > "$ARCHIVE_DIR/$FILENAME"
    
    echo "Archived: $FILENAME"
done
```

**Cron setup** (run daily):
```bash
# Add to OpenClaw cron or system crontab
openclaw cron add --name "Granola Archive" --schedule "30 23 * * *" --task "Run archive-granola.sh to export today's meetings to local disk"
```

### 2. Multi-Agent Sync via Syncthing

Once archived locally, Syncthing distributes the notes to all connected agents automatically.

**How it works:**
- Primary device archives meetings to `$MEETING_ARCHIVE`
- Syncthing syncs the folder to all connected devices
- Remote agents read from their local copy (fast, no API calls needed)
- Remote agents are receive-only (can't write back or corrupt)

**Verify sync status:**
```bash
# Check Syncthing is running
curl -s http://localhost:8384/rest/system/status | python3 -c "import sys,json; print(json.load(sys.stdin)['myID'][:12])"

# Check folder sync status
API_KEY=$(grep apikey ~/Library/Application\ Support/Syncthing/config.xml | sed 's/.*>\(.*\)<.*/\1/' | head -1)
curl -s -H "X-API-Key: $API_KEY" "http://localhost:8384/rest/db/status?folder=synced-meeting-notes" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'State: {d[\"state\"]}, Need: {d[\"needFiles\"]} files')"
```

**Freshness check:**
```bash
# Most recent archived file
ls -lt "$MEETING_ARCHIVE" | head -3
```

If the archive is more than 24h stale or Syncthing shows errors, the skill falls back to the Granola CLI.

### 3. Summary Delivery to Telegram/Discord

After each meeting is archived, the skill can post a summary to your preferred channel.

**Telegram delivery:**
```bash
# Via OpenClaw message tool
message action=send channel=telegram target=<chat-id> message="📝 Meeting: <title>\n\n<summary>\n\nAction items:\n<items>"
```

**Discord delivery:**
```bash
# Via OpenClaw message tool
message action=send channel=discord target=<channel-id> message="📝 Meeting: <title>\n\n<summary>"
```

**Summary format:**
```
📝 Meeting: [Title]
📅 [Date] | 👥 [Attendees]

[AI-enhanced summary — 3-5 bullet points]

Action Items:
• [Person]: [Action] — [Deadline if mentioned]
• [Person]: [Action]
```

### 4. Natural Language Search

Search past meetings using natural language queries. The skill searches the local archive first, falls back to Granola CLI if needed.

**Search the synced archive:**
```bash
# Search by keyword across all notes
grep -ril "keyword" "$MEETING_ARCHIVE/"

# Search with context (shows surrounding lines)
grep -ril "keyword" "$MEETING_ARCHIVE/" | head -5 | while read f; do
    echo "=== $(basename "$f") ==="
    grep -C 3 "keyword" "$f" | head -20
    echo
done

# Find by date range
ls "$MEETING_ARCHIVE/" | grep "2026-03"

# Find by person or company name
grep -ril "john\|acme" "$MEETING_ARCHIVE/" | head -10

# Most recent meetings
ls -lt "$MEETING_ARCHIVE/" | head -10

# Search in debriefs only
grep -ril "keyword" "$MEETING_ARCHIVE/debriefs/"
```

**When the user asks about a meeting:**

1. Parse the query for: person name, company, date, topic
2. Search the archive using grep patterns
3. Read matching files
4. Synthesize an answer from the content
5. Cite which meeting(s) the information came from

**Example queries the skill handles:**
- "What did we discuss with Zand last month?"
- "Who was in the call on March 16?"
- "What action items came out of the Maya meeting?"
- "Find all meetings about stablecoins"
- "What did Farhad say about the Korean consortium?"

**Fallback to Granola CLI:**
```bash
# Only if archive is stale or missing
granola meeting list --search "keyword"
granola meeting list --date 2026-03-16
granola meeting list --attendee "john@example.com"
granola meeting view <meeting-id>
granola meeting enhanced <meeting-id>
granola meeting transcript <meeting-id> --timestamps
```

## Rules

- **DO NOT write** into the synced archive on receive-only devices
- Default to the local archive for all queries (faster, no API dependency)
- Only fall back to Granola CLI if the archive is stale (>24h behind) or inaccessible
- When posting summaries, never include raw transcript — summaries and action items only
- Never expose API keys, Syncthing device IDs, or chat IDs in logs or output

## Directory Structure

```
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
