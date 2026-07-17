import Foundation

/// A formula or cask available to install from Homebrew.
///
/// Public API records provide full metadata for formulae. Casks contributed by
/// locally installed taps use the same catalog shape with package-kind identity
/// and the metadata Homebrew exposes through `tap-info`.
nonisolated struct FormulaRegistryFormula: Decodable, Equatable, Hashable, Identifiable, Sendable {
    /// Stable registry identity used for list diffing and selection.
    var id: String { "\(kind.rawValue):\(fullName)" }

    /// Homebrew package category used to choose install semantics.
    let kind: ManagedPackageKind

    /// Short formula name accepted by `brew install`.
    let name: String

    /// Tap-qualified formula name.
    let fullName: String

    /// Tap that publishes the formula.
    let tap: String

    /// Alternate names accepted by Homebrew.
    let aliases: [String]

    /// Short description supplied by the formula author.
    let summary: String?

    /// Upstream project homepage.
    let homepage: URL?

    /// SPDX license expression reported by Homebrew.
    let license: String?

    /// Versions currently published by the registry.
    let versions: FormulaRegistryVersions

    /// Runtime dependencies declared by the formula.
    let dependencies: [String]

    /// Build-only dependencies declared by the formula.
    let buildDependencies: [String]

    /// Whether Homebrew installs this formula outside the shared prefix.
    let isKegOnly: Bool

    /// Whether maintainers have deprecated the formula.
    let isDeprecated: Bool

    /// Whether maintainers have disabled new installations.
    let isDisabled: Bool

    /// Public Homebrew Formulae detail page for this formula.
    var registryPage: URL? {
        guard kind == .formula, tap == "homebrew/core" else { return nil }
        return URL(string: "https://formulae.brew.sh/formula/\(name)")
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case fullName = "full_name"
        case tap
        case aliases
        case summary = "desc"
        case homepage
        case license
        case versions
        case dependencies
        case buildDependencies = "build_dependencies"
        case isKegOnly = "keg_only"
        case isDeprecated = "deprecated"
        case isDisabled = "disabled"
    }

    /// Decodes the stable subset of the additive Homebrew formula schema used by the app.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = .formula
        name = try container.decode(String.self, forKey: .name)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName) ?? name
        tap = try container.decodeIfPresent(String.self, forKey: .tap) ?? "homebrew/core"
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        license = try container.decodeIfPresent(String.self, forKey: .license)
        versions = try container.decodeIfPresent(FormulaRegistryVersions.self, forKey: .versions) ?? .empty
        dependencies = try container.decodeIfPresent([String].self, forKey: .dependencies) ?? []
        buildDependencies = try container.decodeIfPresent([String].self, forKey: .buildDependencies) ?? []
        isKegOnly = try container.decodeIfPresent(Bool.self, forKey: .isKegOnly) ?? false
        isDeprecated = try container.decodeIfPresent(Bool.self, forKey: .isDeprecated) ?? false
        isDisabled = try container.decodeIfPresent(Bool.self, forKey: .isDisabled) ?? false

        if let homepageString = try container.decodeIfPresent(String.self, forKey: .homepage),
           let homepage = URL(string: homepageString),
           homepage.scheme != nil {
            self.homepage = homepage
        } else {
            homepage = nil
        }
    }

    /// Creates a formula value directly for previews and tests.
    init(
        name: String,
        kind: ManagedPackageKind = .formula,
        fullName: String? = nil,
        tap: String = "homebrew/core",
        aliases: [String] = [],
        summary: String? = nil,
        homepage: URL? = nil,
        license: String? = nil,
        versions: FormulaRegistryVersions = .empty,
        dependencies: [String] = [],
        buildDependencies: [String] = [],
        isKegOnly: Bool = false,
        isDeprecated: Bool = false,
        isDisabled: Bool = false
    ) {
        self.kind = kind
        self.name = name
        self.fullName = fullName ?? name
        self.tap = tap
        self.aliases = aliases
        self.summary = summary
        self.homepage = homepage
        self.license = license
        self.versions = versions
        self.dependencies = dependencies
        self.buildDependencies = buildDependencies
        self.isKegOnly = isKegOnly
        self.isDeprecated = isDeprecated
        self.isDisabled = isDisabled
    }
}
