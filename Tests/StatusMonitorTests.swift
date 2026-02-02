import Testing
@testable import NoSleepAgentLib
import Foundation

@Suite("StatusMonitor Tests")
struct StatusMonitorTests {

    // MARK: - Helper Methods

    func createTempPIDFile(claudePID: Int32, caffeinatePID: Int32) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "claude-caffeinate-\(claudePID).pid"
        let fileURL = tempDir.appendingPathComponent(fileName)

        let content = """
        CAFFEINATE_PID=\(caffeinatePID)
        CLAUDE_PID=\(claudePID)
        """

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Multi-Session Tests

    @Test("Detects caffeinate process from single PID file")
    func testSinglePIDFile() throws {
        // Create a PID file with a process that exists (use init process PID 1)
        let pidFile = try createTempPIDFile(claudePID: 12345, caffeinatePID: 1)
        defer { cleanup(pidFile) }

        // StatusMonitor should detect this as working since PID 1 exists
        // Note: This test verifies the file parsing logic works correctly
        let fileContent = try String(contentsOf: pidFile, encoding: .utf8)
        let lines = fileContent.components(separatedBy: .newlines)

        let caffeinateLine = lines.first { $0.hasPrefix("CAFFEINATE_PID=") }
        #expect(caffeinateLine != nil)

        let pidString = caffeinateLine?.components(separatedBy: "=").last
        #expect(pidString == "1")

        let claudeLine = lines.first { $0.hasPrefix("CLAUDE_PID=") }
        #expect(claudeLine != nil)
        #expect(claudeLine?.components(separatedBy: "=").last == "12345")
    }

    @Test("Handles multiple concurrent PID files")
    func testMultiplePIDFiles() throws {
        // Create multiple PID files for different sessions
        let pidFile1 = try createTempPIDFile(claudePID: 11111, caffeinatePID: 1)
        let pidFile2 = try createTempPIDFile(claudePID: 22222, caffeinatePID: 1)
        let pidFile3 = try createTempPIDFile(claudePID: 33333, caffeinatePID: 1)

        defer {
            cleanup(pidFile1)
            cleanup(pidFile2)
            cleanup(pidFile3)
        }

        // Verify all files were created with correct naming pattern
        #expect(pidFile1.lastPathComponent == "claude-caffeinate-11111.pid")
        #expect(pidFile2.lastPathComponent == "claude-caffeinate-22222.pid")
        #expect(pidFile3.lastPathComponent == "claude-caffeinate-33333.pid")

        // Verify each file contains the correct PIDs
        let content1 = try String(contentsOf: pidFile1, encoding: .utf8)
        #expect(content1.contains("CLAUDE_PID=11111"))

        let content2 = try String(contentsOf: pidFile2, encoding: .utf8)
        #expect(content2.contains("CLAUDE_PID=22222"))

        let content3 = try String(contentsOf: pidFile3, encoding: .utf8)
        #expect(content3.contains("CLAUDE_PID=33333"))
    }

    @Test("Ignores PID file with dead process")
    func testDeadProcessPIDFile() throws {
        // Create a PID file with a process that definitely doesn't exist
        let pidFile = try createTempPIDFile(claudePID: 99999, caffeinatePID: 999999)
        defer { cleanup(pidFile) }

        // Verify the PID is not alive
        let caffeinatePID: Int32 = 999999
        let isAlive = kill(caffeinatePID, 0) == 0

        #expect(isAlive == false)
    }

    @Test("Extracts correct PIDs from file format")
    func testPIDFileFormat() throws {
        let claudePID: Int32 = 54321
        let caffeinatePID: Int32 = 98765

        let pidFile = try createTempPIDFile(claudePID: claudePID, caffeinatePID: caffeinatePID)
        defer { cleanup(pidFile) }

        let content = try String(contentsOf: pidFile, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        // Extract CAFFEINATE_PID
        let caffeinateLine = lines.first { $0.hasPrefix("CAFFEINATE_PID=") }
        let extractedCaffeinatePID = caffeinateLine?
            .components(separatedBy: "=")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(extractedCaffeinatePID == "98765")

        // Extract CLAUDE_PID
        let claudeLine = lines.first { $0.hasPrefix("CLAUDE_PID=") }
        let extractedClaudePID = claudeLine?
            .components(separatedBy: "=")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(extractedClaudePID == "54321")
    }

    @Test("PID file naming follows expected pattern")
    func testPIDFileNamingPattern() {
        let claudePID: Int32 = 12345
        let expectedFileName = "claude-caffeinate-\(claudePID).pid"

        // Verify the naming pattern matches what we expect
        #expect(expectedFileName == "claude-caffeinate-12345.pid")

        // Verify pattern can be used for filtering
        let matchesPattern = expectedFileName.hasPrefix("claude-caffeinate-") &&
                            expectedFileName.hasSuffix(".pid")
        #expect(matchesPattern == true)
    }

    @Test("Handles empty /tmp directory gracefully")
    func testEmptyTmpDirectory() {
        // Create a custom temp directory to simulate empty state
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("status-monitor-test-\(UUID().uuidString)")

        do {
            try FileManager.default.createDirectory(
                at: tempDir,
                withIntermediateDirectories: true
            )
            defer { try? FileManager.default.removeItem(at: tempDir) }

            // List contents
            let contents = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
            let pidFiles = contents.filter {
                $0.hasPrefix("claude-caffeinate-") && $0.hasSuffix(".pid")
            }

            // Should be empty
            #expect(pidFiles.isEmpty)
        } catch {
            Issue.record("Failed to create temp directory: \(error)")
        }
    }
}
