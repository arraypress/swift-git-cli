//
//  Git+Log.swift
//  SwiftGitCLI
//
//  Commit history for the History panel.
//

import Foundation

/// One commit from `git log`.
public struct GitCommit: Equatable, Sendable {
    public let hash: String        // full 40-char SHA
    public let shortHash: String   // abbreviated SHA
    public let author: String
    public let date: String        // YYYY-MM-DD (author date)
    public let subject: String     // first line of the message

    public init(hash: String, shortHash: String, author: String, date: String, subject: String) {
        self.hash = hash; self.shortHash = shortHash; self.author = author
        self.date = date; self.subject = subject
    }
}

public extension Git {

    /// The most recent commits on the current branch, newest first.
    ///
    /// Uses a `%x1f` (unit-separator) delimited pretty-format so commit subjects with any
    /// punctuation parse cleanly. Records are newline-separated.
    ///
    /// - Parameters:
    ///   - root: The repository root (see ``repoRoot(for:)``).
    ///   - limit: Maximum commits to return.
    static func log(repoRoot root: URL, limit: Int = 300) -> [GitCommit] {
        let format = "%H%x1f%h%x1f%an%x1f%ad%x1f%s"
        guard let out = run(["log", "-n", "\(max(1, limit))", "--date=short",
                             "--pretty=format:\(format)"], in: root) else { return [] }
        return out.split(separator: "\n", omittingEmptySubsequences: true).compactMap { line in
            let f = line.components(separatedBy: "\u{1f}")
            guard f.count == 5 else { return nil }
            return GitCommit(hash: f[0], shortHash: f[1], author: f[2], date: f[3], subject: f[4])
        }
    }

    /// The full patch for one commit (`git show`), for the History detail view. `nil` on error.
    static func showCommit(_ hash: String, repoRoot root: URL) -> String? {
        run(["show", "--no-color", "--stat", "--patch", hash], in: root)
    }
}
