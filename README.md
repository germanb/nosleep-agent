# NoSleepAgent

Hooks to prevent your Mac from sleeping while AI agents (like Claude Code) are working.

## Features

- **Prevent Sleep**: Automatically keeps your Mac awake when you submit prompts to Claude
- **Auto Sleep**: Allows sleep when Claude stops or you're done
- **Fast Hooks**: Optimized hooks that return instantly (0.003s) without hanging
- **Zero Config**: Just install and it works

## Installation

### Quick Install

```bash
# Clone or download this repo
cd nosleep-agent

# Run the installer
./install.sh
```

### Manual Install

1. Copy the hooks to your Claude config:
```bash
mkdir -p ~/.claude/hooks
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

2. Add to your `~/.claude/settings.json`:
```json
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
```

3. Enable hooks in Claude:
```bash
claude /hooks enable
```

## How It Works

- **prevent-sleep.sh**: Runs when you submit a prompt, starts `caffeinate` to prevent system sleep
- **allow-sleep.sh**: Runs when Claude stops, kills `caffeinate` to allow normal sleep

The hooks are optimized to:
- Fork immediately to background (instant return)
- Check if caffeinate is already running (avoid redundant restarts)
- Run in 0.003s after initial setup

## Uninstall

```bash
# Remove hooks
rm -rf ~/.claude/hooks

# Disable hooks in Claude
claude /hooks disable

# Or manually remove the "hooks" section from ~/.claude/settings.json
```

## Why This Exists

Long-running AI agent tasks can take minutes or hours. If your Mac sleeps, the agent's work gets interrupted. This keeps your Mac awake while agents are actively working, then allows normal sleep behavior when you're done.

## Requirements

- macOS (uses `caffeinate` command)
- Claude Code CLI (or any tool that supports hooks)

## License

MIT
