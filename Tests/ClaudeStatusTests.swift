import Testing
@testable import NoSleepAgentLib
import Foundation

@Suite("ClaudeStatus Tests")
struct ClaudeStatusTests {

    // MARK: - TaskInfo Tests

    @Test("TaskInfo equality")
    func testTaskInfoEquality() {
        let task1 = TaskInfo(prompt: "Test prompt", project: "MyProject", sessionSlug: "abc123")
        let task2 = TaskInfo(prompt: "Test prompt", project: "MyProject", sessionSlug: "abc123")
        let task3 = TaskInfo(prompt: "Different", project: "MyProject", sessionSlug: "abc123")

        #expect(task1 == task2)
        #expect(task1 != task3)
    }

    @Test("Short prompt with short text")
    func testShortPrompt_shortText() {
        let task = TaskInfo(prompt: "Add tests", project: "MyProject", sessionSlug: "abc123")
        #expect(task.shortPrompt == "Add tests")
    }

    @Test("Short prompt with multiline text")
    func testShortPrompt_multiLine() {
        let task = TaskInfo(
            prompt: "Add comprehensive tests\nFor all components\nWith good coverage",
            project: "MyProject",
            sessionSlug: "abc123"
        )
        #expect(task.shortPrompt == "Add comprehensive tests")
    }

    @Test("Short prompt with long text")
    func testShortPrompt_longText() {
        let longPrompt = "This is a very long prompt that exceeds 60 characters and should be truncated"
        let task = TaskInfo(prompt: longPrompt, project: "MyProject", sessionSlug: "abc123")

        #expect(task.shortPrompt.count == 60)
        #expect(task.shortPrompt.hasSuffix("..."))
        #expect(task.shortPrompt == "This is a very long prompt that exceeds 60 characters and...")
    }

    @Test("Short prompt with exactly 60 characters")
    func testShortPrompt_exactly60Characters() {
        let prompt = "This prompt is exactly 60 characters long for our test case."
        #expect(prompt.count == 60)
        let task = TaskInfo(prompt: prompt, project: "MyProject", sessionSlug: "abc123")

        #expect(task.shortPrompt == prompt)
        #expect(!task.shortPrompt.hasSuffix("..."))
    }

    // MARK: - ClaudeStatus Tests

    @Test("Status equality")
    func testStatusEquality() {
        let idle1 = ClaudeStatus.idle
        let idle2 = ClaudeStatus.idle

        let task = TaskInfo(prompt: "Test", project: "Project", sessionSlug: "123")
        let date = Date()
        let working1 = ClaudeStatus.working(since: date, task: task)
        let working2 = ClaudeStatus.working(since: date, task: task)

        #expect(idle1 == idle2)
        #expect(working1 == working2)
        #expect(idle1 != working1)
    }

    @Test("Is working property")
    func testIsWorking() {
        let idle = ClaudeStatus.idle
        let working = ClaudeStatus.working(since: Date(), task: nil)

        #expect(!idle.isWorking)
        #expect(working.isWorking)
    }

    @Test("Duration when idle")
    func testDuration_idle() {
        let status = ClaudeStatus.idle
        #expect(status.duration == nil)
    }

    @Test("Duration when working")
    func testDuration_working() {
        let startTime = Date().addingTimeInterval(-125) // 2 minutes, 5 seconds ago
        let status = ClaudeStatus.working(since: startTime, task: nil)

        guard let duration = status.duration else {
            Issue.record("Duration should not be nil for working status")
            return
        }

        // Allow for small time drift in test execution
        #expect(duration >= 124)
        #expect(duration <= 126)
    }

    @Test("Task when idle")
    func testTask_idle() {
        let status = ClaudeStatus.idle
        #expect(status.task == nil)
    }

    @Test("Task when working")
    func testTask_working() {
        let task = TaskInfo(prompt: "Test task", project: "MyProject", sessionSlug: "abc123")
        let status = ClaudeStatus.working(since: Date(), task: task)

        #expect(status.task == task)
    }

    @Test("Display text when idle")
    func testDisplayText_idle() {
        let status = ClaudeStatus.idle
        #expect(status.displayText == "Idle")
    }

    @Test("Display text when working (seconds)")
    func testDisplayText_workingSeconds() {
        let startTime = Date().addingTimeInterval(-45) // 45 seconds ago
        let status = ClaudeStatus.working(since: startTime, task: nil)

        let displayText = status.displayText
        #expect(displayText.hasPrefix("Working ("))
        #expect(displayText.contains("s)"))
        #expect(!displayText.contains("m"))
    }

    @Test("Display text when working (minutes)")
    func testDisplayText_workingMinutes() {
        let startTime = Date().addingTimeInterval(-125) // 2 minutes, 5 seconds ago
        let status = ClaudeStatus.working(since: startTime, task: nil)

        let displayText = status.displayText
        #expect(displayText.hasPrefix("Working ("))
        #expect(displayText.contains("m"))
        #expect(displayText.contains("s)"))
    }

    @Test("Display text with exact minute")
    func testDisplayText_exactMinute() {
        let startTime = Date().addingTimeInterval(-120) // Exactly 2 minutes ago
        let status = ClaudeStatus.working(since: startTime, task: nil)

        let displayText = status.displayText
        #expect(displayText.contains("2m 0s") || displayText.contains("1m 59s") || displayText.contains("2m 1s"))
    }
}
