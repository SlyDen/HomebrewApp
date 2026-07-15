import Foundation
import Testing
@testable import HomebrewApp

struct HomebrewAppTests {
    @Test @MainActor func filtersPackagesWithMultipleInstalledVersions() async throws {
        let library = PackageLibrary(service: MockHomebrewService())
        library.packages = [
            InstalledPackageDTO(
                name: "git",
                kind: .formula,
                summary: "Distributed revision control system",
                homepage: nil,
                installedVersions: [InstalledVersionDTO(version: "2.50.1", isActive: true, installedOn: nil)],
                installedOn: Date(timeIntervalSince1970: 0)
            ),
            InstalledPackageDTO(
                name: "node",
                kind: .formula,
                summary: "Platform built on V8",
                homepage: nil,
                installedVersions: [
                    InstalledVersionDTO(version: "24.4.1", isActive: true, installedOn: nil),
                    InstalledVersionDTO(version: "22.17.1", isActive: false, installedOn: nil)
                ],
                installedOn: Date(timeIntervalSince1970: 0)
            ),
            InstalledPackageDTO(
                name: "visual-studio-code",
                kind: .cask,
                summary: "Code editor",
                homepage: nil,
                installedVersions: [
                    InstalledVersionDTO(version: "1.102.0", isActive: true, installedOn: nil),
                    InstalledVersionDTO(version: "1.101.2", isActive: false, installedOn: nil)
                ],
                installedOn: Date(timeIntervalSince1970: 0)
            )
        ]

        library.showsOnlyMultipleVersions = true

        #expect(library.filteredPackages.map(\.name) == ["node", "visual-studio-code"])

        library.selectedKind = .formula

        #expect(library.filteredPackages.map(\.name) == ["node"])
    }

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
