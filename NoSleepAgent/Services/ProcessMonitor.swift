import Foundation

public final class ProcessMonitor {
    public init() {}

    /// Fetches all running Claude Code processes with their CPU usage (async to avoid blocking UI)
    public func getClaudeProcesses() async -> [ClaudeProcess] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
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
                        continuation.resume(returning: [])
                        return
                    }

                    continuation.resume(returning: self.parseProcessOutput(output))
                } catch {
                    print("Failed to execute ps command: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// Kills a process with the given PID, first trying SIGTERM, then SIGKILL (async to avoid blocking UI)
    public func killProcess(pid: Int32) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Try SIGTERM first for graceful termination
                if kill(pid, SIGTERM) == 0 {
                    // Wait a bit to see if process terminates (off main thread now)
                    usleep(500_000) // 500ms

                    // Check if process is still alive
                    if kill(pid, 0) != 0 {
                        continuation.resume(returning: true) // Process terminated
                        return
                    }
                }

                // Fall back to SIGKILL
                continuation.resume(returning: kill(pid, SIGKILL) == 0)
            }
        }
    }

    // MARK: - Private

    private func parseProcessOutput(_ output: String) -> [ClaudeProcess] {
        let lines = output.split(separator: "\n")

        // Skip header line
        guard lines.count > 1 else { return [] }

        var processes: [ClaudeProcess] = []

        for line in lines.dropFirst() {
            // ps aux output format:
            // USER       PID  %CPU %MEM      VSZ    RSS   TT  STAT STARTED      TIME COMMAND
            let columns = line.split(separator: " ", omittingEmptySubsequences: true)

            guard columns.count >= 11 else { continue }

            // Check if command is specifically the Claude Code executable
            // Look for "claude" as an executable name, not just anywhere in the command
            let command = columns[10...].joined(separator: " ")
            let commandLower = command.lowercased()

            // More specific filtering: look for claude executable or claude code processes
            // Avoid matching file paths like /Users/claude/... or processes from this app
            guard commandLower.contains("/claude") ||
                  commandLower.hasPrefix("claude") ||
                  commandLower.contains("claude code") else {
                continue
            }

            // Additional safety: exclude this app itself
            if commandLower.contains("nosleepagent") {
                continue
            }

            // Parse PID and CPU%
            guard let pid = Int32(columns[1]),
                  let cpuPercent = Double(columns[2]) else {
                continue
            }

            processes.append(ClaudeProcess(pid: pid, cpuPercent: cpuPercent))
        }

        return processes.sorted { $0.cpuPercent > $1.cpuPercent }
    }
}
