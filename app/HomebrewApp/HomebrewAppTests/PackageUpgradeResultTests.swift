import Foundation
import SwiftData
import Testing
@testable import HomebrewApp

@MainActor
struct PackageUpgradeResultTests {
    @Test func recordsAndFiltersPerPackageBulkUpgradeResults() async throws {
        let library = PackageLibrary(service: PackageUpgradeTestService())
        let context = try makeModelContext()
        library.packages = [package(named: "alpha"), package(named: "beta")]

        await library.upgradeAll(cleanupAfterUpgrade: true, from: context)

        #expect(library.upgradeResults["homebrew:formula:alpha"]?.status == .succeeded)
        #expect(library.upgradeResults["homebrew:formula:beta"]?.status == .failed)
        #expect(
            library.upgradeResults["homebrew:formula:beta"]?.message
                == PackageUpgradeTestError.upgradeFailed.localizedDescription
        )

        library.selectedUpgradeStatus = .succeeded
        #expect(library.filteredPackages.map(\.name) == ["alpha"])

        library.selectedUpgradeStatus = .failed
        #expect(library.filteredPackages.map(\.name) == ["beta"])

        library.clearPackageFilters()
        #expect(library.filteredPackages.map(\.name) == ["alpha", "beta"])
    }

    @Test func assignsNamedErrorToItsPackageInsteadOfTheLatestActivePackage() async throws {
        let service = PackageUpgradeTestService(
            progressMessages: [
                "Upgrading alpha",
                "Upgrading beta",
                "Error: alpha: upgrade failed"
            ]
        )
        let library = PackageLibrary(service: service)
        let context = try makeModelContext()
        library.packages = [package(named: "alpha"), package(named: "beta")]

        await library.upgradeAll(cleanupAfterUpgrade: false, from: context)

        #expect(library.upgradeResults["homebrew:formula:alpha"]?.status == .failed)
        #expect(
            library.upgradeResults["homebrew:formula:alpha"]?.message
                == "Error: alpha: upgrade failed"
        )
        #expect(library.upgradeResults["homebrew:formula:beta"]?.status == .succeeded)
    }

    /// Creates an isolated in-memory SwiftData context.
    private func makeModelContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: BrewPackage.self,
            BrewVersion.self,
            configurations: configuration
        )
        return ModelContext(container)
    }

    /// Creates a deterministic installed formula for result assertions.
    private func package(named name: String) -> InstalledPackageDTO {
        InstalledPackageDTO(
            name: name,
            kind: .formula,
            summary: "Test package",
            homepage: nil,
            installedVersions: [
                InstalledVersionDTO(version: "1.0", isActive: true, installedOn: .distantPast)
            ],
            installedOn: .distantPast
        )
    }
}
