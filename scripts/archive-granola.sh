#!/bin/bash
# archive-granola.sh — Export new Granola meetings to local disk
# Run daily via cron or manually after meetings
#
# Usage: bash archive-granola.sh
# Environment: MEETING_ARCHIVE (default: ~/MeetingMemoryShared/SyncedMeetingNotes)

set -euo pipefail

ARCHIVE_DIR="${MEETING_ARCHIVE:-$HOME/MeetingMemoryShared/SyncedMeetingNotes}"
mkdir -p "$ARCHIVE_DIR"

echo "Archiving Granola meetings to: $ARCHIVE_DIR"

# Get meetings from the last 24 hours
MEETINGS=$(granola meeting list --since "$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d '1 day ago' +%Y-%m-%d)" --limit 50 2>/dev/null || echo "")

if [ -z "$MEETINGS" ]; then
    echo "No new meetings found (or Granola CLI unavailable)"
    exit 0
fi

ARCHIVED=0
SKIPPED=0

echo "$MEETINGS" | while read -r line; do
    MEETING_ID=$(echo "$line" | awk '{print $1}')
    [ -z "$MEETING_ID" ] && continue
    
    # Skip if already archived
    if ls "$ARCHIVE_DIR"/*"$MEETING_ID"* 2>/dev/null | grep -q .; then
        SKIPPED=$((SKIPPED + 1))
        continue
    fi
    
    # Get meeting metadata
    MEETING_DATA=$(granola meeting view "$MEETING_ID" 2>/dev/null || echo "")
    [ -z "$MEETING_DATA" ] && continue
    
    DATE=$(echo "$MEETING_DATA" | grep -i "date" | head -1 | awk '{print $2}')
    TITLE=$(echo "$MEETING_DATA" | grep -i "title" | head -1 | sed 's/.*: //' | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | head -c 50)
    
    [ -z "$DATE" ] && DATE=$(date +%Y-%m-%d)
    [ -z "$TITLE" ] && TITLE="untitled"
    
    FILENAME="${DATE}_${TITLE}_${MEETING_ID}.md"
    
    # Export enhanced notes + transcript
    {
        FULL_TITLE=$(echo "$MEETING_DATA" | grep -i "title" | head -1 | sed 's/.*: //')
        echo "# Meeting: ${FULL_TITLE:-Untitled}"
        echo "**Date:** $DATE"
        echo "**Meeting ID:** $MEETING_ID"
        echo ""
        
        ATTENDEES=$(echo "$MEETING_DATA" | grep -i "attendee\|participant" || echo "")
        if [ -n "$ATTENDEES" ]; then
            echo "**Attendees:**"
            echo "$ATTENDEES"
            echo ""
        fi
        
        echo "## Summary"
        granola meeting enhanced "$MEETING_ID" 2>/dev/null || echo "(No enhanced notes available)"
        echo ""
        
        echo "## Transcript"
        granola meeting transcript "$MEETING_ID" --timestamps 2>/dev/null || echo "(No transcript available)"
    } > "$ARCHIVE_DIR/$FILENAME"
    
    ARCHIVED=$((ARCHIVED + 1))
    echo "✅ Archived: $FILENAME"
done

echo "Done. Archived: $ARCHIVED new, Skipped: $SKIPPED existing"
