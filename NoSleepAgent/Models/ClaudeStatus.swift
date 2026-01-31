import Foundation

struct TaskInfo: Equatable {
    let prompt: String
    let project: String
    let sessionSlug: String

    var shortPrompt: String {
        let firstLine = prompt.split(separator: "\n").first.map(String.init) ?? prompt
        if firstLine.count > 60 {
            return String(firstLine.prefix(57)) + "..."
        }
        return firstLine
    }
}

enum ClaudeStatus: Equatable {
    case idle
    case working(since: Date, task: TaskInfo?)

    var isWorking: Bool {
        if case .working = self { return true }
        return false
    }

    var duration: TimeInterval? {
        guard case .working(let since, _) = self else { return nil }
        return Date().timeIntervalSince(since)
    }

    var task: TaskInfo? {
        guard case .working(_, let task) = self else { return nil }
        return task
    }

    var displayText: String {
        switch self {
        case .idle:
            return "Idle"
        case .working:
            guard let duration = duration else { return "Working" }
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            if minutes > 0 {
                return "Working (\(minutes)m \(seconds)s)"
            } else {
                return "Working (\(seconds)s)"
            }
        }
    }
}
