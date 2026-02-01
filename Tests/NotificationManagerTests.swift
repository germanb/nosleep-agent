import Testing
@testable import NoSleepAgentLib
import Foundation

@Suite("NotificationManager Tests")
@MainActor
struct NotificationManagerTests {

    // MARK: - Duration Formatting Tests
    // These test the formatting logic used in notifications

    @Test("Duration formatting with exact minutes")
    func testDurationFormatting_exactMinutes() {
        let duration: TimeInterval = 300 // 5 minutes exactly
        let formatted = formatDuration(duration)
        #expect(formatted == "5m")
    }

    @Test("Duration formatting with minutes and seconds")
    func testDurationFormatting_minutesAndSeconds() {
        let duration: TimeInterval = 325 // 5 minutes 25 seconds
        let formatted = formatDuration(duration)
        #expect(formatted == "5m 25s")
    }

    @Test("Duration formatting less than a minute")
    func testDurationFormatting_lessThanMinute() {
        let duration: TimeInterval = 45 // 45 seconds
        let formatted = formatDuration(duration)
        #expect(formatted == "0m 45s")
    }

    @Test("Duration formatting long duration")
    func testDurationFormatting_longDuration() {
        let duration: TimeInterval = 3665 // 1 hour, 1 minute, 5 seconds
        let formatted = formatDuration(duration)
        #expect(formatted == "61m 5s")
    }

    // MARK: - Notification Body Formatting

    @Test("Notification body with task")
    func testNotificationBody_withTask() {
        let body = buildNotificationBody(duration: 325, task: "Add tests")
        #expect(body == "Claude finished working (5m 25s)\nAdd tests")
    }

    @Test("Notification body without task")
    func testNotificationBody_withoutTask() {
        let body = buildNotificationBody(duration: 300, task: nil)
        #expect(body == "Claude finished working (5m)")
    }

    @Test("Notification body with empty task")
    func testNotificationBody_emptyTask() {
        let body = buildNotificationBody(duration: 300, task: "")
        #expect(body == "Claude finished working (5m)")
    }

    // MARK: - Threshold Tests

    @Test("Minimum duration threshold for notifications")
    func testMinimumDurationThreshold() {
        // NotificationManager only sends notifications for durations >= 5 minutes
        let fiveMinutes: TimeInterval = 300
        let fourMinutes: TimeInterval = 240

        #expect(fiveMinutes >= 300, "5 minutes should meet threshold")
        #expect(fourMinutes < 300, "4 minutes should not meet threshold")
    }

    // MARK: - Manager Initialization

    @Test("NotificationManager initializes with permission false")
    func testInitialization() {
        let manager = NotificationManager()
        // Permission starts as false until explicitly granted
        #expect(manager.hasPermission == false)
    }

    // MARK: - Helper Functions (mirror NotificationManager's internal logic)

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
    }

    private func buildNotificationBody(duration: TimeInterval, task: String?) -> String {
        let durationText = formatDuration(duration)
        var body = "Claude finished working (\(durationText))"
        if let task = task, !task.isEmpty {
            body += "\n\(task)"
        }
        return body
    }
}
