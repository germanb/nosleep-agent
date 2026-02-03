#!/bin/bash
# Test that caffeinate processes don't leak when hooks are used normally

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd)"

echo -e "${YELLOW}Testing for caffeinate leaks${NC}"
echo "============================================"

# Count caffeinate processes before
BEFORE_COUNT=$(ps aux | grep "caffeinate -dims" | grep -v grep | wc -l | tr -d ' ')
echo "Caffeinate processes before: $BEFORE_COUNT"

# Simulate a session: start -> wait -> stop
echo ""
echo "Simulating Claude Code session lifecycle..."

# Start (this will fork to background)
echo "  1. Starting prevent-sleep.sh..."
bash "$HOOKS_DIR/prevent-sleep.sh"
sleep 1

# Check caffeinate started
DURING_COUNT=$(ps aux | grep "caffeinate -dims" | grep -v grep | wc -l | tr -d ' ')
EXPECTED_DURING=$((BEFORE_COUNT + 1))

if [ "$DURING_COUNT" -eq "$EXPECTED_DURING" ]; then
    echo -e "  ${GREEN}✓${NC} Caffeinate started (count: $DURING_COUNT)"
else
    echo -e "  ${RED}✗${NC} Expected $EXPECTED_DURING caffeinate, got $DURING_COUNT"
    exit 1
fi

# Simulate work
echo "  2. Simulating work for 2 seconds..."
sleep 2

# Stop
echo "  3. Running allow-sleep.sh..."
bash "$HOOKS_DIR/allow-sleep.sh"
sleep 1

# Check caffeinate stopped
AFTER_COUNT=$(ps aux | grep "caffeinate -dims" | grep -v grep | wc -l | tr -d ' ')

echo ""
echo "Results:"
echo "  Before:  $BEFORE_COUNT"
echo "  During:  $DURING_COUNT"
echo "  After:   $AFTER_COUNT"
echo ""

if [ "$AFTER_COUNT" -eq "$BEFORE_COUNT" ]; then
    echo -e "${GREEN}✓ No caffeinate leak detected!${NC}"
    echo "All caffeinate processes were properly cleaned up."
    exit 0
else
    echo -e "${RED}✗ Caffeinate leak detected!${NC}"
    echo "Expected $BEFORE_COUNT, but found $AFTER_COUNT"
    echo ""
    echo "Active caffeinate processes:"
    ps aux | grep "caffeinate -dims" | grep -v grep
    exit 1
fi
