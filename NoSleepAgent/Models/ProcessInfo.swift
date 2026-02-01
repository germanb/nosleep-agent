import Foundation

public struct ClaudeProcess: Equatable, Identifiable {
    public let pid: Int32
    public let cpuPercent: Double

    public var id: Int32 { pid }

    public init(pid: Int32, cpuPercent: Double) {
        self.pid = pid
        self.cpuPercent = cpuPercent
    }
}
