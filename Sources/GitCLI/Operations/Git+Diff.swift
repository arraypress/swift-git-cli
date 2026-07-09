//
//  Git+Diff.swift
//  SwiftGitCLI
//
//  Line-level diff parsing: gutter markers and phantom removed rows.
//
//  Created by David Sherlock on 7/9/26.
//

import Foundation

public extension Git {

    /// Per-line change kind for one file versus `HEAD`, for editor gutter markers.
    ///
    /// Parses `git diff --unified=0`. Added and modified lines map to their
    /// 1-based working-copy line number; a pure deletion marks the surviving line
    /// just below the removal.
    ///
    /// - Returns: A map from 1-based line number to ``GitChangeKind``.
    static func lineChanges(for file: URL, repoRoot root: URL) -> [Int: GitChangeKind] {
        let rel = relativePath(file, root: root)
        guard let diff = run(["diff", "--unified=0", "--no-color", "HEAD", "--", rel], in: root) else { return [:] }
        var marks: [Int: GitChangeKind] = [:]
        for line in diff.split(separator: "\n", omittingEmptySubsequences: false) where line.hasPrefix("@@") {
            // @@ -oldStart[,oldCount] +newStart[,newCount] @@
            let parts = line.split(separator: " ")
            guard parts.count >= 3 else { continue }
            let old = parts[1], new = parts[2]   // "-a,b", "+c,d"
            let oldCount = counts(old).1
            let (newStart, newCount) = counts(new)
            if newCount == 0 {
                marks[max(1, newStart)] = .deleted            // pure deletion
            } else {
                let kind: GitChangeKind = oldCount == 0 ? .added : .modified
                for l in newStart..<(newStart + newCount) { marks[l] = kind }
            }
        }
        return marks
    }

    /// Removed (old) lines to ghost inline as phantom rows, for a Cursor-style
    /// inline diff.
    ///
    /// Parses `git diff --unified=0`. Removed lines are keyed by the 1-based
    /// new-file line they should render *above* (for a pure deletion, the line
    /// just below where the content used to be).
    ///
    /// - Returns: A map from 1-based new-file line number to the removed lines'
    ///   text, in order.
    static func removedLines(for file: URL, repoRoot root: URL) -> [Int: [String]] {
        let rel = relativePath(file, root: root)
        guard let diff = run(["diff", "--unified=0", "--no-color", "HEAD", "--", rel], in: root) else { return [:] }
        var result: [Int: [String]] = [:]
        var pending: [String] = []
        var anchor = 1
        var inHunk = false   // real `---`/`+++` file headers only precede the first @@
        func flush() {
            if !pending.isEmpty { result[anchor, default: []].append(contentsOf: pending); pending = [] }
        }
        for raw in diff.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            if line.hasPrefix("@@") {
                flush()
                inHunk = true
                let parts = line.split(separator: " ")   // @@ -oldS,oldC +newS,newC @@
                guard parts.count >= 3 else { continue }
                let (newStart, newCount) = counts(parts[2])
                anchor = newCount > 0 ? newStart : max(1, newStart + 1)   // above the first new line, or after a pure deletion
            } else if inHunk, line.hasPrefix("-") {
                pending.append(String(line.dropFirst()))   // removed content (even if it starts with "--")
            }
        }
        flush()
        return result
    }
}
