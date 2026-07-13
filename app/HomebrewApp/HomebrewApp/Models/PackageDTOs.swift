import Foundation

/// A package category reported by a package manager.
///
/// The current app only loads Homebrew formulae and casks, but this enum is kept
/// separate from the SwiftData storage layer so later package-manager adapters
/// can feed the same list and detail UI with minimal changes.
enum ManagedPackageKind: String, Codable, CaseIterable, Identifiable, Sendable {
    /// A Homebrew command-line package installed as a formula.
    case formula

    /// A Homebrew graphical application bundle installed as a cask.
    case cask

    /// Stable identity used by SwiftUI lists and pickers.
    var id: String { rawValue }

    /// Human-readable label shown in filters and package details.
    var title: String {
        switch self {
        case .formula: "Formula"
        case .cask: "Cask"
        }
    }

    /// SF Symbol used to visually distinguish package categories.
    var systemImage: String {
        switch self {
        case .formula: "shippingbox"
        case .cask: "macwindow"
        }
    }
}

/// A user action that can be invoked from an installed-version tag.
///
/// The action names intentionally mirror package-manager concepts rather than
/// Homebrew command names so another service can map them to npm, cargo, or other
/// tooling later.
enum PackageVersionAction: String, CaseIterable, Identifiable, Sendable {
    /// Remove this installed version from the system.
    case delete

    /// Mark this version as the active version where the package manager supports it.
    case makeActive

    /// Update the package, optionally using the selected version as context.
    case update

    /// Stable identity for SwiftUI menus.
    var id: String { rawValue }

    /// Label shown in the version action menu.
    var title: String {
        switch self {
        case .delete: "Delete"
        case .makeActive: "Make Active"
        case .update: "Update"
        }
    }

    /// SF Symbol shown next to the action label.
    var systemImage: String {
        switch self {
        case .delete: "trash"
        case .makeActive: "checkmark.circle"
        case .update: "arrow.triangle.2.circlepath"
        }
    }
}

/// A package snapshot used by the UI, service layer, local cache, and JSON export.
///
/// This type is intentionally immutable and `Sendable` so CLI services can build
/// package snapshots off the main actor before the `PackageLibrary` publishes them
/// to SwiftUI.
struct InstalledPackageDTO: Codable, Hashable, Identifiable, Sendable {
    /// Stable Homebrew-specific identity for navigation, diffing, and persistence.
    var id: String { "homebrew:\(kind.rawValue):\(name)" }

    /// Package token or formula name, for example `git` or `visual-studio-code`.
    let name: String

    /// Package category reported by Homebrew.
    let kind: ManagedPackageKind

    /// Short package description shown in rows and details.
    let summary: String

    /// Project or package homepage, when Homebrew reports one.
    let homepage: URL?

    /// Installed versions known for this package.
    let installedVersions: [InstalledVersionDTO]

    /// Earliest known install timestamp for the package.
    let installedOn: Date
}

/// A version entry attached to an installed package snapshot.
struct InstalledVersionDTO: Codable, Hashable, Identifiable, Sendable {
    /// Uses the version string as the identity within its parent package.
    var id: String { version }

    /// Version reported by Homebrew.
    let version: String

    /// Indicates the currently active or linked version when that state is known.
    let isActive: Bool

    /// Install timestamp for this version, when Homebrew reports one.
    let installedOn: Date?
}

/// Top-level JSON document written by the app's export flow.
///
/// The exported shape is designed to be readable now and suitable for a later
/// bulk-install/import workflow.
struct PackageExportDocumentPayload: Codable, Sendable {
    /// Timestamp when the export was prepared.
    let exportedAt: Date

    /// Source package manager name, currently `homebrew`.
    let packageManager: String

    /// Package snapshots included in the export.
    let packages: [InstalledPackageDTO]
}
