import Foundation

public struct SessionParser {
    private let projectsPath: String

    public init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.projectsPath = "\(home)/.claude/projects"
    }

    /// Testable initializer with custom projects path
    public init(projectsPath: String) {
        self.projectsPath = projectsPath
    }

    public func findActiveSession() -> TaskInfo? {
        let fileManager = FileManager.default

        // Find most recently modified .jsonl file across all project directories
        guard let projectDirs = try? fileManager.contentsOfDirectory(atPath: projectsPath) else {
            return nil
        }

        var mostRecentFile: (path: String, date: Date)?

        for dir in projectDirs {
            let dirPath = "\(projectsPath)/\(dir)"
            guard let files = try? fileManager.contentsOfDirectory(atPath: dirPath) else { continue }

            for file in files where file.hasSuffix(".jsonl") {
                let filePath = "\(dirPath)/\(file)"
                guard let attrs = try? fileManager.attributesOfItem(atPath: filePath),
                      let modDate = attrs[.modificationDate] as? Date else { continue }

                // Only consider files modified in the last 30 seconds (active session)
                if Date().timeIntervalSince(modDate) < 30 {
                    if mostRecentFile == nil || modDate > mostRecentFile!.date {
                        mostRecentFile = (filePath, modDate)
                    }
                }
            }
        }

        guard let activeFile = mostRecentFile else { return nil }

        return parseSession(at: activeFile.path)
    }

    private func parseSession(at path: String) -> TaskInfo? {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        let lines = content.components(separatedBy: "\n")
        var latestUserPrompt: String?
        var project: String = "Unknown"
        var sessionSlug: String = ""

        for line in lines where !line.isEmpty {
            guard let jsonData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                continue
            }

            // Extract project from cwd
            if let cwd = json["cwd"] as? String {
                project = URL(fileURLWithPath: cwd).lastPathComponent
            }

            // Extract session slug
            if let slug = json["slug"] as? String {
                sessionSlug = slug
            }

            // Look for user messages with text content
            if json["type"] as? String == "user",
               let message = json["message"] as? [String: Any],
               let content = message["content"] {

                // Handle string content (user prompt)
                if let text = content as? String,
                   !text.isEmpty,
                   !text.hasPrefix("["),  // Skip interrupts
                   !text.hasPrefix("{") { // Skip JSON
                    latestUserPrompt = text
                }

                // Handle array content
                if let contentArray = content as? [[String: Any]] {
                    for item in contentArray {
                        if item["type"] as? String == "text",
                           let text = item["text"] as? String,
                           !text.isEmpty,
                           !text.hasPrefix("[") {
                            latestUserPrompt = text
                        }
                    }
                }
            }
        }

        guard let prompt = latestUserPrompt else { return nil }

        return TaskInfo(
            prompt: prompt,
            project: project,
            sessionSlug: sessionSlug
        )
    }
}
