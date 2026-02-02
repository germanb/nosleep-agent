#!/bin/bash

# Function to find Claude process PID by walking up parent chain
find_claude_pid() {
    local pid=$PPID
    while [[ $pid -gt 1 ]]; do
        local cmd=$(ps -p $pid -o comm= 2>/dev/null)
        if [[ "$cmd" =~ (claude|node|electron) ]]; then
            echo $pid
            return
        fi
        pid=$(ps -p $pid -o ppid= 2>/dev/null | tr -d ' ')
    done
    echo ""
}

# Get Claude PID to find the right PID file
CLAUDE_PID=$(find_claude_pid)
if [[ -z "$CLAUDE_PID" ]]; then
    CLAUDE_PID=$PPID
fi

PID_FILE="/tmp/claude-caffeinate-${CLAUDE_PID}.pid"

if [[ -f "$PID_FILE" ]]; then
    caffeinate_pid=$(grep '^CAFFEINATE_PID=' "$PID_FILE" 2>/dev/null | cut -d'=' -f2)
    if [[ -n "$caffeinate_pid" ]] && kill -0 "$caffeinate_pid" 2>/dev/null; then
        kill "$caffeinate_pid" 2>/dev/null
    fi
    rm "$PID_FILE"
fi

# Cleanup orphaned caffeinate processes from dead Claude sessions
for pid_file in /tmp/claude-caffeinate-*.pid; do
    [[ -f "$pid_file" ]] || continue

    # Extract Claude PID from filename
    claude_pid=$(basename "$pid_file" | sed 's/claude-caffeinate-\([0-9]*\)\.pid/\1/')

    # Check if Claude process still exists
    if ! kill -0 "$claude_pid" 2>/dev/null; then
        # Claude is dead, kill its caffeinate
        caffeinate_pid=$(grep '^CAFFEINATE_PID=' "$pid_file" 2>/dev/null | cut -d'=' -f2)
        if [[ -n "$caffeinate_pid" ]]; then
            kill "$caffeinate_pid" 2>/dev/null
        fi
        rm "$pid_file"
    fi
done
