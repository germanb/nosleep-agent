#!/bin/bash

# Fork to background immediately if not already forked
if [[ "$1" != "--forked" ]]; then
    "$0" --forked >/dev/null 2>&1 &
    exit 0
fi

# Now running in background
PID_FILE="/tmp/claude-caffeinate.pid"

# Check if already running
[[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null && exit 0

# Start caffeinate
caffeinate -dims >/dev/null 2>&1 &
echo $! > "$PID_FILE"
