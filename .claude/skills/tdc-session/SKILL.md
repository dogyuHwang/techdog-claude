---
name: tdc-session
description: "TechDog Claude - Session management for context preservation across sessions"
user-invocable: true
argument-hint: "[save|resume|list|clean]"
---

**입력:** $ARGUMENTS

# /tdc-session - Session Management

## Commands

### `/tdc-session save`
Save current session state for later resumption.

1. Gather current state:
   - Active tasks and their status
   - Files modified in this session
   - Key decisions made
   - Pending work items
2. Write to `.tdc/sessions/<timestamp>.json`:
   ```json
   {
     "session_id": "<ISO timestamp>",
     "project": "<cwd>",
     "task": "<original task>",
     "completed": [],
     "in_progress": [],
     "pending": [],
     "decisions": [],
     "files_modified": [],
     "context_summary": "<compressed context>"
   }
   ```
3. Confirm save to user

### `/tdc-session resume`
Resume from the latest saved session.

1. Read the latest `.tdc/sessions/*.json`
2. Display session summary to user
3. Load context and continue work

### `/tdc-session resume <session_id>`
Resume a specific session by ID.

### `/tdc-session list`
List all saved sessions with timestamps and task summaries.

1. Scan `.tdc/sessions/*.json`
2. Display table: ID | Date | Task | Status

### `/tdc-session clean`
Remove sessions older than 7 days.

## Auto-Save

The master agent should auto-save when:
- Context is getting long (many tool calls)
- Before suggesting a session restart
- When the user explicitly asks to stop

## Token Optimization

- Session files are JSON, not verbose markdown
- Context summaries should be under 100 lines
- Only save what's needed to resume — not full conversation history
