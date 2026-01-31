import Foundation
import Observation

@Observable
@MainActor
final class StatusMonitor {
    private(set) var status: ClaudeStatus = .idle

    private let pidFilePath = "/tmp/claude-caffeinate.pid"
    private let sessionParser = SessionParser()
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var pollTimer: Timer?
    private var workingStartTime: Date?

    func startMonitoring() {
        checkStatus()
        setupFileWatcher()
        setupPollTimer()
    }

    func stopMonitoring() {
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
              let pidString = try? String(contentsOfFile: pidFilePath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = Int32(pidString) else {
            transitionToIdle()
            return
        }

        let isAlive = kill(pid, 0) == 0

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
            workingStartTime = nil
            status = .idle
        }
    }
}
