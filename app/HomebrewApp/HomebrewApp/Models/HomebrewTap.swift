import Foundation

/// One Homebrew tap and the formulae it makes available locally.
nonisolated struct HomebrewTap: Decodable, Equatable, Identifiable, Sendable {
    /// Canonical `user/repository` tap name.
    let name: String

    /// Whether Homebrew reports the tap as installed on this Mac.
    let isInstalled: Bool

    /// Whether Homebrew maintains the tap.
    let isOfficial: Bool

    /// Whether Homebrew trusts formulae from the tap without an override.
    let isTrusted: Bool

    /// Fully qualified formula names made available by this tap.
    let formulaNames: [String]

    /// Git remote backing the tap, when Homebrew reports one.
    let remote: String?

    /// Stable identity used by tap lists and removal confirmation.
    var id: String { name }

    /// Searchable formula placeholders for metadata that is only available locally.
    var formulae: [FormulaRegistryFormula] {
        formulaNames.map { fullName in
            FormulaRegistryFormula(
                name: fullName.split(separator: "/").last.map(String.init) ?? fullName,
                fullName: fullName,
                tap: name
            )
        }
    }

    /// Normalizes and validates a tap name entered as `user/repository`.
    static func normalizedName(_ input: String) -> String? {
        let trimmedName = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmedName.split(separator: "/", omittingEmptySubsequences: false)
        guard components.count == 2,
              components.allSatisfy({ component in
                  component.isEmpty == false && component.allSatisfy { character in
                      character.isLetter || character.isNumber || "-._".contains(character)
                  }
              }) else {
            return nil
        }
        return trimmedName
    }

    /// Creates a tap value directly for previews and tests.
    init(
        name: String,
        isInstalled: Bool = true,
        isOfficial: Bool = false,
        isTrusted: Bool = false,
        formulaNames: [String] = [],
        remote: String? = nil
    ) {
        self.name = name
        self.isInstalled = isInstalled
        self.isOfficial = isOfficial
        self.isTrusted = isTrusted
        self.formulaNames = formulaNames
        self.remote = remote
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case isInstalled = "installed"
        case isOfficial = "official"
        case isTrusted = "trusted"
        case formulaNames = "formula_names"
        case remote
    }

    /// Decodes the stable subset of `brew tap-info --installed --json` used by the app.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        isInstalled = try container.decodeIfPresent(Bool.self, forKey: .isInstalled) ?? false
        isOfficial = try container.decodeIfPresent(Bool.self, forKey: .isOfficial) ?? false
        isTrusted = try container.decodeIfPresent(Bool.self, forKey: .isTrusted) ?? false
        formulaNames = try container.decodeIfPresent([String].self, forKey: .formulaNames) ?? []
        remote = try container.decodeIfPresent(String.self, forKey: .remote)
    }
}
