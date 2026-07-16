import Foundation
import Testing
@testable import HomebrewApp

struct HomebrewPackageDiskUsageTests {
    @Test func measuresRegularFilesRecursively() async throws {
        let packageDirectory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let nestedDirectory = packageDirectory
            .appending(path: "nested", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: nestedDirectory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: packageDirectory) }

        try Data(repeating: 0, count: 1_024)
            .write(to: packageDirectory.appending(path: "first.bin"))
        try Data(repeating: 0, count: 2_048)
            .write(to: nestedDirectory.appending(path: "second.bin"))

        let packageID = "homebrew:formula:test"
        let sizes = await HomebrewPackageDiskUsage.sizes(
            for: [packageID: packageDirectory]
        )

        #expect(sizes[packageID] == 3_072)
    }
}
