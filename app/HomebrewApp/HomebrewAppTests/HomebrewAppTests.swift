import Foundation
import SwiftData
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
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(PackageExportDocumentPayload.self, from: data)

        #expect(payload.packageManager == "homebrew")
        #expect(payload.packages.map(\.name) == ["git"])
        #expect(payload.packages.first?.installedVersions.first?.version == "2.50.1")
    }

    @Test @MainActor func upgradeAllRunsCleanupWhenEnabled() async throws {
        let service = RecordingHomebrewService()
        let library = PackageLibrary(service: service)
        let context = try makeModelContext()

        await library.upgradeAll(cleanupAfterUpgrade: true, from: context)

        #expect(service.recordedOperations == [.updateHomebrew, .upgradeAll, .cleanup, .installedPackages])
        #expect(library.errorMessage == nil)
    }

    @Test @MainActor func upgradeAllSkipsCleanupWhenDisabled() async throws {
        let service = RecordingHomebrewService()
        let library = PackageLibrary(service: service)
        let context = try makeModelContext()

        await library.upgradeAll(cleanupAfterUpgrade: false, from: context)

        #expect(service.recordedOperations == [.updateHomebrew, .upgradeAll, .installedPackages])
        #expect(library.logs.contains { $0.title == "Cleanup skipped" })
    }

    @Test @MainActor func upgradeAllDoesNotCleanupOrRefreshAfterUpgradeFailure() async throws {
        let service = RecordingHomebrewService(upgradeError: TestServiceError.upgradeFailed)
        let library = PackageLibrary(service: service)
        let context = try makeModelContext()

        await library.upgradeAll(cleanupAfterUpgrade: true, from: context)

        #expect(service.recordedOperations == [.updateHomebrew, .upgradeAll])
        #expect(library.errorMessage == TestServiceError.upgradeFailed.localizedDescription)
        #expect(library.isLoading == false)
    }

    @Test @MainActor func upgradeAllStopsWhenHomebrewUpdateFails() async throws {
        let service = RecordingHomebrewService(updateError: TestServiceError.updateFailed)
        let library = PackageLibrary(service: service)
        let context = try makeModelContext()

        await library.upgradeAll(cleanupAfterUpgrade: true, from: context)

        #expect(service.recordedOperations == [.updateHomebrew])
        #expect(library.errorMessage == TestServiceError.updateFailed.localizedDescription)
        #expect(library.logs.contains { $0.title == "Homebrew update failed" })
        #expect(library.isLoading == false)
    }

    @Test @MainActor func upgradeAllPassesDisabledTrustChecksPreference() async throws {
        let service = RecordingHomebrewService()
        let library = PackageLibrary(service: service)
        let context = try makeModelContext()
        library.disablesTapTrustChecks = true

        await library.upgradeAll(cleanupAfterUpgrade: true, from: context)

        #expect(service.recordedTrustCheckSettings == [true, true, true, true])
    }

    @Test @MainActor func installsRegistryFormulaAndRefreshesPackages() async throws {
        let installedFormula = InstalledPackageDTO(
            name: "wget",
            kind: .formula,
            summary: "Internet file retriever",
            homepage: nil,
            installedVersions: [
                InstalledVersionDTO(version: "1.25.0", isActive: true, installedOn: nil)
            ],
            installedOn: Date(timeIntervalSince1970: 0)
        )
        let service = RecordingHomebrewService(installedPackagesResult: [installedFormula])
        let library = PackageLibrary(service: service)
        let context = try makeModelContext()
        library.disablesTapTrustChecks = true

        await library.installFormula(named: "wget", context: context)

        #expect(service.recordedOperations == [.installFormula("wget"), .installedPackages])
        #expect(service.recordedTrustCheckSettings == [true, true])
        #expect(library.isFormulaInstalled(named: "wget"))
        #expect(library.errorMessage == nil)
        #expect(library.isLoading == false)
        #expect(library.logs.contains { $0.title == "Formula installed" })
    }

    @Test @MainActor func doesNotRefreshPackagesWhenFormulaInstallationFails() async throws {
        let service = RecordingHomebrewService(installError: TestServiceError.installFailed)
        let library = PackageLibrary(service: service)
        let context = try makeModelContext()

        await library.installFormula(named: "wget", context: context)

        #expect(service.recordedOperations == [.installFormula("wget")])
        #expect(library.errorMessage == TestServiceError.installFailed.localizedDescription)
        #expect(library.isLoading == false)
        #expect(library.logs.contains { $0.title == "Formula installation failed" })
    }

    @Test func commandEnvironmentAppliesTapTrustPreference() {
        let inherited = [
            "HOMEBREW_NO_REQUIRE_TAP_TRUST": "1",
            "PRESERVED_VALUE": "present"
        ]

        let enabled = HomebrewCommandEnvironment.make(
            inheriting: inherited,
            resolvedPATH: "/test/bin",
            disablesTapTrustChecks: true,
            askpassPath: "/test/askpass"
        )
        let disabled = HomebrewCommandEnvironment.make(
            inheriting: inherited,
            resolvedPATH: "/test/bin",
            disablesTapTrustChecks: false,
            askpassPath: nil
        )

        #expect(enabled["HOMEBREW_NO_REQUIRE_TAP_TRUST"] == "1")
        #expect(enabled["SUDO_ASKPASS"] == "/test/askpass")
        #expect(enabled["PRESERVED_VALUE"] == "present")
        #expect(disabled["HOMEBREW_NO_REQUIRE_TAP_TRUST"] == nil)
    }

    @Test func parsesHomebrewUpgradeProgress() {
        #expect(HomebrewOutputParser.progressMessage(from: "==> Upgrading git") == "Upgrading git")
        #expect(
            HomebrewOutputParser.progressMessage(
                from: "\u{001B}[34m==> Installing dependencies for ripgrep: pcre2\u{001B}[0m"
            ) == "Installing dependencies for ripgrep: pcre2"
        )
        #expect(
            HomebrewOutputParser.progressMessage(
                from: "==> Running installer for docker with sudo; the password may be necessary."
            ) == "Waiting for administrator password for docker"
        )
        #expect(HomebrewOutputParser.progressMessage(from: "Already up-to-date.") == nil)
    }

    @Test func createsPrivateAskpassHelper() throws {
        let helper = try HomebrewAskpassHelper.create()
        defer { helper.remove() }

        let attributes = try FileManager.default.attributesOfItem(atPath: helper.executableURL.path)
        let permissions = try #require(attributes[.posixPermissions] as? NSNumber)
        let script = try String(contentsOf: helper.executableURL, encoding: .utf8)

        #expect(permissions.intValue == 0o700)
        #expect(script.contains("with hidden answer"))
        #expect(script.contains("/usr/bin/osascript"))
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

private enum RecordedHomebrewOperation: Equatable, Sendable {
    case installFormula(String)
    case updateHomebrew
    case upgradeAll
    case cleanup
    case installedPackages
}

private enum TestServiceError: LocalizedError {
    case installFailed
    case updateFailed
    case upgradeFailed

    var errorDescription: String? {
        switch self {
        case .installFailed:
            "The formula installation failed."
        case .updateFailed:
            "The Homebrew update failed."
        case .upgradeFailed:
            "The bulk upgrade failed."
        }
    }
}

@MainActor
private final class RecordingHomebrewService: HomebrewServicing {
    private(set) var recordedOperations: [RecordedHomebrewOperation] = []
    private(set) var recordedTrustCheckSettings: [Bool] = []
    private let updateError: (any Error)?
    private let upgradeError: (any Error)?
    private let installError: (any Error)?
    private let installedPackagesResult: [InstalledPackageDTO]

    init(
        updateError: (any Error)? = nil,
        upgradeError: (any Error)? = nil,
        installError: (any Error)? = nil,
        installedPackagesResult: [InstalledPackageDTO] = []
    ) {
        self.updateError = updateError
        self.upgradeError = upgradeError
        self.installError = installError
        self.installedPackagesResult = installedPackagesResult
    }

    func installedPackages(disablesTapTrustChecks: Bool) async throws -> [InstalledPackageDTO] {
        recordedOperations.append(.installedPackages)
        recordedTrustCheckSettings.append(disablesTapTrustChecks)
        return installedPackagesResult
    }

    func installFormula(packageName: String, disablesTapTrustChecks: Bool) async throws {
        recordedOperations.append(.installFormula(packageName))
        recordedTrustCheckSettings.append(disablesTapTrustChecks)
        if let installError {
            throw installError
        }
    }

    func updateHomebrew(disablesTapTrustChecks: Bool) async throws {
        recordedOperations.append(.updateHomebrew)
        recordedTrustCheckSettings.append(disablesTapTrustChecks)
        if let updateError {
            throw updateError
        }
    }

    func upgradeAll(disablesTapTrustChecks: Bool, progress: HomebrewProgressHandler?) async throws {
        recordedOperations.append(.upgradeAll)
        recordedTrustCheckSettings.append(disablesTapTrustChecks)
        if let upgradeError {
            throw upgradeError
        }
        progress?("Upgrading test-package")
    }

    func cleanup(disablesTapTrustChecks: Bool) async throws {
        recordedOperations.append(.cleanup)
        recordedTrustCheckSettings.append(disablesTapTrustChecks)
    }

    func deleteVersion(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws {}

    func makeVersionActive(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws {}

    func update(packageName: String, version: String?, disablesTapTrustChecks: Bool) async throws {}

    func reinstall(packageName: String, force: Bool, disablesTapTrustChecks: Bool) async throws {}

    func delete(packageName: String, disablesTapTrustChecks: Bool) async throws {}
}
