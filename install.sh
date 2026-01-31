#!/bin/bash
set -e

echo "Installing NoSleepAgent hooks..."

# Create hooks directory
mkdir -p ~/.claude/hooks

# Copy hooks
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

echo "✓ Hooks copied to ~/.claude/hooks/"

# Check if settings.json exists
SETTINGS_FILE="$HOME/.claude/settings.json"

if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "⚠ Settings file not found. Creating new one..."
    cat > "$SETTINGS_FILE" <<'EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/prevent-sleep.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/allow-sleep.sh"
          }
        ]
      }
    ]
  }
}
EOF
    echo "✓ Created settings.json with hooks configuration"
else
    echo "⚠ Settings file exists. You need to manually add hooks to ~/.claude/settings.json"
    echo ""
    echo "Add this to your settings.json:"
    echo ""
    cat <<'EOF'
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/prevent-sleep.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.claude/hooks/allow-sleep.sh"
          }
        ]
      }
    ]
  }
EOF
fi

echo ""
echo "Installation complete!"
echo ""
echo "To enable hooks, run:"
echo "  claude /hooks enable"
echo ""
echo "Or manually run: /hooks enable in your next Claude Code session"
