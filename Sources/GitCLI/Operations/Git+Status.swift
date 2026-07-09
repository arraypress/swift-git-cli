//
//  Git+Status.swift
//  SwiftGitCLI
//
//  Working-tree status of changed files.
//
//  Created by David Sherlock on 7/9/26.
//

import Foundation

public extension Git {

    /// Working-tree changes versus `HEAD`, one entry per changed file.
    ///
    /// Parses `git status --porcelain=v1`. For renames, `path` is the new path.
    ///
    /// - Parameter root: The repository root (see ``repoRoot(for:)``).
    /// - Returns: `(path, kind)` pairs, where `path` is repository-relative.
    static func status(repoRoot root: URL) -> [(path: String, kind: GitChangeKind)] {
        guard let out = run(["status", "--porcelain=v1"], in: root) else { return [] }
        var result: [(String, GitChangeKind)] = []
        for raw in out.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = String(raw)
            guard line.count >= 4 else { continue }
            let code = String(line.prefix(2))
            var path = String(line.dropFirst(3))
            if let arrow = path.range(of: " -> ") { path = String(path[arrow.upperBound...]) }  // renames
            let kind: GitChangeKind
            if code.contains("?") { kind = .untracked }
            else if code.contains("A") { kind = .added }
            else if code.contains("D") { kind = .deleted }
            else if code.contains("R") { kind = .renamed }
            else { kind = .modified }
            result.append((path, kind))
        }
        return result
    }
}
