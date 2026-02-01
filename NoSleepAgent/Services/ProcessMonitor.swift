import Foundation
import OSLog

private let logger = Logger(subsystem: "com.nosleep.agent", category: "ProcessMonitor")

public final class ProcessMonitor {
    private let selfPID: Int32

    public init(selfPID: Int32 = ProcessInfo.processInfo.processIdentifier) {
        self.selfPID = selfPID
    }

    public func fetchProcesses() async -> [ClaudeProcess] {
        logger.debug("Starting process fetch")
        let output = await runPS()
        logger.debug("ps aux returned \(output.count) bytes")
        var processes = parseProcesses(from: output)

        // Enrich with project names from working directories
        for i in processes.indices {
            logger.debug("Enriching PID \(processes[i].pid) with project info")
            if let project = await getProjectName(for: processes[i].pid) {
                processes[i] = ClaudeProcess(
                    pid: processes[i].pid,
                    cpuPercent: processes[i].cpuPercent,
                    project: project
                )
            }
        }

        logger.debug("Detected \(processes.count) Claude Code processes")
        return processes
    }

    public func killProcess(_ pid: Int32) -> Bool {
        // First try SIGTERM
        let termResult = kill(pid, SIGTERM)
        if termResult != 0 {
            return false
        }

        // Wait 500ms for graceful shutdown
        Thread.sleep(forTimeInterval: 0.5)

        // Check if still alive
        let stillAlive = kill(pid, 0) == 0
        if stillAlive {
            // Force kill with SIGKILL
            kill(pid, SIGKILL)
        }

        return true
    }

    // MARK: - Internal (exposed for testing)

    func parseProcesses(from output: String) -> [ClaudeProcess] {
        var processes: [ClaudeProcess] = []

        let lines = output.components(separatedBy: .newlines)
        logger.debug("Parsing ps output, found \(lines.count) total lines")

        for line in lines {
            // Only match lines containing "claude" (case-insensitive)
            guard line.lowercased().contains("claude") else { continue }

            logger.debug("Found claude process: \(line)")

            // Exclude Claude Desktop app and all its helpers
            let lowerLine = line.lowercased()
            if lowerLine.contains("/applications/claude.app") ||
               lowerLine.contains("claude helper") ||
               lowerLine.contains("chrome-native-host") {
                logger.debug("Excluding desktop app/helper: \(line)")
                continue
            }

            let columns = line.split(whereSeparator: { $0.isWhitespace })
            // ps aux format: USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
            // Index:         0    1   2    3    4   5   6   7    8     9    10+
            guard columns.count >= 11,
                  let pid = Int32(columns[1]),
                  let cpu = Double(columns[2]) else {
                continue
            }

            // Extract the command (column 10+)
            let command = columns[10...].joined(separator: " ")

            // Get the executable name (last component of path or first word)
            let executablePath = String(columns[10])
            let executable = executablePath.split(separator: "/").last.map(String.init) ?? executablePath

            // Only match actual Claude CLI processes:
            // 1. Executable is "claude" (e.g., "claude --dangerously-skip-permissions")
            // 2. Executable is "node" with "claude" in args (e.g., "node /path/to/claude-code")
            // Exclude shell wrappers (zsh, bash, find, etc.) even if they have "claude" in paths
            let isClaudeExecutable = executable.lowercased() == "claude"
            let isNodeWithClaude = executable.lowercased() == "node" && command.lowercased().contains("claude")

            guard isClaudeExecutable || isNodeWithClaude else {
                logger.debug("Excluding non-Claude executable: \(command)")
                continue
            }

            // Exclude self
            if pid == selfPID { continue }

            processes.append(ClaudeProcess(pid: pid, cpuPercent: cpu))
        }

        return processes
    }

    private func getProjectName(for pid: Int32) async -> String? {
        let cwd = await runCommand("/usr/sbin/lsof", args: ["-a", "-p", "\(pid)", "-d", "cwd", "-Fn"])
        // lsof output format: p<pid>\nn<path>
        let lines = cwd.components(separatedBy: .newlines)
        for line in lines where line.hasPrefix("n") {
            let path = String(line.dropFirst()) // Remove 'n' prefix
            // Extract last component as project name
            return URL(fileURLWithPath: path).lastPathComponent
        }
        return nil
    }

    private func runCommand(_ executable: String, args: [String]) async -> String {
        await withCheckedContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = args
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                let output = String(data: data, encoding: .utf8) ?? ""
                continuation.resume(returning: output)
            } catch {
                continuation.resume(returning: "")
            }
        }
    }

    private func runPS() async -> String {
        await runCommand("/bin/ps", args: ["aux"])
    }
}
