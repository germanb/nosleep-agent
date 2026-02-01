import Testing
@testable import NoSleepAgentLib
import Foundation

@Suite("ProcessMonitor Tests")
struct ProcessMonitorTests {

    // MARK: - Parse Tests

    @Test("Parses valid ps output with claude processes")
    func testParsesClaudeProcesses() {
        let output = """
        USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        user     12345  15.2  1.0 123456 12345 ??       S    10:00   0:01 /usr/bin/claude
        user     67890  25.5  2.0 234567 23456 ??       S    10:01   0:02 node /path/to/claude-code
        """

        let monitor = ProcessMonitor(selfPID: 99999)
        let processes = monitor.parseProcesses(from: output)

        #expect(processes.count == 2)
        #expect(processes[0].pid == 12345)
        #expect(processes[0].cpuPercent == 15.2)
        #expect(processes[1].pid == 67890)
        #expect(processes[1].cpuPercent == 25.5)
    }

    @Test("Returns empty array for empty output")
    func testEmptyOutput() {
        let monitor = ProcessMonitor(selfPID: 99999)
        let processes = monitor.parseProcesses(from: "")

        #expect(processes.isEmpty)
    }

    @Test("Returns empty array when no claude processes")
    func testNoClaudeProcesses() {
        let output = """
        USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        user     12345  15.2  1.0 123456 12345 ??       S    10:00   0:01 /usr/bin/node
        user     67890  25.5  2.0 234567 23456 ??       S    10:01   0:02 /usr/bin/python
        """

        let monitor = ProcessMonitor(selfPID: 99999)
        let processes = monitor.parseProcesses(from: output)

        #expect(processes.isEmpty)
    }

    @Test("Excludes self PID from results")
    func testExcludesSelfPID() {
        let selfPID: Int32 = 12345
        let output = """
        USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        user     12345  15.2  1.0 123456 12345 ??       S    10:00   0:01 /usr/bin/claude
        user     67890  25.5  2.0 234567 23456 ??       S    10:01   0:02 node /path/to/claude-code
        """

        let monitor = ProcessMonitor(selfPID: selfPID)
        let processes = monitor.parseProcesses(from: output)

        #expect(processes.count == 1)
        #expect(processes[0].pid == 67890)
    }

    @Test("Handles malformed lines gracefully")
    func testMalformedLines() {
        let output = """
        USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        invalid line without enough columns claude
        user     abc   15.2  1.0 123456 12345 ??       S    10:00   0:01 /usr/bin/claude
        user     12345  xyz  1.0 123456 12345 ??       S    10:00   0:01 /usr/bin/claude
        user     67890  25.5  2.0 234567 23456 ??       S    10:01   0:02 node /path/to/claude-code
        """

        let monitor = ProcessMonitor(selfPID: 99999)
        let processes = monitor.parseProcesses(from: output)

        #expect(processes.count == 1)
        #expect(processes[0].pid == 67890)
    }

    @Test("Case insensitive matching for claude")
    func testCaseInsensitiveMatching() {
        let output = """
        USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        user     11111  10.0  1.0 123456 12345 ??       S    10:00   0:01 /usr/bin/CLAUDE
        user     22222  20.0  1.0 123456 12345 ??       S    10:00   0:01 /usr/bin/Claude
        user     33333  30.0  1.0 123456 12345 ??       S    10:00   0:01 /usr/bin/claude
        """

        let monitor = ProcessMonitor(selfPID: 99999)
        let processes = monitor.parseProcesses(from: output)

        #expect(processes.count == 3)
    }

    @Test("Excludes Claude Desktop app")
    func testExcludesDesktopApp() {
        let output = """
        USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        user     12345  50.0  1.0 123456 12345 ??       S    10:00   0:01 claude --dangerously-skip-permissions
        user     67890  10.0  1.0 123456 12345 ??       S    10:00   0:01 /Applications/Claude.app/Contents/MacOS/Claude
        """

        let monitor = ProcessMonitor(selfPID: 99999)
        let processes = monitor.parseProcesses(from: output)

        #expect(processes.count == 1)
        #expect(processes[0].pid == 12345)
    }

    @Test("Excludes Claude Helper processes")
    func testExcludesHelpers() {
        let output = """
        USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        user     11111  10.0  1.0 123456 12345 ??       S    10:00   0:01 claude --dangerously-skip-permissions
        user     22222   5.0  1.0 123456 12345 ??       S    10:00   0:01 /Applications/Claude.app/Contents/Frameworks/Claude Helper (Renderer)
        user     33333   2.0  1.0 123456 12345 ??       S    10:00   0:01 /Applications/Claude.app/Contents/Frameworks/Claude Helper (GPU)
        """

        let monitor = ProcessMonitor(selfPID: 99999)
        let processes = monitor.parseProcesses(from: output)

        #expect(processes.count == 1)
        #expect(processes[0].pid == 11111)
    }

    @Test("Excludes chrome-native-host")
    func testExcludesNativeHost() {
        let output = """
        USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        user     11111  10.0  1.0 123456 12345 ??       S    10:00   0:01 claude --dangerously-skip-permissions
        user     22222   0.0  1.0 123456 12345 ??       S    10:00   0:01 /Applications/Claude.app/Contents/Helpers/chrome-native-host
        """

        let monitor = ProcessMonitor(selfPID: 99999)
        let processes = monitor.parseProcesses(from: output)

        #expect(processes.count == 1)
        #expect(processes[0].pid == 11111)
    }

    @Test("Excludes shell wrappers with claude in paths")
    func testExcludesShellWrappers() {
        let output = """
        USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
        user     11111  10.0  1.0 123456 12345 ??       S    10:00   0:01 claude --dangerously-skip-permissions
        user     22222   0.0  0.0 123456 12345 ??       Ss   10:00   0:00 /bin/zsh -c -l source /Users/user/.claude/shell-snapshots/snapshot.sh
        user     33333   0.0  0.0 123456 12345 ??       S    10:00   0:01 find /Users/user -type d -name .claude*
        """

        let monitor = ProcessMonitor(selfPID: 99999)
        let processes = monitor.parseProcesses(from: output)

        #expect(processes.count == 1)
        #expect(processes[0].pid == 11111)
    }

    // MARK: - Kill Tests

    @Test("Kill returns false for non-existent PID")
    func testKillNonExistentPID() {
        let monitor = ProcessMonitor(selfPID: 99999)
        // Use a PID that's very unlikely to exist
        let result = monitor.killProcess(999999)

        #expect(result == false)
    }
}
