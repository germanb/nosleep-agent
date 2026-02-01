import Foundation

public struct ClaudeProcess: Identifiable, Equatable {
    public let pid: Int32
    public let project: String

    public var id: Int32 { pid }

    public init(pid: Int32, project: String = "") {
        self.pid = pid
        self.project = project
    }
}
