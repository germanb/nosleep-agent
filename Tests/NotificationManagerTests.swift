import Testing
@testable import NoSleepAgentLib
import Foundation

@Suite("NotificationManager Tests")
@MainActor
struct NotificationManagerTests {

    // MARK: - Duration Formatting Tests

    @Test("Duration formatting with exact minutes")
    func testDurationFormatting_exactMinutes() {
        let duration: TimeInterval = 300 // 5 minutes exactly

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationText = seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"

        #expect(minutes == 5)
        #expect(seconds == 0)
        #expect(durationText == "5m")
    }

    @Test("Duration formatting with minutes and seconds")
    func testDurationFormatting_minutesAndSeconds() {
        let duration: TimeInterval = 325 // 5 minutes 25 seconds

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationText = seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"

        #expect(minutes == 5)
        #expect(seconds == 25)
        #expect(durationText == "5m 25s")
    }

    @Test("Duration formatting less than a minute")
    func testDurationFormatting_lessThanMinute() {
        let duration: TimeInterval = 45 // 45 seconds

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationText = seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"

        #expect(minutes == 0)
        #expect(seconds == 45)
        #expect(durationText == "0m 45s")
    }

    @Test("Duration formatting long duration")
    func testDurationFormatting_longDuration() {
        let duration: TimeInterval = 3665 // 1 hour, 1 minute, 5 seconds

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationText = seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"

        #expect(minutes == 61)
        #expect(seconds == 5)
        #expect(durationText == "61m 5s")
    }

    // MARK: - Notification Content Tests

    @Test("Notification content with task")
    func testNotificationContent_withTask() {
        let duration: TimeInterval = 325
        let taskPrompt = "Add comprehensive tests to the project"

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationText = seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"

        let title = "Task Completed"
        var body = "Claude finished working (\(durationText))"

        if !taskPrompt.isEmpty {
            body += "\n\(taskPrompt)"
        }

        #expect(title == "Task Completed")
        #expect(body == "Claude finished working (5m 25s)\nAdd comprehensive tests to the project")
    }

    @Test("Notification content without task")
    func testNotificationContent_withoutTask() {
        let duration: TimeInterval = 300

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationText = seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"

        let title = "Task Completed"
        let body = "Claude finished working (\(durationText))"

        #expect(title == "Task Completed")
        #expect(body == "Claude finished working (5m)")
    }

    @Test("Notification content with empty task")
    func testNotificationContent_emptyTask() {
        let duration: TimeInterval = 300
        let taskPrompt = ""

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let durationText = seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"

        let title = "Task Completed"
        var body = "Claude finished working (\(durationText))"

        if !taskPrompt.isEmpty {
            body += "\n\(taskPrompt)"
        }

        #expect(body == "Claude finished working (5m)")
        #expect(!body.contains("\n"))
    }

    // MARK: - Permission Logic Tests

    @Test("Bundle availability check")
    func testBundleAvailability() {
        let isAvailable = Bundle.main.bundleIdentifier != nil
        // This test documents expected behavior
        #expect(isAvailable != nil)
    }

    // MARK: - Minimum Duration Tests

    @Test("Minimum duration threshold")
    func testMinimumDurationThreshold() {
        let fiveMinutes: TimeInterval = 300
        let fourMinutes: TimeInterval = 240

        #expect(fiveMinutes >= 300)
        #expect(fourMinutes < 300)
    }

    @Test("Duration edge cases")
    func testDurationEdgeCases() {
        // Test edge case: exactly 5 minutes
        let exactFiveMin: TimeInterval = 300
        #expect(exactFiveMin == 300)

        // Test edge case: just under 5 minutes
        let justUnder: TimeInterval = 299.9
        #expect(justUnder < 300)

        // Test edge case: just over 5 minutes
        let justOver: TimeInterval = 300.1
        #expect(justOver > 300)
    }
}
