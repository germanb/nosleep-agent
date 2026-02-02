#!/bin/bash

# Fork to background immediately if not already forked
if [[ "$1" != "--forked" ]]; then
    "$0" --forked >/dev/null 2>&1 &
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

# Get Claude PID first to create unique PID file
CLAUDE_PID=$(find_claude_pid)
if [[ -z "$CLAUDE_PID" ]]; then
    # Fallback: use PPID if we can't find Claude in parent chain
    CLAUDE_PID=$PPID
fi

PID_FILE="/tmp/claude-caffeinate-${CLAUDE_PID}.pid"

# Check if already running
if [[ -f "$PID_FILE" ]]; then
    caffeinate_pid=$(grep '^CAFFEINATE_PID=' "$PID_FILE" 2>/dev/null | cut -d'=' -f2)
    [[ -z "$caffeinate_pid" ]] && caffeinate_pid=$(cat "$PID_FILE")
    kill -0 "$caffeinate_pid" 2>/dev/null && exit 0
fi

# Start caffeinate
caffeinate -dims >/dev/null 2>&1 &
caffeinate_pid=$!

# Store PIDs
cat > "$PID_FILE" <<EOF
CAFFEINATE_PID=$caffeinate_pid
CLAUDE_PID=$CLAUDE_PID
EOF
