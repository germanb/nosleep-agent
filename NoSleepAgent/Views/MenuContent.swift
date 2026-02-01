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
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
}
