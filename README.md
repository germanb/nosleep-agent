# NoSleepAgent ☕

Keep your Mac awake while Claude Code works. No more interrupted AI sessions due to sleep mode.

## What It Does

When you're using Claude Code, NoSleepAgent:
- ✅ Prevents your Mac from sleeping during active tasks
- ✅ Shows what Claude is working on in your menu bar
- ✅ Notifies you when long tasks complete (optional)
- ✅ Automatically allows sleep when Claude is idle

## Quick Start

### 1. Install with Claude Code

Just say to Claude:
```
Install https://github.com/germanb/nosleep-agent
```

Claude will:
- Clone and build the app
- Set up the hooks automatically
- Launch the menu bar app

### 2. That's it!

Look for the coffee cup icon ☕ in your menu bar. When Claude starts working, it'll keep your Mac awake.

## Settings

Click the menu bar icon to:
- **Launch at Login** - Auto-start when you log in
- **Enable Notifications** - Get alerts when tasks ≥5 minutes complete
- See current task info (project, prompt, duration)

## Manual Installation (if needed)

If Claude Code doesn't install it automatically:

```bash
# Clone and build
git clone https://github.com/germanb/nosleep-agent.git
cd nosleep-agent
swift build -c release

# Add hooks to ~/.claude/settings.json
{
  "hooks": {
    "agent-start": "~/nosleep-agent/hooks/prevent-sleep.sh",
    "agent-stop": "~/nosleep-agent/hooks/allow-sleep.sh"
  }
}

# Run the app
open .build/release/NoSleepAgent
```

## How It Works

Simple: when Claude Code starts a task, the hooks run `caffeinate` to prevent sleep. When the task finishes, sleep is allowed again. The menu bar app monitors this and shows you what's happening.

## Troubleshooting

**Menu bar icon not showing?**
- Make sure the app is running (check Activity Monitor)
- Try rebuilding: `swift build -c release`

**Mac still sleeping?**
- Check that hooks are configured in `~/.claude/settings.json`
- Verify the hook scripts have execute permissions: `chmod +x hooks/*.sh`

**Not seeing task info?**
- Task info comes from Claude session files (`~/.claude/projects/`)
- May take a few seconds to appear after starting a task

**Process count seems wrong?**
- View real-time logs to see what's being detected:
  ```bash
  log stream --predicate 'subsystem == "com.nosleep.agent"' --level debug
  ```
- View recent logs:
  ```bash
  log show --predicate 'subsystem == "com.nosleep.agent"' --last 5m --info
  ```

## Requirements

- macOS 14.0 or later
- Claude Code CLI

## Icon Styles

The app defaults to a coffee cup icon. You can change it by modifying `NoSleepAgentApp.swift`:
- ☕ Coffee Cup (default)
- ✨ Sparkles AI
- 💻 CPU Agent
- ⚙️ Dual Gears
- ⚫ Simple Dot

## Contributing

Issues and PRs welcome! This is a simple tool to make Claude Code usage better.

## License

MIT - Use it however you want.

---

**Made for [Claude Code](https://claude.com/claude-code)** 🤖
