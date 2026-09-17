import Foundation

/// Appends unresolved lyrics lookups to disk so real-world song-naming shapes
/// that the parser/search doesn't handle can be collected and reviewed later.
final class NotFoundLogger: @unchecked Sendable {
    static let shared = NotFoundLogger()

    private let logFileURL: URL?
    private let queue = DispatchQueue(label: "com.emrycho.ezlyrics.notfoundlogger")

    init(logFileURL: URL? = nil) {
        if let logFileURL = logFileURL {
            self.logFileURL = logFileURL
        } else if let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = supportDir.appendingPathComponent("ezlyrics")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            self.logFileURL = dir.appendingPathComponent("not_found.log")
        } else {
            self.logFileURL = nil
        }
    }

    /// Logs a track for which no lyrics could be found, using the artist/title
    /// as parsed off the OS "now playing" info (after MediaRemoteWrapper's
    /// cleanup heuristics), so unhandled naming shapes can be inspected later.
    func log(artist: String, title: String, reason: String) {
        guard let logFileURL = logFileURL else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "\(timestamp)\tartist=\"\(artist)\"\ttitle=\"\(title)\"\treason=\"\(reason)\"\n"
        guard let data = line.data(using: .utf8) else { return }

        queue.async {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let handle = try? FileHandle(forWritingTo: logFileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
}
