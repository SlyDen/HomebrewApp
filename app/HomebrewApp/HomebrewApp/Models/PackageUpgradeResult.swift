import Foundation

/// Per-package result retained for the latest upgrade operation.
struct PackageUpgradeResult: Equatable, Sendable {
    /// Whether the package upgrade succeeded or failed.
    let status: PackageUpgradeStatus

    /// Homebrew's error description when the package upgrade failed.
    let message: String?

    /// Time at which the result became known.
    let completedAt: Date

    /// Creates a package upgrade result.
    init(status: PackageUpgradeStatus, message: String? = nil, completedAt: Date = .now) {
        self.status = status
        self.message = message
        self.completedAt = completedAt
    }
}
