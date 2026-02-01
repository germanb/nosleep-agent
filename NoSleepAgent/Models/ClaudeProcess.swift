import Foundation

public struct ClaudeProcess: Identifiable, Equatable {
    public let pid: Int32
    public let cpuPercent: Double
    public let project: String

    public var id: Int32 { pid }

    public init(pid: Int32, cpuPercent: Double, project: String = "") {
        self.pid = pid
        self.cpuPercent = cpuPercent
        self.project = project
    }
}
