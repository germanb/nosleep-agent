import SwiftUI
import ServiceManagement

public struct MenuContent: View {
    let monitor: StatusMonitor
    let notificationManager: NotificationManager

    public init(monitor: StatusMonitor, notificationManager: NotificationManager) {
        self.monitor = monitor
        self.notificationManager = notificationManager
    }
    @State private var currentTime = Date()
    @State private var launchAtLogin = false
    @State private var claudeProcesses: [ClaudeProcess] = []
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let processMonitor = ProcessMonitor()

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(monitor.status.displayText)
                .font(.headline)

            if let task = monitor.status.task {
                Divider()

                Text(task.project)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(task.shortPrompt)
                    .font(.caption)
                    .lineLimit(2)
                    .padding(.top, 2)

                if !task.sessionSlug.isEmpty {
                    Text(task.sessionSlug)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 1)
                }
            }

            Divider()

            // Claude Processes Section
            if !claudeProcesses.isEmpty {
                Text("Claude Processes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(claudeProcesses) { process in
                    HStack {
                        Text("PID \(process.pid)")
                            .font(.caption)
                        Text(String(format: "%.0f%%", process.cpuPercent))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Kill") {
                            killProcess(pid: process.pid)
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }

                Divider()
            }

            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    toggleLaunchAtLogin(newValue)
                }

            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, newValue in
                    if newValue {
                        Task {
                            await notificationManager.requestPermissions()
                        }
                    }
                }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            checkLaunchAtLoginStatus()
            Task {
                await refreshProcesses()
            }
        }
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

    private func refreshProcesses() async {
        claudeProcesses = await processMonitor.getClaudeProcesses()
    }

    private func killProcess(pid: Int32) {
        Task {
            _ = await processMonitor.killProcess(pid: pid)
            // Refresh the process list after kill completes
            await refreshProcesses()
        }
    }
}
