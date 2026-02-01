import Testing
@testable import NoSleepAgentLib
import Foundation

@Suite("ProcessMonitor Tests")
struct ProcessMonitorTests {

    // MARK: - ProcessInfo Tests

    @Test("ProcessInfo equality")
    func testProcessInfoEquality() {
        let proc1 = ProcessInfo(pid: 12345, cpuPercent: 78.5)
        let proc2 = ProcessInfo(pid: 12345, cpuPercent: 78.5)
        let proc3 = ProcessInfo(pid: 54321, cpuPercent: 78.5)

        #expect(proc1 == proc2)
        #expect(proc1 != proc3)
    }

    @Test("ProcessInfo id property")
    func testProcessInfoId() {
        let process = ProcessInfo(pid: 12345, cpuPercent: 78.5)
        #expect(process.id == 12345)
    }

    // MARK: - ProcessMonitor Tests

    @Test("ProcessMonitor initialization")
    func testProcessMonitorInit() {
        let monitor = ProcessMonitor()
        #expect(monitor != nil)
    }

    @Test("Get claude processes returns array")
    func testGetClaudeProcesses() {
        let monitor = ProcessMonitor()
        let processes = monitor.getClaudeProcesses()

        // Should return an array (may be empty if no claude processes running)
        #expect(processes is [ProcessInfo])
    }

    @Test("Kill non-existent process returns false")
    func testKillNonExistentProcess() {
        let monitor = ProcessMonitor()
        // Use an invalid PID (999999 is unlikely to exist)
        let result = monitor.killProcess(pid: 999999)

        // Should return false for non-existent process
        #expect(!result)
    }
}
