import Foundation

/// Type-qualified Homebrew installation command shared by logging and execution.
nonisolated struct HomebrewInstallCommand: Equatable, Sendable {
    /// Short or tap-qualified package name passed to Homebrew.
    let packageName: String

    /// Package category that determines the Homebrew install flag.
    let kind: ManagedPackageKind

    /// Arguments passed to the Homebrew executable after `brew`.
    var arguments: [String] {
        let packageFlag = switch kind {
        case .formula: "--formula"
        case .cask: "--cask"
        }
        return ["install", packageFlag, packageName]
    }

    /// Command text shown in the operation log.
    var displayString: String {
        "brew \(arguments.joined(separator: " "))"
    }
}
