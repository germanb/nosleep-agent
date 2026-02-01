import Foundation
import UserNotifications
import AppKit

/// Minimal notification service for task completion alerts
@MainActor
public class NotificationManager: ObservableObject {
    @Published public var hasPermission = false
    private var hasRequestedPermission = false
    private var isAvailable = false

    public init() {
        // Check if running in a proper app bundle (required for UserNotifications)
        isAvailable = Bundle.main.bundleIdentifier != nil
        if isAvailable {
            checkPermissionStatus()
        }
    }

    // MARK: - Permission Management

    /// Check current notification permission status
    private func checkPermissionStatus() {
        guard isAvailable else { return }

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Request notification permissions (ask once)
    public func requestPermissions() async -> Bool {
        guard isAvailable else {
            print("UserNotifications not available (app not running in bundle)")
            return false
        }

        // Only ask once per app lifecycle
        guard !hasRequestedPermission else { return hasPermission }
        hasRequestedPermission = true

        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])

            await MainActor.run {
                hasPermission = granted
            }

            return granted
        } catch {
            print("Failed to request notification permissions: \(error)")
            return false
        }
    }

    // MARK: - Notifications

    /// Send completion notification for tasks >= 5 minutes
    public func sendCompletionNotification(duration: TimeInterval, task: String?) {
        guard isAvailable && hasPermission else { return }

        // Format duration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationText = seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"

        // Build notification content
        let content = UNMutableNotificationContent()
        content.title = "Task Completed"
        content.body = "Claude finished working (\(durationText))"

        if let task = task, !task.isEmpty {
            content.body += "\n\(task)"
        }

        // Passive delivery (non-intrusive banner)
        content.interruptionLevel = .passive

        // Optional system beep
        content.sound = .default

        // Send immediately
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // nil = immediate delivery
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
}
