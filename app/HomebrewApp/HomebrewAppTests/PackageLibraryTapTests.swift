import Foundation
import SwiftData
import Testing
@testable import HomebrewApp

struct PackageLibraryTapTests {
    @Test @MainActor func addsAndRemovesTapWhileRefreshingSearchablePackages() async throws {
        let service = RecordingHomebrewService()
        let library = PackageLibrary(service: service)
        library.disablesTapTrustChecks = true

        let didAdd = await library.addTap(named: "darrylmorley/whatcable")

        #expect(didAdd)
        #expect(library.taps.map(\.name) == ["darrylmorley/whatcable"])
        #expect(
            library.tappedCatalogItems.map(\.fullName) == [
                "darrylmorley/whatcable/whatcable",
                "darrylmorley/whatcable/whatcable-cli"
            ]
        )
        #expect(library.tappedCatalogItems.map(\.kind) == [.cask, .formula])
        let tap = try #require(library.taps.first)

        let didRemove = await library.removeTap(tap)

        #expect(didRemove)
        #expect(library.taps.isEmpty)
        #expect(library.tappedCatalogItems.isEmpty)
        #expect(
            service.recordedOperations == [
                .addTap("darrylmorley/whatcable"),
                .installedTaps,
                .removeTap("darrylmorley/whatcable"),
                .installedTaps
            ]
        )
        #expect(service.recordedTrustCheckSettings == [true, true, true, true])
    }

    @Test @MainActor func rejectsInvalidTapNameWithoutCallingHomebrew() async {
        let service = RecordingHomebrewService()
        let library = PackageLibrary(service: service)

        let didAdd = await library.addTap(named: "not-a-tap")

        #expect(didAdd == false)
        #expect(library.tapErrorMessage != nil)
        #expect(service.recordedOperations.isEmpty)
    }

    @Test @MainActor func installsQualifiedTappedCaskAndRefreshesPackages() async throws {
        let installedCask = InstalledPackageDTO(
            name: "whatcable",
            kind: .cask,
            summary: "USB-C cable information",
            homepage: nil,
            installedVersions: [
                InstalledVersionDTO(version: "1.0.0", isActive: true, installedOn: nil)
            ],
            installedOn: Date(timeIntervalSince1970: 0)
        )
        let service = RecordingHomebrewService(installedPackagesResult: [installedCask])
        let library = PackageLibrary(service: service)
        let context = try makeModelContext()

        await library.installPackage(
            named: "darrylmorley/whatcable/whatcable",
            kind: .cask,
            context: context
        )

        #expect(
            service.recordedOperations == [
                .installPackage("darrylmorley/whatcable/whatcable", .cask),
                .installedPackages
            ]
        )
        #expect(library.isPackageInstalled(named: "whatcable", kind: .cask))
        #expect(
            library.logs.contains {
                $0.detail == "brew install --cask darrylmorley/whatcable/whatcable"
            }
        )
        #expect(library.errorMessage == nil)
        #expect(library.isLoading == false)
    }

    @Test @MainActor func doesNotReinstallInstalledTappedCask() async throws {
        let service = RecordingHomebrewService()
        let library = PackageLibrary(service: service)
        let context = try makeModelContext()
        library.packages = [
            InstalledPackageDTO(
                name: "whatcable",
                kind: .cask,
                summary: "Find the cable for a device",
                homepage: nil,
                installedVersions: [
                    InstalledVersionDTO(version: "1.0.0", isActive: true, installedOn: nil)
                ],
                installedOn: Date(timeIntervalSince1970: 0)
            )
        ]

        await library.installPackage(
            named: "darrylmorley/whatcable/whatcable",
            kind: .cask,
            context: context
        )

        #expect(service.recordedOperations.isEmpty)
    }

    @MainActor
    private func makeModelContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: BrewPackage.self,
            BrewVersion.self,
            configurations: configuration
        )
        return ModelContext(container)
    }
}
