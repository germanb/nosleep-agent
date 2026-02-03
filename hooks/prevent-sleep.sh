#!/bin/bash

# Fork to background immediately if not already forked
if [[ "$1" != "--forked" ]]; then
    SESSION_PID=$PPID
    "$0" --forked "$SESSION_PID" >/dev/null 2>&1 &
    exit 0
fi

# Now running in background
# Function to find Claude process PID by walking up parent chain
find_claude_pid() {
    local pid=$PPID
    while [[ $pid -gt 1 ]]; do
        local cmd=$(ps -p $pid -o comm= 2>/dev/null)
        # Match various ways Claude might appear (claude, node, electron)
        if [[ "$cmd" =~ (claude|node|electron) ]]; then
            echo $pid
            return
        fi
        pid=$(ps -p $pid -o ppid= 2>/dev/null | tr -d ' ')
    done
    echo ""
}

# Session PID passed from the non-forked invocation
SESSION_PID="$2"
if [[ -z "$SESSION_PID" ]]; then
    SESSION_PID=$PPID
fi

# Get Claude PID for metadata
CLAUDE_PID=$(find_claude_pid)
if [[ -z "$CLAUDE_PID" ]]; then
    # Fallback: use PPID if we can't find Claude in parent chain
    CLAUDE_PID=$PPID
fi

PID_FILE="/tmp/claude-caffeinate-session-${SESSION_PID}.pid"

# Check if already running
if [[ -f "$PID_FILE" ]]; then
    caffeinate_pid=$(grep '^CAFFEINATE_PID=' "$PID_FILE" 2>/dev/null | cut -d'=' -f2)
    [[ -z "$caffeinate_pid" ]] && caffeinate_pid=$(cat "$PID_FILE")
    if [[ -n "$caffeinate_pid" ]] && kill -0 "$caffeinate_pid" 2>/dev/null; then
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# Start caffeinate
caffeinate -dims >/dev/null 2>&1 &
caffeinate_pid=$!

# Store PIDs
START_EPOCH=$(date +%s)
TMP_FILE="/tmp/claude-caffeinate-session-${SESSION_PID}.pid.tmp"
cat > "$TMP_FILE" <<EOF
CAFFEINATE_PID=$caffeinate_pid
CLAUDE_PID=$CLAUDE_PID
SESSION_PID=$SESSION_PID
START_EPOCH=$START_EPOCH
EOF
mv "$TMP_FILE" "$PID_FILE"
