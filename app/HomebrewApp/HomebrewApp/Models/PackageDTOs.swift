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

/// Severity/category for execution log entries shown in the bottom panel.
enum PackageLogLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    /// General informational message.
    case info

    /// State transition message.
    case state

    /// Command that is about to execute.
    case command

    /// Successful completion message.
    case success

    /// Recoverable warning or empty state.
    case warning

    /// Operation failure.
    case error

    /// Stable identity for SwiftUI lists.
    var id: String { rawValue }

    /// Human-readable label shown in the log panel.
    var title: String {
        switch self {
        case .info: "Info"
        case .state: "State"
        case .command: "Command"
        case .success: "Success"
        case .warning: "Warning"
        case .error: "Error"
        }
    }

    /// SF Symbol shown next to the log level.
    var systemImage: String {
        switch self {
        case .info: "info.circle"
        case .state: "switch.2"
        case .command: "terminal"
        case .success: "checkmark.circle"
        case .warning: "exclamationmark.triangle"
        case .error: "xmark.octagon"
        }
    }
}

/// One execution log entry rendered in the bottom log panel.
struct PackageLogEntry: Identifiable, Hashable, Sendable {
    /// Stable identity for log rows.
    let id: UUID

    /// Time the entry was created.
    let timestamp: Date

    /// Severity/category that controls row color and iconography.
    let level: PackageLogLevel

    /// Short row title.
    let title: String

    /// Optional detailed output text.
    let detail: String?

    /// Creates a log row.
    init(id: UUID = UUID(), timestamp: Date = .now, level: PackageLogLevel, title: String, detail: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.title = title
        self.detail = detail
    }
}

/// A user action that can be invoked for a whole package.
///
/// The action names intentionally mirror package-manager concepts rather than
/// Homebrew command names so another service can map them to npm, cargo, or other
/// tooling later.
enum PackageAction: String, CaseIterable, Identifiable, Sendable {
    /// Upgrade this package to the latest available version.
    case upgrade

    /// Reinstall this package using the package manager's default behavior.
    case reinstall

    /// Force a reinstall where the package manager supports overwriting artifacts.
    case forceReinstall

    /// Remove this package from the system.
    case delete

    /// Stable identity for SwiftUI menus and controls.
    var id: String { rawValue }

    /// Label shown in package action controls.
    var title: String {
        switch self {
        case .upgrade: "Upgrade"
        case .reinstall: "Reinstall"
        case .forceReinstall: "Force Reinstall"
        case .delete: "Delete"
        }
    }

    /// SF Symbol shown next to the action label.
    var systemImage: String {
        switch self {
        case .upgrade: "arrow.up.circle"
        case .reinstall: "arrow.triangle.2.circlepath"
        case .forceReinstall: "exclamationmark.arrow.triangle.2.circlepath"
        case .delete: "trash"
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
        case .delete: "Delete Version"
        case .makeActive: "Make Active"
        case .update: "Upgrade Package"
        }
    }

    /// SF Symbol shown next to the action label.
    var systemImage: String {
        switch self {
        case .delete: "trash"
        case .makeActive: "checkmark.circle"
        case .update: "arrow.up.circle"
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
    nonisolated var id: String { "homebrew:\(kind.rawValue):\(name)" }

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

    /// Logical byte count inside the package's Homebrew-managed directory.
    let installedSize: Int64?

    /// Creates an immutable package snapshot.
    init(
        name: String,
        kind: ManagedPackageKind,
        summary: String,
        homepage: URL?,
        installedVersions: [InstalledVersionDTO],
        installedOn: Date,
        installedSize: Int64? = nil
    ) {
        self.name = name
        self.kind = kind
        self.summary = summary
        self.homepage = homepage
        self.installedVersions = installedVersions
        self.installedOn = installedOn
        self.installedSize = installedSize
    }

    /// Most recent known package install or upgrade timestamp.
    var updatedOn: Date {
        installedVersions.compactMap(\.installedOn).max() ?? installedOn
    }

    /// Returns this snapshot with an updated disk-usage measurement.
    func withInstalledSize(_ size: Int64?) -> InstalledPackageDTO {
        InstalledPackageDTO(
            name: name,
            kind: kind,
            summary: summary,
            homepage: homepage,
            installedVersions: installedVersions,
            installedOn: installedOn,
            installedSize: size
        )
    }
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
