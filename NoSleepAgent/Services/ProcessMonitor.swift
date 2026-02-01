import Foundation

public final class ProcessMonitor {
    public init() {}

    /// Fetches all running Claude Code processes with their CPU usage
    public func getClaudeProcesses() -> [ProcessInfo] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["aux"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return []
            }

            return parseProcessOutput(output)
        } catch {
            print("Failed to execute ps command: \(error)")
            return []
        }
    }

    /// Kills a process with the given PID, first trying SIGTERM, then SIGKILL
    public func killProcess(pid: Int32) -> Bool {
        // Try SIGTERM first for graceful termination
        if kill(pid, SIGTERM) == 0 {
            // Wait a bit to see if process terminates
            usleep(500_000) // 500ms

            // Check if process is still alive
            if kill(pid, 0) != 0 {
                return true // Process terminated
            }
        }

        // Fall back to SIGKILL
        return kill(pid, SIGKILL) == 0
    }

    // MARK: - Private

    private func parseProcessOutput(_ output: String) -> [ProcessInfo] {
        let lines = output.split(separator: "\n")

        // Skip header line
        guard lines.count > 1 else { return [] }

        var processes: [ProcessInfo] = []

        for line in lines.dropFirst() {
            // ps aux output format:
            // USER       PID  %CPU %MEM      VSZ    RSS   TT  STAT STARTED      TIME COMMAND
            let columns = line.split(separator: " ", omittingEmptySubsequences: true)

            guard columns.count >= 11 else { continue }

            // Check if command contains "claude"
            let command = columns[10...].joined(separator: " ")
            guard command.lowercased().contains("claude") else { continue }

            // Parse PID and CPU%
            guard let pid = Int32(columns[1]),
                  let cpuPercent = Double(columns[2]) else {
                continue
            }

            processes.append(ProcessInfo(pid: pid, cpuPercent: cpuPercent))
        }

        return processes.sorted { $0.cpuPercent > $1.cpuPercent }
    }
}
