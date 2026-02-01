#!/bin/bash
PID_FILE="/tmp/claude-caffeinate.pid"

if [[ -f "$PID_FILE" ]]; then
    # Extract caffeinate PID from new format (supports both old and new)
    caffeinate_pid=$(grep '^CAFFEINATE_PID=' "$PID_FILE" 2>/dev/null | cut -d'=' -f2)
    if [[ -z "$caffeinate_pid" ]]; then
        # Fallback: old format (just the PID)
        caffeinate_pid=$(cat "$PID_FILE")
    fi
    kill "$caffeinate_pid" 2>/dev/null
    rm "$PID_FILE"
fi
