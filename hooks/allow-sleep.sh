#!/bin/bash

# Session PID (caller) to find the right PID file
SESSION_PID="$1"
if [[ -z "$SESSION_PID" ]]; then
    SESSION_PID=$PPID
fi

PID_FILE="/tmp/claude-caffeinate-session-${SESSION_PID}.pid"

if [[ -f "$PID_FILE" ]]; then
    caffeinate_pid=$(grep '^CAFFEINATE_PID=' "$PID_FILE" 2>/dev/null | cut -d'=' -f2)
    if [[ -n "$caffeinate_pid" ]] && kill -0 "$caffeinate_pid" 2>/dev/null; then
        kill "$caffeinate_pid" 2>/dev/null
    fi
    rm "$PID_FILE"
fi

# Cleanup orphaned caffeinate processes from dead Claude sessions
for pid_file in /tmp/claude-caffeinate-session-*.pid; do
    [[ -f "$pid_file" ]] || continue

    # Extract session PID from file contents (fallback to filename)
    session_pid=$(grep '^SESSION_PID=' "$pid_file" 2>/dev/null | cut -d'=' -f2)
    if [[ -z "$session_pid" ]]; then
        session_pid=$(basename "$pid_file" | sed 's/claude-caffeinate-session-\([0-9]*\)\.pid/\1/')
    fi

    # Check if session process still exists
    if [[ -z "$session_pid" ]] || ! kill -0 "$session_pid" 2>/dev/null; then
        # Session is dead, kill its caffeinate
        caffeinate_pid=$(grep '^CAFFEINATE_PID=' "$pid_file" 2>/dev/null | cut -d'=' -f2)
        if [[ -n "$caffeinate_pid" ]]; then
            kill "$caffeinate_pid" 2>/dev/null
        fi
        rm "$pid_file"
    fi
done
