import Foundation

public struct TaskInfo: Equatable {
    public let prompt: String
    public let project: String
    public let sessionSlug: String

    public init(prompt: String, project: String, sessionSlug: String) {
        self.prompt = prompt
        self.project = project
        self.sessionSlug = sessionSlug
    }

    public var shortPrompt: String {
        let firstLine = prompt.split(separator: "\n").first.map(String.init) ?? prompt
        if firstLine.count > 60 {
            return String(firstLine.prefix(57)) + "..."
        }
        return firstLine
    }
}

public enum ClaudeStatus: Equatable {
    case idle
    case working(since: Date, task: TaskInfo?)

    public var isWorking: Bool {
        if case .working = self { return true }
        return false
    }

    public var duration: TimeInterval? {
        guard case .working(let since, _) = self else { return nil }
        return Date().timeIntervalSince(since)
    }

    public var task: TaskInfo? {
        guard case .working(_, let task) = self else { return nil }
        return task
    }

    public var displayText: String {
        switch self {
        case .idle:
            return "Idle"
        case .working:
            return "Working"
        }
    }
}
