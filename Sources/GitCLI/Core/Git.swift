//
//  Git.swift
//  SwiftGitCLI
//
//  The `Git` namespace and its low-level process/path primitives.
//
//  Created by David Sherlock on 7/9/26.
//

import Foundation

/// A thin wrapper over the `git` command-line tool.
///
/// `Git` is a namespace (a caseless `enum`) — you never instantiate it; call the
/// static methods directly:
///
/// ```swift
/// import GitCLI
///
/// guard let root = Git.repoRoot(for: someFileURL) else { return }
/// for change in Git.status(repoRoot: root) {
///     print(change.path, change.kind)
/// }
/// ```
///
/// Every call shells out to ``executable`` synchronously and is cheap. When
/// scanning a whole repository, run these off the main queue.
///
/// The operations are grouped across the package:
/// - Status: ``status(repoRoot:)``
/// - Diff: ``lineChanges(for:repoRoot:)``, ``removedLines(for:repoRoot:)``
/// - Blame: ``blame(for:line:repoRoot:)``
/// - Actions: ``stage(_:repoRoot:)``, ``unstage(_:repoRoot:)``, ``discard(_:kind:repoRoot:)``
///
/// - Note: This wraps the `git` executable rather than linking libgit2, so a
///   working `git` must be installed at ``executable``.
public enum Git {

    /// Absolute path to the `git` executable used for every invocation.
    ///
    /// Defaults to the system git at `/usr/bin/git` (the Command Line Tools shim
    /// on macOS). Point it elsewhere before making calls to use a different git.
    public static var executable = "/usr/bin/git"

    /// Runs `git <args>` in `dir` and returns standard output.
    ///
    /// - Parameters:
    ///   - args: Arguments passed to `git`, e.g. `["status", "--porcelain=v1"]`.
    ///   - dir: Working directory the command runs in.
    /// - Returns: The command's standard output decoded as UTF-8, or `nil` if the
    ///   process failed to launch or exited with a non-zero status.
    public static func run(_ args: [String], in dir: URL) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: executable)
        p.arguments = args
        p.currentDirectoryURL = dir
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        do { try p.run() } catch { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// The repository root containing `dir`, or `nil` if `dir` is not inside a git repo.
    ///
    /// - Parameter dir: A file or directory URL. If a file is passed, its parent
    ///   directory is searched.
    public static func repoRoot(for dir: URL) -> URL? {
        let base = dir.hasDirectoryPath ? dir : dir.deletingLastPathComponent()
        guard let out = run(["rev-parse", "--show-toplevel"], in: base)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !out.isEmpty else { return nil }
        return URL(fileURLWithPath: out)
    }

    /// The path of `file` relative to the repository `root`.
    ///
    /// Falls back to the file's last path component when `file` is not located
    /// under `root`.
    public static func relativePath(_ file: URL, root: URL) -> String {
        let f = file.standardizedFileURL.path, r = root.standardizedFileURL.path
        return f.hasPrefix(r + "/") ? String(f.dropFirst(r.count + 1)) : file.lastPathComponent
    }
}
