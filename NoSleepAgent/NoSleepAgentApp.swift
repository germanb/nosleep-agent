import SwiftUI
import NoSleepAgentLib

@main
struct NoSleepAgentApp: App {
    @State private var notificationManager: NotificationManager
    @State private var monitor: StatusMonitor
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    init() {
        let notifManager = MainActor.assumeIsolated { NotificationManager() }
        _notificationManager = State(initialValue: notifManager)
        _monitor = State(initialValue: MainActor.assumeIsolated {
            StatusMonitor(notificationManager: notifManager)
        })
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(monitor: monitor, notificationManager: notificationManager)
                .task {
                    monitor.startMonitoring()

                    // Request permissions if notifications enabled
                    if notificationsEnabled {
                        _ = await notificationManager.requestPermissions()
                    }
                }
        } label: {
            StatusIcon(status: monitor.status, style: .coffee)
        }
        .menuBarExtraStyle(.window)
    }
}
