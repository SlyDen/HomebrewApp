import Foundation
@testable import HomebrewApp

@MainActor
final class PackageUpgradeTestService: HomebrewServicing {
    private let progressMessages: [String]
    private let upgradeError: (any Error)?

    init(
        progressMessages: [String] = ["Upgrading alpha", "Upgrading beta 1.0 -> 2.0"],
        upgradeError: (any Error)? = PackageUpgradeTestError.upgradeFailed
    ) {
        self.progressMessages = progressMessages
        self.upgradeError = upgradeError
    }

    func installedPackages(disablesTapTrustChecks: Bool) async throws -> [InstalledPackageDTO] { [] }

    func installedTaps(disablesTapTrustChecks: Bool) async throws -> [HomebrewTap] { [] }

    func addTap(name: String, disablesTapTrustChecks: Bool) async throws {}

    func removeTap(name: String, disablesTapTrustChecks: Bool) async throws {}

    func installPackage(
        packageName: String,
        kind: ManagedPackageKind,
        disablesTapTrustChecks: Bool
    ) async throws {}

    func updateHomebrew(disablesTapTrustChecks: Bool) async throws {}

    func upgradeAll(disablesTapTrustChecks: Bool, progress: HomebrewProgressHandler?) async throws {
        for message in progressMessages {
            progress?(message)
        }
        if let upgradeError {
            throw upgradeError
        }
    }

    func cleanup(disablesTapTrustChecks: Bool) async throws {}

    func deleteVersion(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws {}

    func makeVersionActive(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws {}

    func update(packageName: String, version: String?, disablesTapTrustChecks: Bool) async throws {}

    func reinstall(packageName: String, force: Bool, disablesTapTrustChecks: Bool) async throws {}

    func delete(packageName: String, disablesTapTrustChecks: Bool) async throws {}
}
