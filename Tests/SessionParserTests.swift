import Testing
@testable import NoSleepAgentLib
import Foundation

@Suite("SessionParser Tests")
struct SessionParserTests {

    // MARK: - Helper Methods

    func createTempProjectsDir() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("session-parser-tests-\(UUID().uuidString)")
            .appendingPathComponent(".claude")
            .appendingPathComponent("projects")

        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )

        return tempDir
    }

    func cleanup(_ url: URL) {
        // Go up to the test root (3 levels: projects -> .claude -> test-uuid)
        let testRoot = url.deletingLastPathComponent().deletingLastPathComponent()
        try? FileManager.default.removeItem(at: testRoot)
    }

    func writeSessionFile(at projectsDir: URL, projectName: String, fileName: String, content: String) throws -> URL {
        let projectDir = projectsDir.appendingPathComponent(projectName)
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)

        let filePath = projectDir.appendingPathComponent(fileName)
        try content.write(to: filePath, atomically: true, encoding: .utf8)

        return filePath
    }

    func makeUserMessageJSON(prompt: String, cwd: String, slug: String) -> String {
        """
        {"type":"user","message":{"content":"\(prompt)"},"cwd":"\(cwd)","slug":"\(slug)"}
        """
    }

    // MARK: - Tests

    @Test("Returns nil when projects directory is empty")
    func testEmptyProjectsDir() throws {
        let projectsDir = try createTempProjectsDir()
        defer { cleanup(projectsDir) }

        let parser = SessionParser(projectsPath: projectsDir.path)
        let result = parser.findActiveSession()

        #expect(result == nil)
    }

    @Test("Returns nil when no recent files exist")
    func testNoRecentFiles() throws {
        let projectsDir = try createTempProjectsDir()
        defer { cleanup(projectsDir) }

        let content = makeUserMessageJSON(prompt: "Test", cwd: "/test/proj", slug: "s1")
        let filePath = try writeSessionFile(at: projectsDir, projectName: "proj", fileName: "session.jsonl", content: content)

        // Set modification date to 1 minute ago (older than 30s threshold)
        let oldDate = Date().addingTimeInterval(-60)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: filePath.path)

        let parser = SessionParser(projectsPath: projectsDir.path)
        let result = parser.findActiveSession()

        #expect(result == nil)
    }

    @Test("Finds active session from recent file")
    func testFindsActiveSession() throws {
        let projectsDir = try createTempProjectsDir()
        defer { cleanup(projectsDir) }

        let content = makeUserMessageJSON(prompt: "Add tests to project", cwd: "/Users/dev/myapp", slug: "abc123")
        _ = try writeSessionFile(at: projectsDir, projectName: "myapp-encoded", fileName: "session.jsonl", content: content)

        let parser = SessionParser(projectsPath: projectsDir.path)
        let result = parser.findActiveSession()

        #expect(result != nil)
        #expect(result?.prompt == "Add tests to project")
        #expect(result?.project == "myapp")
        #expect(result?.sessionSlug == "abc123")
    }

    @Test("Extracts latest user message from multiple messages")
    func testLatestUserMessage() throws {
        let projectsDir = try createTempProjectsDir()
        defer { cleanup(projectsDir) }

        let content = """
        {"type":"user","message":{"content":"First message"},"cwd":"/test/proj","slug":"s1"}
        {"type":"assistant","message":{"content":"Response"}}
        {"type":"user","message":{"content":"Second message"},"cwd":"/test/proj","slug":"s1"}
        """
        _ = try writeSessionFile(at: projectsDir, projectName: "proj", fileName: "session.jsonl", content: content)

        let parser = SessionParser(projectsPath: projectsDir.path)
        let result = parser.findActiveSession()

        #expect(result?.prompt == "Second message")
    }

    @Test("Skips interrupt messages")
    func testSkipsInterrupts() throws {
        let projectsDir = try createTempProjectsDir()
        defer { cleanup(projectsDir) }

        let content = """
        {"type":"user","message":{"content":"Real prompt"},"cwd":"/test/proj","slug":"s1"}
        {"type":"user","message":{"content":"[interrupt]"},"cwd":"/test/proj","slug":"s1"}
        """
        _ = try writeSessionFile(at: projectsDir, projectName: "proj", fileName: "session.jsonl", content: content)

        let parser = SessionParser(projectsPath: projectsDir.path)
        let result = parser.findActiveSession()

        #expect(result?.prompt == "Real prompt")
    }

    @Test("Handles array content format")
    func testArrayContent() throws {
        let projectsDir = try createTempProjectsDir()
        defer { cleanup(projectsDir) }

        let content = """
        {"type":"user","message":{"content":[{"type":"text","text":"Array prompt"}]},"cwd":"/test/proj","slug":"s1"}
        """
        _ = try writeSessionFile(at: projectsDir, projectName: "proj", fileName: "session.jsonl", content: content)

        let parser = SessionParser(projectsPath: projectsDir.path)
        let result = parser.findActiveSession()

        #expect(result?.prompt == "Array prompt")
    }

    @Test("Returns nil for malformed JSON")
    func testMalformedJSON() throws {
        let projectsDir = try createTempProjectsDir()
        defer { cleanup(projectsDir) }

        _ = try writeSessionFile(at: projectsDir, projectName: "proj", fileName: "session.jsonl", content: "{invalid json")

        let parser = SessionParser(projectsPath: projectsDir.path)
        let result = parser.findActiveSession()

        #expect(result == nil)
    }

    @Test("Selects most recently modified file across projects")
    func testSelectsMostRecentFile() throws {
        let projectsDir = try createTempProjectsDir()
        defer { cleanup(projectsDir) }

        // Create older file
        let oldContent = makeUserMessageJSON(prompt: "Old prompt", cwd: "/test/old", slug: "old")
        let oldFile = try writeSessionFile(at: projectsDir, projectName: "old-proj", fileName: "old.jsonl", content: oldContent)

        // Set old file to 20 seconds ago (still within 30s but older)
        let oldDate = Date().addingTimeInterval(-20)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: oldFile.path)

        // Create newer file (just now)
        let newContent = makeUserMessageJSON(prompt: "New prompt", cwd: "/test/new", slug: "new")
        _ = try writeSessionFile(at: projectsDir, projectName: "new-proj", fileName: "new.jsonl", content: newContent)

        let parser = SessionParser(projectsPath: projectsDir.path)
        let result = parser.findActiveSession()

        #expect(result?.prompt == "New prompt")
        #expect(result?.project == "new")
    }
}
