import SwiftUI
import ServiceManagement

public struct MenuContent: View {
    let monitor: StatusMonitor
    let notificationManager: NotificationManager

    public init(monitor: StatusMonitor, notificationManager: NotificationManager) {
        self.monitor = monitor
        self.notificationManager = notificationManager
    }
    @State private var launchAtLogin = false
    @State private var processes: [ClaudeProcess] = []
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    private let processTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let processMonitor = ProcessMonitor()

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Claude Processes Section - Now primary content
            if !processes.isEmpty {
                ProcessesSectionView(
                    processes: processes,
                    currentTask: monitor.status.task,
                    onKillProcess: { pid in
                        _ = processMonitor.killProcess(pid)
                        Task {
                            processes = await processMonitor.fetchProcesses()
                        }
                    }
                )
                .padding(.top, 8)
                .padding(.bottom, 4)
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No Claude processes running")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }

            MenuDivider()

            // Minimal inline settings
            MinimalToggleItem(
                title: "Launch at Login",
                isOn: $launchAtLogin
            )
            .onChange(of: launchAtLogin) { _, newValue in
                toggleLaunchAtLogin(newValue)
            }

            MinimalToggleItem(
                title: "Notifications",
                isOn: $notificationsEnabled
            )
            .onChange(of: notificationsEnabled) { _, newValue in
                if newValue {
                    Task {
                        await notificationManager.requestPermissions()
                    }
                }
            }

            // Quit button (no divider, no shortcut display)
            MinimalButtonItem(title: "Quit NoSleep Agent") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .onReceive(processTimer) { _ in
            Task {
                processes = await processMonitor.fetchProcesses()
            }
        }
        .task {
            checkLaunchAtLoginStatus()
            processes = await processMonitor.fetchProcesses()
        }
        .frame(width: 280)
    }

    private func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func toggleLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }
}

// MARK: - Native macOS Components

/// Native macOS menu divider - 1px hairline
struct MenuDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(height: 1)
            .padding(.horizontal, 0)
    }
}

/// Processes section with native macOS list style
struct ProcessesSectionView: View {
    let processes: [ClaudeProcess]
    let currentTask: TaskInfo?
    let onKillProcess: (Int32) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("Claude Processes")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.3)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

            // Process list
            ForEach(processes) { process in
                ProcessRowView(
                    process: process,
                    taskInfo: shouldShowTask(for: process) ? currentTask : nil,
                    onKill: {
                        onKillProcess(process.pid)
                    }
                )
            }
        }
    }

    // Show task only on the most active process for that project
    // This prevents duplicate task info when multiple instances run in same folder
    private func shouldShowTask(for process: ClaudeProcess) -> Bool {
        guard let task = currentTask else { return false }
        guard !process.project.isEmpty && process.project == task.project else { return false }

        // Find all processes with the same project
        let sameProjectProcesses = processes.filter { $0.project == process.project }

        // If only one process, show the task
        guard sameProjectProcesses.count > 1 else { return true }

        // Show task only on the process with highest CPU usage
        let mostActive = sameProjectProcesses.max(by: { $0.cpuPercent < $1.cpuPercent })
        return mostActive?.pid == process.pid
    }
}

/// Native macOS menu item with status dot and hover effect
struct ProcessRowView: View {
    let process: ClaudeProcess
    let taskInfo: TaskInfo?
    let onKill: () -> Void
    @State private var isHovering = false

    // Determine process status based on CPU usage
    private var processStatus: ProcessStatus {
        if process.cpuPercent > 15.0 {
            return .active
        } else if process.cpuPercent > 3.0 {
            return .moderate
        } else {
            return .idle
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main process row
            HStack(spacing: 8) {
                // Status indicator dot
                Circle()
                    .fill(processStatus.color)
                    .frame(width: 6, height: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(process.project.isEmpty ? "claude-\(process.pid)" : process.project)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\(String(format: "%.1f", process.cpuPercent))% CPU")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Spacer(minLength: 8)

                // Kill button - appears on hover
                Button(action: onKill) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            // Task info - shown if this process has active task
            if let task = taskInfo {
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(processStatus.color.opacity(0.3))
                        .frame(width: 2)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.shortPrompt)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        if !task.sessionSlug.isEmpty {
                            Text(task.sessionSlug)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.trailing, 8)
                }
                .padding(.leading, 22) // Align with text above
                .padding(.trailing, 12)
                .padding(.bottom, 6)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Process Status
enum ProcessStatus {
    case active   // High CPU (> 15%)
    case moderate // Medium CPU (3-15%)
    case idle     // Low CPU (< 3%)

    var color: Color {
        switch self {
        case .active: return .green
        case .moderate: return .yellow
        case .idle: return .secondary.opacity(0.5)
        }
    }
}

/// Minimal toggle item - no hover, no icons, ultra clean
struct MinimalToggleItem: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.mini)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }
}

/// Minimal button item - ultra clean
struct MinimalButtonItem: View {
    let title: String
    let shortcut: String?
    let action: () -> Void
    @State private var isHovering = false

    init(title: String, shortcut: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.shortcut = shortcut
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Spacer()

                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Native macOS menu item button
struct MenuItemButton: View {
    let title: String
    let icon: String?
    let destructive: Bool
    let shortcut: String?
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(destructive ? .red : .secondary)
                        .frame(width: 16)
                }

                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(destructive ? .red : .primary)

                Spacer()

                if let shortcut = shortcut {
                    Text("⌘\(shortcut)")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovering ? (destructive ? Color.red.opacity(0.12) : Color.accentColor.opacity(0.08)) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .padding(.horizontal, 4)
    }
}
