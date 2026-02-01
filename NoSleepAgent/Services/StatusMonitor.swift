import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
public final class StatusMonitor {
    public private(set) var status: ClaudeStatus = .idle

    private let pidFilePath = "/tmp/claude-caffeinate.pid"
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
            Task { @MainActor in
                self?.checkStatus()
            }
        }
    }

    private func checkStatus() {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: pidFilePath),
              let content = try? String(contentsOfFile: pidFilePath, encoding: .utf8) else {
            transitionToIdle()
            return
        }

        // Parse PID file (supports both new and old formats)
        let pid: Int32?
        let lines = content.components(separatedBy: .newlines)
        if let caffeinateLineIndex = lines.firstIndex(where: { $0.hasPrefix("CAFFEINATE_PID=") }),
           let pidString = lines[caffeinateLineIndex].components(separatedBy: "=").last {
            // New format: CAFFEINATE_PID=12345
            pid = Int32(pidString.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            // Old format: just the PID number
            pid = Int32(content.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        guard let caffeinatePid = pid else {
            transitionToIdle()
            return
        }

        let isAlive = kill(caffeinatePid, 0) == 0

        if isAlive {
            transitionToWorking()
        } else {
            transitionToIdle()
        }
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

    /// Get the Claude process PID that's preventing sleep
    public func getActiveClaudePID() -> Int32? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: pidFilePath),
              let content = try? String(contentsOfFile: pidFilePath, encoding: .utf8) else {
            return nil
        }

        // Parse new format: "CAFFEINATE_PID=12345\nCLAUDE_PID=6789"
        let lines = content.components(separatedBy: .newlines)
        for line in lines where line.hasPrefix("CLAUDE_PID=") {
            let pidString = String(line.dropFirst(11)) // Remove "CLAUDE_PID="
            if let pid = Int32(pidString), kill(pid, 0) == 0 { // Verify process is alive
                return pid
            }
        }

        return nil
    }
}
