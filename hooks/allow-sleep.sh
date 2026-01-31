#!/bin/bash
PID_FILE="/tmp/claude-caffeinate.pid"

if [[ -f "$PID_FILE" ]]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm "$PID_FILE"
fi
