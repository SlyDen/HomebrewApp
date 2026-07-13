import Foundation
import SwiftData

/// Persisted representation of a Homebrew package.
///
/// `BrewPackage` stores the latest package snapshot returned by the service so
/// the app can show cached results immediately on launch, before a fresh CLI
/// refresh completes. It deliberately stores `kindRawValue` instead of the enum
/// directly to keep the SwiftData model schema simple and migration-friendly.
@Model
final class BrewPackage {
    /// Stable package identity shared with `InstalledPackageDTO.id`.
    @Attribute(.unique) var id: String

    /// Homebrew formula name or cask token.
    var name: String

    /// Raw value for `ManagedPackageKind`.
    var kindRawValue: String

    /// Cached package description.
    var packageSummary: String

    /// Cached homepage URL, if one was reported by Homebrew.
    var homepage: URL?

    /// Earliest known install date for the package.
    var installedOn: Date

    /// Timestamp when this record was last seen in a refresh.
    var lastSeenAt: Date

    /// Installed versions belonging to this package.
    @Relationship(deleteRule: .cascade, inverse: \BrewVersion.package) var versions: [BrewVersion]

    /// Creates a persisted package record from a service snapshot.
    ///
    /// - Parameters:
    ///   - id: Stable package identity.
    ///   - name: Homebrew formula name or cask token.
    ///   - kind: Package category.
    ///   - packageSummary: Human-readable package description.
    ///   - homepage: Optional package homepage.
    ///   - installedOn: Earliest known install date.
    ///   - lastSeenAt: Refresh timestamp for cache bookkeeping.
    ///   - versions: Installed version records owned by this package.
    init(
        id: String,
        name: String,
        kind: ManagedPackageKind,
        packageSummary: String,
        homepage: URL?,
        installedOn: Date,
        lastSeenAt: Date = .now,
        versions: [BrewVersion] = []
    ) {
        self.id = id
        self.name = name
        self.kindRawValue = kind.rawValue
        self.packageSummary = packageSummary
        self.homepage = homepage
        self.installedOn = installedOn
        self.lastSeenAt = lastSeenAt
        self.versions = versions
    }

    /// Typed package kind derived from the stored raw value.
    ///
    /// Unknown future values fall back to `.formula` so older app versions can
    /// still render cached records instead of failing to decode the model.
    var kind: ManagedPackageKind {
        get { ManagedPackageKind(rawValue: kindRawValue) ?? .formula }
        set { kindRawValue = newValue.rawValue }
    }
}

/// Persisted version record owned by a `BrewPackage`.
@Model
final class BrewVersion {
    /// Version string reported by Homebrew.
    var version: String

    /// Whether this version is active or linked.
    var isActive: Bool

    /// Install timestamp for this version, when known.
    var installedOn: Date?

    /// Owning package relationship.
    var package: BrewPackage?

    /// Creates a persisted installed-version record.
    ///
    /// - Parameters:
    ///   - version: Version string reported by Homebrew.
    ///   - isActive: Whether this version is active or linked.
    ///   - installedOn: Optional version install timestamp.
    init(version: String, isActive: Bool = false, installedOn: Date? = nil) {
        self.version = version
        self.isActive = isActive
        self.installedOn = installedOn
    }
}

extension BrewPackage {
    /// Replaces this persisted record with the latest service snapshot.
    ///
    /// The version relationship is rebuilt from the incoming DTO because the CLI
    /// response is treated as the source of truth during refresh.
    ///
    /// - Parameters:
    ///   - package: Latest package snapshot returned by the service layer.
    ///   - seenAt: Refresh timestamp to store in `lastSeenAt`.
    func update(from package: InstalledPackageDTO, seenAt: Date = .now) {
        name = package.name
        kind = package.kind
        packageSummary = package.summary
        homepage = package.homepage
        installedOn = package.installedOn
        lastSeenAt = seenAt

        versions.removeAll()
        versions = package.installedVersions.map { version in
            BrewVersion(version: version.version, isActive: version.isActive, installedOn: version.installedOn)
        }
    }

    /// Builds an immutable UI/export snapshot from the persisted record.
    ///
    /// Versions are sorted with active versions first and then by descending
    /// localized version string, which keeps the most relevant tags visible first.
    func snapshot() -> InstalledPackageDTO {
        InstalledPackageDTO(
            name: name,
            kind: kind,
            summary: packageSummary,
            homepage: homepage,
            installedVersions: versions
                .sorted { lhs, rhs in
                    if lhs.isActive != rhs.isActive { return lhs.isActive }
                    return lhs.version.localizedStandardCompare(rhs.version) == .orderedDescending
                }
                .map { InstalledVersionDTO(version: $0.version, isActive: $0.isActive, installedOn: $0.installedOn) },
            installedOn: installedOn
        )
    }
}
