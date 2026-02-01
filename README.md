# NoSleepAgent

A macOS menu bar app that prevents your Mac from sleeping during Claude Code agent operations.

## Features

- **Automatic Sleep Prevention**: Monitors Claude Code agent activity and prevents Mac sleep while tasks are running
- **Session Tracking**: Displays current project name, task prompt, and working duration
- **Completion Notifications**: Get notified when long-running tasks (≥5 minutes) complete
- **Launch at Login**: Optional auto-start when you log in
- **Multiple Icon Styles**: Choose from coffee cup, sparkles, CPU, gears, or simple dot icons

## How It Works

NoSleepAgent integrates with Claude Code via hooks:
1. When Claude Code starts a task, the `prevent-sleep.sh` hook runs `caffeinate` to prevent sleep
2. The menu bar app monitors the caffeinate process and displays task info
3. When the task completes, `allow-sleep.sh` stops caffeinate and sends a notification (if enabled)

## Installation

### Prerequisites
- macOS 14.0 or later
- Swift 5.9+
- Claude Code CLI

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/nosleep-agent.git
cd nosleep-agent

# Build the app
swift build -c release

# Or build with Xcode
open Package.swift
```

### Setup Claude Code Hooks

Add these hooks to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "agent-start": "~/path/to/nosleep-agent/hooks/prevent-sleep.sh",
    "agent-stop": "~/path/to/nosleep-agent/hooks/allow-sleep.sh"
  }
}
```

## Usage

1. Launch NoSleepAgent (it appears in your menu bar)
2. Use Claude Code normally
3. The app automatically:
   - Prevents sleep when Claude is working
   - Shows task info in the menu
   - Sends notifications when tasks complete (if enabled)

## Configuration

- **Launch at Login**: Toggle in the menu to auto-start
- **Enable Notifications**: Toggle to receive task completion alerts
- **Icon Style**: Choose your preferred icon from 5 styles (configure in code)

## Development

### Run Tests

```bash
swift test
```

### Project Structure

```
NoSleepAgent/
├── Models/
│   └── ClaudeStatus.swift      # Task and status data models
├── Services/
│   ├── StatusMonitor.swift     # File watching and state management
│   ├── SessionParser.swift     # Parse Claude session files
│   └── NotificationManager.swift # macOS notifications
├── Views/
│   ├── MenuContent.swift       # Menu bar UI
│   └── StatusIcon.swift        # Icon rendering
└── NoSleepAgentApp.swift       # App entry point

hooks/
├── prevent-sleep.sh            # Start caffeinate
└── allow-sleep.sh              # Stop caffeinate

Tests/
├── ClaudeStatusTests.swift
├── SessionParserTests.swift
└── NotificationManagerTests.swift
```

## Technical Details

- Built with SwiftUI and Swift 5.9
- Uses `caffeinate` to prevent system sleep
- Monitors PID files in `/tmp` for agent status
- Parses Claude session files from `~/.claude/projects/`
- Sends passive notifications via UserNotifications framework

## License

MIT License - see LICENSE file for details

## Contributing

Contributions welcome! Please open an issue or PR.

## Acknowledgments

Built for use with [Claude Code](https://claude.com/claude-code) by Anthropic.
