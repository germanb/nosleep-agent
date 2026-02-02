import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
public final class StatusMonitor {
    public private(set) var status: ClaudeStatus = .idle

    private let pidFilePattern = "/tmp/claude-caffeinate-"
    private let sessionParser = SessionParser()
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var pollTimer: Timer?
    private var workingStartTime: Date?
    private var notificationManager: NotificationManager?

    public init(notificationManager: NotificationManager? = nil) {
        self.notificationManager = notificationManager
    }

    public func startMonitoring() {
        checkStatus()
        setupFileWatcher()
        setupPollTimer()
    }

    public func stopMonitoring() {
        dispatchSource?.cancel()
        dispatchSource = nil
        pollTimer?.invalidate()
        pollTimer = nil
        if fileDescriptor != -1 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func setupFileWatcher() {
        fileDescriptor = open("/tmp", O_EVTONLY)
        guard fileDescriptor != -1 else { return }

        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .extend],
            queue: .main
        )

        dispatchSource?.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.checkStatus()
            }
        }

        let fd = fileDescriptor
        dispatchSource?.setCancelHandler {
            if fd != -1 {
                close(fd)
            }
        }

        dispatchSource?.resume()
    }

    private func setupPollTimer() {
        // Poll every 2 seconds for more responsive task info updates
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.checkStatus()
            }
        }
    }

    private func checkStatus() {
        // Check if any caffeinate process from our hooks is running
        if hasAnyCaffeinateProcess() {
            transitionToWorking()
        } else {
            transitionToIdle()
        }
    }

    private func hasAnyCaffeinateProcess() -> Bool {
        let fileManager = FileManager.default

        // Get all PID files in /tmp matching our pattern
        do {
            let tmpContents = try fileManager.contentsOfDirectory(atPath: "/tmp")
            let pidFiles = tmpContents.filter { $0.hasPrefix("claude-caffeinate-") && $0.hasSuffix(".pid") }

            for pidFile in pidFiles {
                let fullPath = "/tmp/\(pidFile)"
                guard let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else {
                    continue
                }

                // Parse caffeinate PID
                let lines = content.components(separatedBy: .newlines)
                if let caffeinateLine = lines.first(where: { $0.hasPrefix("CAFFEINATE_PID=") }),
                   let pidString = caffeinateLine.components(separatedBy: "=").last,
                   let caffeinatePid = Int32(pidString.trimmingCharacters(in: .whitespacesAndNewlines)) {

                    // Check if this caffeinate process is still alive
                    if kill(caffeinatePid, 0) == 0 {
                        return true
                    }
                }
            }
        } catch {
            // If we can't read /tmp, fall back to checking for any caffeinate process
            return checkForAnyCaffeinateProcessViaProcFS()
        }

        return false
    }

    private func checkForAnyCaffeinateProcessViaProcFS() -> Bool {
        // Fallback: check if any caffeinate process with -dims flag is running
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["aux"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Look for caffeinate processes with -dims flag
                return output.contains("caffeinate -dims")
            }
        } catch {
            return false
        }

        return false
    }

    private func transitionToWorking() {
        let taskInfo = sessionParser.findActiveSession()

        if !status.isWorking {
            workingStartTime = Date()
        }

        status = .working(since: workingStartTime ?? Date(), task: taskInfo)
    }

    private func transitionToIdle() {
        if status.isWorking {
            // Send completion notification if enabled and duration >= 5 minutes
            if UserDefaults.standard.bool(forKey: "notificationsEnabled"),
               let startTime = workingStartTime {
                let duration = Date().timeIntervalSince(startTime)
                if duration >= 300 { // 5 minutes in seconds
                    let taskPrompt = status.task?.prompt
                    notificationManager?.sendCompletionNotification(
                        duration: duration,
                        task: taskPrompt
                    )
                }
            }

            workingStartTime = nil
            status = .idle
        }
    }

    /// Get the first active Claude process PID that's preventing sleep
    public func getActiveClaudePID() -> Int32? {
        let fileManager = FileManager.default

        do {
            let tmpContents = try fileManager.contentsOfDirectory(atPath: "/tmp")
            let pidFiles = tmpContents.filter { $0.hasPrefix("claude-caffeinate-") && $0.hasSuffix(".pid") }

            for pidFile in pidFiles {
                let fullPath = "/tmp/\(pidFile)"
                guard let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else {
                    continue
                }

                let lines = content.components(separatedBy: .newlines)
                for line in lines where line.hasPrefix("CLAUDE_PID=") {
                    let pidString = String(line.dropFirst(11))
                    if let pid = Int32(pidString), kill(pid, 0) == 0 {
                        return pid
                    }
                }
            }
        } catch {
            return nil
        }

        return nil
    }
}
