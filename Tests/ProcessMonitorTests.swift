import Testing
@testable import NoSleepAgentLib
import Foundation

@Suite("ProcessMonitor Tests")
struct ProcessMonitorTests {

    // MARK: - Kill Tests

    @Test("Kill returns false for non-existent PID")
    func testKillNonExistentPID() {
        let monitor = ProcessMonitor(selfPID: 99999)
        // Use a PID that's very unlikely to exist
        let result = monitor.killProcess(999999)

        #expect(result == false)
    }

    // Note: Most ProcessMonitor functionality now uses pgrep/lsof which are
    // difficult to test without actual running processes. The core logic is
    // simple enough that integration testing is more valuable than unit tests.
    // The kill functionality above is tested since it has clear failure cases.
}
