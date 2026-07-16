import Foundation

/// Published versions embedded in a Homebrew registry formula.
nonisolated struct FormulaRegistryVersions: Decodable, Equatable, Hashable, Sendable {
    /// Empty version metadata used when the registry omits the object.
    static let empty = FormulaRegistryVersions(stable: nil, head: nil, hasBottle: false)

    /// Latest stable version, when available.
    let stable: String?

    /// Development version label, when available.
    let head: String?

    /// Whether Homebrew publishes a prebuilt bottle for at least one platform.
    let hasBottle: Bool

    private enum CodingKeys: String, CodingKey {
        case stable
        case head
        case hasBottle = "bottle"
    }

    /// Creates version metadata directly for previews and tests.
    init(stable: String?, head: String?, hasBottle: Bool) {
        self.stable = stable
        self.head = head
        self.hasBottle = hasBottle
    }

    /// Decodes version metadata while tolerating additive or missing fields.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stable = try container.decodeIfPresent(String.self, forKey: .stable)
        head = try container.decodeIfPresent(String.self, forKey: .head)
        hasBottle = try container.decodeIfPresent(Bool.self, forKey: .hasBottle) ?? false
    }
}
