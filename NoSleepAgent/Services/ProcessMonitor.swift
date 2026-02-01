import Foundation
import OSLog

private let logger = Logger(subsystem: "com.nosleep.agent", category: "ProcessMonitor")

public final class ProcessMonitor {
    private let selfPID: Int32

    public init(selfPID: Int32 = ProcessInfo.processInfo.processIdentifier) {
        self.selfPID = selfPID
    }

    public func fetchProcesses() async -> [ClaudeProcess] {
        // Get Claude process PIDs using pgrep (much faster than ps aux)
        let pids = await getClaudeProcessPIDs()

        // Batch fetch all project names in a single lsof call
        let projectNames = await getProjectNames(for: pids)

        // Build process list
        return pids.map { pid in
            ClaudeProcess(pid: pid, project: projectNames[pid] ?? "")
        }
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

    /// Get Claude process PIDs using pgrep - much faster than ps aux
    private func getClaudeProcessPIDs() async -> [Int32] {
        // Use pgrep to find claude processes
        // -i: case insensitive
        // -f: match full command line (to catch node processes running claude)
        let output = await runCommand("/usr/bin/pgrep", args: ["-if", "claude"])

        let pids = output.components(separatedBy: .newlines)
            .compactMap { Int32($0.trimmingCharacters(in: .whitespaces)) }
            .filter { $0 != selfPID }

        // Filter out Claude Desktop app and helpers
        return await filterClaudeProcesses(pids)
    }

    /// Filter out Claude Desktop app and helper processes
    private func filterClaudeProcesses(_ pids: [Int32]) async -> [Int32] {
        guard !pids.isEmpty else { return [] }

        // Batch fetch all command lines in a single ps call
        let pidList = pids.map(String.init).joined(separator: ",")
        let output = await runCommand("/bin/ps", args: ["-p", pidList, "-o", "pid=,command="])

        var validPIDs: [Int32] = []

        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Parse "PID COMMAND" format - PID is first whitespace-separated token
            let components = trimmed.split(separator: " ", maxSplits: 1)
            guard components.count >= 2,
                  let pid = Int32(components[0]) else { continue }

            let cmd = String(components[1]).lowercased()

            // Exclude Claude Desktop app and all its helpers
            if cmd.contains("/applications/claude.app") ||
               cmd.contains("claude helper") ||
               cmd.contains("chrome-native-host") {
                continue
            }

            // Only include actual Claude CLI processes
            if cmd.contains("claude") {
                validPIDs.append(pid)
            }
        }

        return validPIDs
    }

    /// Batch fetch project names for multiple PIDs in a single lsof call
    private func getProjectNames(for pids: [Int32]) async -> [Int32: String] {
        guard !pids.isEmpty else { return [:] }

        // Build comma-separated PID list for lsof
        let pidList = pids.map(String.init).joined(separator: ",")

        // Single lsof call for all processes
        let output = await runCommand("/usr/sbin/lsof", args: ["-a", "-p", pidList, "-d", "cwd", "-Fn"])

        // Parse output: p<pid>\nn<path>\np<pid2>\nn<path2>...
        var projectNames: [Int32: String] = [:]
        var currentPID: Int32?

        for line in output.components(separatedBy: .newlines) {
            if line.hasPrefix("p") {
                currentPID = Int32(line.dropFirst())
            } else if line.hasPrefix("n"), let pid = currentPID {
                let path = String(line.dropFirst())
                let projectName = URL(fileURLWithPath: path).lastPathComponent
                projectNames[pid] = projectName
            }
        }

        return projectNames
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

}
