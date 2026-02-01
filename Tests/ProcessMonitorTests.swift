import Testing
@testable import NoSleepAgentLib
import Foundation

@Suite("ProcessMonitor Tests")
struct ProcessMonitorTests {

    // MARK: - ClaudeProcess Tests

    @Test("ClaudeProcess equality")
    func testClaudeProcessEquality() {
        let proc1 = ClaudeProcess(pid: 12345, cpuPercent: 78.5)
        let proc2 = ClaudeProcess(pid: 12345, cpuPercent: 78.5)
        let proc3 = ClaudeProcess(pid: 54321, cpuPercent: 78.5)

        #expect(proc1 == proc2)
        #expect(proc1 != proc3)
    }

    @Test("ClaudeProcess id property")
    func testClaudeProcessId() {
        let process = ClaudeProcess(pid: 12345, cpuPercent: 78.5)
        #expect(process.id == 12345)
    }

    // MARK: - ProcessMonitor Tests

    @Test("ProcessMonitor initialization")
    func testProcessMonitorInit() {
        let monitor = ProcessMonitor()
        #expect(monitor != nil)
    }

    @Test("Get claude processes returns array")
    func testGetClaudeProcesses() async {
        let monitor = ProcessMonitor()
        let processes = await monitor.getClaudeProcesses()

        // Should return an array (may be empty if no claude processes running)
        #expect(processes is [ClaudeProcess])
    }

    @Test("Kill non-existent process returns false")
    func testKillNonExistentProcess() async {
        let monitor = ProcessMonitor()
        // Use an invalid PID (999999 is unlikely to exist)
        let result = await monitor.killProcess(pid: 999999)

        // Should return false for non-existent process
        #expect(!result)
    }
}
