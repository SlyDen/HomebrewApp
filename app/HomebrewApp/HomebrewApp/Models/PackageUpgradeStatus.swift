import Foundation

/// Outcome of the most recent upgrade attempt for an installed package.
enum PackageUpgradeStatus: String, CaseIterable, Identifiable, Sendable {
    /// Homebrew completed the package upgrade without reporting an error.
    case succeeded

    /// Homebrew reported an error while upgrading the package.
    case failed

    /// Stable identity used by the package filter menu.
    var id: String { rawValue }

    /// Localizable label shown in result badges and filters.
    var title: LocalizedStringResource {
        switch self {
        case .succeeded: "Successfully Upgraded"
        case .failed: "Upgrade Errors"
        }
    }

    /// SF Symbol used to distinguish successful and failed upgrades.
    var systemImage: String {
        switch self {
        case .succeeded: "checkmark.circle.fill"
        case .failed: "xmark.octagon.fill"
        }
    }
}
