//
//  Git+Actions.swift
//  SwiftGitCLI
//
//  Mutating actions: stage, unstage, and discard.
//
//  Created by David Sherlock on 7/9/26.
//

import Foundation

public extension Git {

    /// Stages `file` (`git add`). Returns `true` on success.
    @discardableResult
    static func stage(_ file: URL, repoRoot root: URL) -> Bool {
        run(["add", "--", relativePath(file, root: root)], in: root) != nil
    }

    /// Unstages `file` (`git restore --staged`). Returns `true` on success.
    ///
    /// - Note: Requires an existing `HEAD` (a repository with at least one commit).
    @discardableResult
    static func unstage(_ file: URL, repoRoot root: URL) -> Bool {
        run(["restore", "--staged", "--", relativePath(file, root: root)], in: root) != nil
    }

    /// Reverts `file` to `HEAD` (tracked) or deletes it (untracked). **Destructive.**
    ///
    /// - Parameter kind: The file's change kind. `.untracked` files are removed
    ///   from disk; all others are checked out from `HEAD`, discarding local edits.
    /// - Returns: `true` on success.
    @discardableResult
    static func discard(_ file: URL, kind: GitChangeKind, repoRoot root: URL) -> Bool {
        if kind == .untracked { return (try? FileManager.default.removeItem(at: file)) != nil }
        return run(["checkout", "HEAD", "--", relativePath(file, root: root)], in: root) != nil
    }
}
