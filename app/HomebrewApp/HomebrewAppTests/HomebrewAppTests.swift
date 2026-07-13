import Foundation
import Testing
@testable import HomebrewApp

struct HomebrewAppTests {
    @Test @MainActor func exportJSONContainsPackages() async throws {
        let library = PackageLibrary(service: MockHomebrewService())
        library.packages = [
            InstalledPackageDTO(
                name: "git",
                kind: .formula,
                summary: "Distributed revision control system",
                homepage: URL(string: "https://git-scm.com"),
                installedVersions: [InstalledVersionDTO(version: "2.50.1", isActive: true, installedOn: nil)],
                installedOn: Date(timeIntervalSince1970: 0)
            )
        ]

        library.prepareExport()

        let data = try #require(library.exportData)
        let payload = try JSONDecoder().decode(PackageExportDocumentPayload.self, from: data)

        #expect(payload.packageManager == "homebrew")
        #expect(payload.packages.map(\.name) == ["git"])
        #expect(payload.packages.first?.installedVersions.first?.version == "2.50.1")
    }
}
