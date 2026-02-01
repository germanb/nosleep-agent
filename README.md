# NoSleepAgent ☕

Keep your Mac awake while Claude Code works. No more interrupted AI sessions due to sleep mode.

## What It Does

When you're using Claude Code, NoSleepAgent:
- ✅ Prevents your Mac from sleeping during active tasks
- ✅ Shows active Claude Code processes in your menu bar
- ✅ Monitors CPU usage and allows killing hung processes
- ✅ Shows what Claude is working on
- ✅ Notifies you when long tasks complete (optional)
- ✅ Automatically allows sleep when Claude is idle

## Features

### Process Monitoring
View all running Claude Code CLI processes with:
- Real-time CPU usage
- Process ID (PID)
- Project name (when available)
- One-click kill for hung processes

The app accurately detects only Claude Code CLI processes, excluding Claude Desktop app and its helpers.

### Sleep Prevention
Automatically prevents macOS sleep during active Claude Code sessions using hooks.

### Task Notifications
Get notified when long-running tasks (≥5 minutes) complete.

## Installation

### Quick Install (Recommended)
Ask Claude Code:
```
Install https://github.com/germanb/nosleep-agent
```

### Manual Install
```bash
git clone https://github.com/germanb/nosleep-agent.git
cd nosleep-agent
./build-app.sh
open NoSleepAgent.app
```

Add hooks to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "agent-start": "~/nosleep-agent/hooks/prevent-sleep.sh",
    "agent-stop": "~/nosleep-agent/hooks/allow-sleep.sh"
  }
}
```

## Settings

Click the menu bar icon to:
- **Launch at Login** - Auto-start when you log in
- **Enable Notifications** - Get alerts when tasks ≥5 minutes complete
- See current task info (project, prompt, duration)
- View and manage running Claude Code processes

## How It Works

Simple: when Claude Code starts a task, the hooks run `caffeinate` to prevent sleep. When the task finishes, sleep is allowed again. The menu bar app monitors this and shows you what's happening.

## Troubleshooting

### App Issues
**Menu bar icon not showing?**
- Check Activity Monitor for NoSleepAgent process
- Rebuild: `./build-app.sh`

**Process count seems wrong?**
The app only counts Claude Code CLI processes, not the Desktop app. View logs:
```bash
log stream --predicate 'subsystem == "com.nosleep.agent"' --level debug
```

### Sleep Prevention Issues
**Mac still sleeping during Claude tasks?**
- Verify hooks in `~/.claude/settings.json`
- Check permissions: `chmod +x hooks/*.sh`

### Task Info Issues
**Not seeing current task details?**
- Session data loads from `~/.claude/projects/`
- May take a few seconds to appear

## Requirements

- macOS 14.0 or later
- Claude Code CLI

## Contributing

Issues and PRs welcome! This is a simple tool to make Claude Code usage better.

## License

MIT - Use it however you want.

---

**Made for [Claude Code](https://claude.com/claude-code)** 🤖
