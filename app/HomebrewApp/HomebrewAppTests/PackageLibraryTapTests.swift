import Foundation
import SwiftData
import Testing
@testable import HomebrewApp

struct PackageLibraryTapTests {
    @Test @MainActor func addsAndRemovesTapWhileRefreshingSearchableFormulae() async throws {
        let service = RecordingHomebrewService()
        let library = PackageLibrary(service: service)
        library.disablesTapTrustChecks = true

        let didAdd = await library.addTap(named: "darrylmorley/whatcable")

        #expect(didAdd)
        #expect(library.taps.map(\.name) == ["darrylmorley/whatcable"])
        #expect(library.tappedFormulae.map(\.fullName) == ["darrylmorley/whatcable/whatcable"])
        let tap = try #require(library.taps.first)

        let didRemove = await library.removeTap(tap)

        #expect(didRemove)
        #expect(library.taps.isEmpty)
        #expect(library.tappedFormulae.isEmpty)
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

    @Test @MainActor func doesNotReinstallInstalledTappedFormula() async throws {
        let service = RecordingHomebrewService()
        let library = PackageLibrary(service: service)
        let context = try makeModelContext()
        library.packages = [
            InstalledPackageDTO(
                name: "whatcable",
                kind: .formula,
                summary: "Find the cable for a device",
                homepage: nil,
                installedVersions: [
                    InstalledVersionDTO(version: "1.0.0", isActive: true, installedOn: nil)
                ],
                installedOn: Date(timeIntervalSince1970: 0)
            )
        ]

        await library.installFormula(named: "darrylmorley/whatcable/whatcable", context: context)

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
