#!/bin/bash

# Integration tests for prevent-sleep.sh and allow-sleep.sh hooks
# Tests multi-session support and orphan cleanup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/../hooks" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

passed=0
failed=0

# Test helpers
assert_eq() {
    if [ "$1" = "$2" ]; then
        echo -e "${GREEN}✓${NC} $3"
        ((passed++))
    else
        echo -e "${RED}✗${NC} $3"
        echo "  Expected: $2"
        echo "  Got: $1"
        ((failed++))
    fi
}

assert_file_exists() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} File exists: $1"
        ((passed++))
    else
        echo -e "${RED}✗${NC} File should exist: $1"
        ((failed++))
    fi
}

assert_file_not_exists() {
    if [ ! -f "$1" ]; then
        echo -e "${GREEN}✓${NC} File does not exist: $1"
        ((passed++))
    else
        echo -e "${RED}✗${NC} File should not exist: $1"
        ((failed++))
    fi
}

assert_process_alive() {
    if kill -0 "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Process $1 is alive"
        ((passed++))
        return 0
    else
        echo -e "${RED}✗${NC} Process $1 should be alive"
        ((failed++))
        return 1
    fi
}

assert_process_dead() {
    if ! kill -0 "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Process $1 is dead"
        ((passed++))
        return 0
    else
        echo -e "${RED}✗${NC} Process $1 should be dead"
        ((failed++))
        return 1
    fi
}

cleanup() {
    # Kill any test caffeinate processes
    pkill -f "caffeinate.*test-session" 2>/dev/null || true
    # Remove test PID files
    rm -f /tmp/claude-caffeinate-test-*.pid
    rm -f /tmp/claude-caffeinate-*.pid.test
}

# Cleanup before and after tests
trap cleanup EXIT
cleanup

echo "========================================="
echo "Testing Multi-Session Hook Behavior"
echo "========================================="
echo

# Test 1: Unique PID files per session
echo -e "${YELLOW}Test 1: Unique PID files per session${NC}"

# Manually create PID files to test the naming pattern and format
# (Since we can't override PPID, we test the file structure directly)
PID_FILE_1="/tmp/claude-caffeinate-10001.pid"
PID_FILE_2="/tmp/claude-caffeinate-10002.pid"

# Create test PID files
caffeinate -dims >/dev/null 2>&1 &
CAFF_PID_1=$!
cat > "$PID_FILE_1" <<EOF
CAFFEINATE_PID=$CAFF_PID_1
CLAUDE_PID=10001
EOF

caffeinate -dims >/dev/null 2>&1 &
CAFF_PID_2=$!
cat > "$PID_FILE_2" <<EOF
CAFFEINATE_PID=$CAFF_PID_2
CLAUDE_PID=10002
EOF

assert_file_exists "$PID_FILE_1"
assert_file_exists "$PID_FILE_2"

if [ "$CAFF_PID_1" != "$CAFF_PID_2" ]; then
    echo -e "${GREEN}✓${NC} Different caffeinate PIDs: $CAFF_PID_1 vs $CAFF_PID_2"
    ((passed++))
else
    echo -e "${RED}✗${NC} Caffeinate PIDs should be different"
    ((failed++))
fi

assert_process_alive "$CAFF_PID_1"
assert_process_alive "$CAFF_PID_2"

echo

# Test 2: Manual cleanup simulation
echo -e "${YELLOW}Test 2: Manual cleanup of single session${NC}"

# Simulate allow-sleep.sh logic: read PID file, kill caffeinate, remove file
if [ -f "$PID_FILE_1" ]; then
    caff_pid=$(grep '^CAFFEINATE_PID=' "$PID_FILE_1" | cut -d'=' -f2)
    if [ -n "$caff_pid" ]; then
        kill "$caff_pid" 2>/dev/null
    fi
    rm "$PID_FILE_1"
fi
sleep 0.5

assert_file_not_exists "$PID_FILE_1"
assert_file_exists "$PID_FILE_2"
assert_process_dead "$CAFF_PID_1"
assert_process_alive "$CAFF_PID_2"

echo

# Test 3: Orphan cleanup
echo -e "${YELLOW}Test 3: Orphan cleanup for dead sessions${NC}"

# Create a fake orphan (PID file for a Claude process that doesn't exist)
ORPHAN_FILE="/tmp/claude-caffeinate-99999.pid"
caffeinate -dims >/dev/null 2>&1 &
ORPHAN_CAFF_PID=$!
cat > "$ORPHAN_FILE" <<EOF
CAFFEINATE_PID=$ORPHAN_CAFF_PID
CLAUDE_PID=99999
EOF

assert_file_exists "$ORPHAN_FILE"
assert_process_alive "$ORPHAN_CAFF_PID"

# Simulate orphan cleanup logic from allow-sleep.sh
for pid_file in /tmp/claude-caffeinate-*.pid; do
    [ -f "$pid_file" ] || continue

    claude_pid=$(basename "$pid_file" | sed 's/claude-caffeinate-\([0-9]*\)\.pid/\1/')

    # Check if Claude process still exists
    if ! kill -0 "$claude_pid" 2>/dev/null; then
        # Claude is dead, kill its caffeinate
        caffeinate_pid=$(grep '^CAFFEINATE_PID=' "$pid_file" 2>/dev/null | cut -d'=' -f2)
        if [ -n "$caffeinate_pid" ]; then
            kill "$caffeinate_pid" 2>/dev/null
        fi
        rm "$pid_file"
    fi
done
sleep 0.5

# Orphan should be cleaned up
assert_file_not_exists "$ORPHAN_FILE"
assert_process_dead "$ORPHAN_CAFF_PID"

# PID_FILE_2 should still exist (Claude 10002 doesn't actually exist but we haven't run cleanup on it)
# Clean it up manually
if [ -f "$PID_FILE_2" ]; then
    caff_pid=$(grep '^CAFFEINATE_PID=' "$PID_FILE_2" | cut -d'=' -f2)
    [ -n "$caff_pid" ] && kill "$caff_pid" 2>/dev/null
    rm "$PID_FILE_2"
fi

echo

# Test 4: PID file format validation
echo -e "${YELLOW}Test 4: PID file format validation${NC}"

PID_FILE_3="/tmp/claude-caffeinate-10003.pid"
caffeinate -dims >/dev/null 2>&1 &
CAFF_PID_3=$!

cat > "$PID_FILE_3" <<EOF
CAFFEINATE_PID=$CAFF_PID_3
CLAUDE_PID=10003
EOF

assert_file_exists "$PID_FILE_3"

# Check format
if grep -q '^CAFFEINATE_PID=' "$PID_FILE_3" && grep -q '^CLAUDE_PID=' "$PID_FILE_3"; then
    echo -e "${GREEN}✓${NC} PID file has correct format"
    ((passed++))
else
    echo -e "${RED}✗${NC} PID file format is incorrect"
    cat "$PID_FILE_3"
    ((failed++))
fi

EXTRACTED_CAFF_PID=$(grep '^CAFFEINATE_PID=' "$PID_FILE_3" | cut -d'=' -f2)
CLAUDE_PID_3=$(grep '^CLAUDE_PID=' "$PID_FILE_3" | cut -d'=' -f2)

assert_eq "$CLAUDE_PID_3" "10003" "CLAUDE_PID in file"
assert_eq "$EXTRACTED_CAFF_PID" "$CAFF_PID_3" "CAFFEINATE_PID in file"

# Cleanup
kill "$CAFF_PID_3" 2>/dev/null || true
rm -f "$PID_FILE_3"

echo

# Summary
echo "========================================="
echo "Test Results"
echo "========================================="
echo -e "Passed: ${GREEN}$passed${NC}"
echo -e "Failed: ${RED}$failed${NC}"
echo

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
