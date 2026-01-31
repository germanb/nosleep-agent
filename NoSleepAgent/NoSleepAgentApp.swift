import SwiftUI

@main
struct NoSleepAgentApp: App {
    @State private var monitor = StatusMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(monitor: monitor)
                .task {
                    monitor.startMonitoring()
                }
        } label: {
            StatusIcon(status: monitor.status, style: .coffee)
        }
        .menuBarExtraStyle(.menu)
    }
}
