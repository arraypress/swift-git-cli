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
    ///
    /// Fails (returns `false`) when `file` is not located under `root`.
    @discardableResult
    static func stage(_ file: URL, repoRoot root: URL) -> Bool {
        guard let rel = relativePathIfUnderRoot(file, root: root) else { return false }
        return run(["add", "--", rel], in: root) != nil
    }

    /// Unstages `file` (`git restore --staged`). Returns `true` on success.
    ///
    /// Fails (returns `false`) when `file` is not located under `root`.
    ///
    /// - Note: Requires an existing `HEAD` (a repository with at least one commit).
    @discardableResult
    static func unstage(_ file: URL, repoRoot root: URL) -> Bool {
        guard let rel = relativePathIfUnderRoot(file, root: root) else { return false }
        return run(["restore", "--staged", "--", rel], in: root) != nil
    }

    /// Reverts `file` to `HEAD` (tracked) or deletes it (untracked). **Destructive.**
    ///
    /// Fails (returns `false`) when a tracked `file` is not located under `root` —
    /// never falls back to a bare-filename pathspec that could clobber an
    /// unrelated same-named file at the repository root.
    ///
    /// - Parameter kind: The file's change kind. `.untracked` files are removed
    ///   from disk; all others are checked out from `HEAD`, discarding local edits.
    /// - Returns: `true` on success.
    @discardableResult
    static func discard(_ file: URL, kind: GitChangeKind, repoRoot root: URL) -> Bool {
        if kind == .untracked { return (try? FileManager.default.removeItem(at: file)) != nil }
        guard let rel = relativePathIfUnderRoot(file, root: root) else { return false }
        return run(["checkout", "HEAD", "--", rel], in: root) != nil
    }
}
