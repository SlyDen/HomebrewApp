import Foundation

enum PackageUpgradeTestError: LocalizedError {
    case upgradeFailed

    var errorDescription: String? {
        "The bulk upgrade failed."
    }
}
