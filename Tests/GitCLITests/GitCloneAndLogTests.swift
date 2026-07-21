import XCTest
@testable import GitCLI

final class GitCloneAndLogTests: XCTestCase {
    private var scratch: [URL] = []

    override func tearDownWithError() throws {
        for u in scratch { try? FileManager.default.removeItem(at: u) }
        scratch = []
    }

    private func tempDir(_ prefix: String) throws -> URL {
        let u = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        scratch.append(u)
        return u
    }

    private func seedRepo(_ root: URL, commits: [String]) {
        _ = Git.run(["init", "-q"], in: root)
        _ = Git.run(["config", "user.email", "t@e.com"], in: root)
        _ = Git.run(["config", "user.name", "T"], in: root)
        _ = Git.run(["config", "commit.gpgsign", "false"], in: root)
        for (i, msg) in commits.enumerated() {
            try? "\(i)".write(to: root.appendingPathComponent("f\(i).txt"), atomically: true, encoding: .utf8)
            _ = Git.run(["add", "-A"], in: root)
            _ = Git.run(["commit", "-q", "-m", msg], in: root)
        }
    }

    // MARK: - defaultCloneDirectoryName (pure)

    func testDefaultCloneDirectoryName() {
        XCTAssertEqual(Git.defaultCloneDirectoryName(for: "https://github.com/arraypress/sidewatch.git"), "sidewatch")
        XCTAssertEqual(Git.defaultCloneDirectoryName(for: "https://github.com/owner/Repo"), "Repo")
        XCTAssertEqual(Git.defaultCloneDirectoryName(for: "git@github.com:owner/my-repo.git"), "my-repo")
        XCTAssertEqual(Git.defaultCloneDirectoryName(for: "git@host:repo.git"), "repo")
        XCTAssertEqual(Git.defaultCloneDirectoryName(for: "https://example.com/a/b/c.git/"), "c")
        XCTAssertEqual(Git.defaultCloneDirectoryName(for: ""), "repository")
    }

    // MARK: - log (integration)

    func testLogReturnsCommitsNewestFirst() throws {
        let root = try tempDir("gitlog")
        seedRepo(root, commits: ["first", "second", "third"])
        let commits = Git.log(repoRoot: root, limit: 10)
        XCTAssertEqual(commits.count, 3)
        XCTAssertEqual(commits.map(\.subject), ["third", "second", "first"])   // newest first
        XCTAssertEqual(commits.first?.author, "T")
        XCTAssertEqual(commits.first?.shortHash.count ?? 0 >= 7, true)
        XCTAssertFalse(commits.first?.hash.isEmpty ?? true)
    }

    func testLogRespectsLimit() throws {
        let root = try tempDir("gitloglimit")
        seedRepo(root, commits: ["a", "b", "c", "d"])
        XCTAssertEqual(Git.log(repoRoot: root, limit: 2).count, 2)
    }

    func testShowCommitContainsThePatch() throws {
        let root = try tempDir("gitshow")
        seedRepo(root, commits: ["only"])
        let hash = Git.log(repoRoot: root, limit: 1).first!.hash
        let patch = Git.showCommit(hash, repoRoot: root)
        XCTAssertNotNil(patch)
        XCTAssertTrue(patch!.contains("only"))       // the commit subject
        XCTAssertTrue(patch!.contains("f0.txt"))     // the changed file
    }

    // MARK: - clone (integration, local — no network)

    func testCloneLocalRepoSucceeds() throws {
        let src = try tempDir("clone-src")
        seedRepo(src, commits: ["seed"])
        let parent = try tempDir("clone-dest")

        let result = Git.clone(from: src.path, into: parent, name: "checkout")
        XCTAssertTrue(result.succeeded, "clone error: \(result.error ?? "nil")")
        XCTAssertEqual(result.path?.lastPathComponent, "checkout")
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path!.appendingPathComponent("f0.txt").path,
                                                     isDirectory: &isDir))
        // The clone has the source's history.
        XCTAssertEqual(Git.log(repoRoot: result.path!, limit: 5).map(\.subject), ["seed"])
    }

    func testCloneBadPathReturnsError() throws {
        let parent = try tempDir("clone-bad")
        let result = Git.clone(from: "/nonexistent/does-not-exist.git", into: parent)
        XCTAssertFalse(result.succeeded)
        XCTAssertNotNil(result.error)
    }
}
