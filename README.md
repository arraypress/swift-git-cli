# Swift Git CLI

A thin, synchronous Swift wrapper over the `git` command-line tool — repository status, per-line diff markers, phantom removed-line data for inline diffs, blame, and staging actions. Pure Foundation, zero dependencies, no libgit2.

## Features

- 📋 **Working-tree status** — `Git.status(repoRoot:)` returns one `(path, kind)` per changed file, parsed from `git status --porcelain=v1` (added / modified / deleted / untracked / renamed)
- 📏 **Per-line gutter markers** — `Git.lineChanges(for:repoRoot:)` maps each 1-based line to a `GitChangeKind` for editor change bars
- 👻 **Inline-diff phantom rows** — `Git.removedLines(for:repoRoot:)` returns deleted lines keyed by the surviving line they belong above, for Cursor-style inline diffs
- 🧾 **Fast single-line blame** — `Git.blame(for:line:repoRoot:)` returns author, a short relative age, and the commit summary
- ✅ **Staging actions** — `stage`, `unstage`, and a destructive `discard` (revert-to-HEAD or delete-untracked)
- 🧭 **Repo discovery** — `Git.repoRoot(for:)` and repo-relative path resolution
- 🪶 **Zero dependencies** — Foundation only; shells out to the system `git`
- 🧪 **Fully tested** — integration tests against throwaway repos plus direct unit tests of the diff-hunk and relative-time parsers

## Requirements

- macOS 10.15+
- Swift 5.9+
- A working `git` on disk (defaults to `/usr/bin/git`; override via `Git.executable`)

> **Platform note:** this wraps the `git` binary via `Process`, so it is macOS-only (not iOS/tvOS/watchOS).

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-git-cli.git", from: "1.0.0")
]
```

## Usage

```swift
import GitCLI

// Locate the repository containing a file.
guard let root = Git.repoRoot(for: someFileURL) else { return }

// What changed?
for change in Git.status(repoRoot: root) {
    print(change.kind, change.path)   // e.g. modified  Sources/App/main.swift
}

// Per-line change bars for the gutter.
let marks = Git.lineChanges(for: fileURL, repoRoot: root)   // [Int: GitChangeKind]

// Removed lines to ghost inline, keyed by the new-file line they sit above.
let removed = Git.removedLines(for: fileURL, repoRoot: root)   // [Int: [String]]

// Who last touched line 42?
if let blame = Git.blame(for: fileURL, line: 42, repoRoot: root) {
    print("\(blame.author) · \(blame.timeAgo) · \(blame.summary)")
}

// Staging actions.
Git.stage(fileURL, repoRoot: root)
Git.unstage(fileURL, repoRoot: root)
Git.discard(fileURL, kind: .modified, repoRoot: root)   // destructive
```

### Using a non-default git

```swift
Git.executable = "/opt/homebrew/bin/git"
```

## Notes

- All calls are **synchronous** and cheap. When scanning a whole repository, dispatch them off the main queue.
- `discard` is **destructive**: `.untracked` files are removed from disk; all other kinds are checked out from `HEAD`, discarding local edits.
- Actions like `unstage` (`git restore --staged`) require an existing `HEAD` — i.e. a repository with at least one commit.

## License

MIT
