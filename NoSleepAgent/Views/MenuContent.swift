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
    @State private var processes: [ClaudeProcess] = []
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let processTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
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

            // Claude Processes Section
            if processes.isEmpty {
                Text("No Claude Processes")
            } else {
                Menu("Claude Processes (\(processes.count))") {
                    ForEach(processes) { process in
                        let label = process.project.isEmpty
                            ? "PID \(process.pid)"
                            : process.project
                        Button("Kill \(label) (\(String(format: "%.1f", process.cpuPercent))%)") {
                            _ = processMonitor.killProcess(process.pid)
                            Task {
                                processes = await processMonitor.fetchProcesses()
                            }
                        }
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
        .padding()
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
