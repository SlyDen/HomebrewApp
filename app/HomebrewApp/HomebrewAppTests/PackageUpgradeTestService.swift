import Foundation
@testable import HomebrewApp

@MainActor
final class PackageUpgradeTestService: HomebrewServicing {
    func installedPackages(disablesTapTrustChecks: Bool) async throws -> [InstalledPackageDTO] { [] }

    func installedTaps(disablesTapTrustChecks: Bool) async throws -> [HomebrewTap] { [] }

    func addTap(name: String, disablesTapTrustChecks: Bool) async throws {}

    func removeTap(name: String, disablesTapTrustChecks: Bool) async throws {}

    func installFormula(packageName: String, disablesTapTrustChecks: Bool) async throws {}

    func updateHomebrew(disablesTapTrustChecks: Bool) async throws {}

    func upgradeAll(disablesTapTrustChecks: Bool, progress: HomebrewProgressHandler?) async throws {
        progress?("Upgrading alpha")
        progress?("Upgrading beta 1.0 -> 2.0")
        throw PackageUpgradeTestError.upgradeFailed
    }

    func cleanup(disablesTapTrustChecks: Bool) async throws {}

    func deleteVersion(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws {}

    func makeVersionActive(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws {}

    func update(packageName: String, version: String?, disablesTapTrustChecks: Bool) async throws {}

    func reinstall(packageName: String, force: Bool, disablesTapTrustChecks: Bool) async throws {}

    func delete(packageName: String, disablesTapTrustChecks: Bool) async throws {}
}
