import Foundation
import Testing
@testable import HomebrewApp

struct HomebrewTapTests {
    @Test func decodesTapInfoAndBuildsSearchablePackages() throws {
        let data = Data(
            """
            {
              "name": "darrylmorley/whatcable",
              "installed": true,
              "official": false,
              "trusted": false,
              "formula_names": ["darrylmorley/whatcable/whatcable-cli"],
              "cask_tokens": ["darrylmorley/whatcable/whatcable"],
              "remote": "https://github.com/darrylmorley/homebrew-whatcable"
            }
            """.utf8
        )

        let tap = try JSONDecoder().decode(HomebrewTap.self, from: data)

        #expect(tap.name == "darrylmorley/whatcable")
        #expect(tap.isInstalled)
        #expect(tap.formulaNames == ["darrylmorley/whatcable/whatcable-cli"])
        #expect(tap.caskTokens == ["darrylmorley/whatcable/whatcable"])
        #expect(tap.formulae.first?.kind == .formula)
        #expect(tap.casks.first?.name == "whatcable")
        #expect(tap.casks.first?.kind == .cask)
        #expect(tap.casks.first?.fullName == "darrylmorley/whatcable/whatcable")
        #expect(tap.casks.first?.registryPage == nil)
        #expect(tap.packageCount == 2)
    }

    @Test func validatesCanonicalTapNames() {
        #expect(HomebrewTap.normalizedName("  darrylmorley/whatcable\n") == "darrylmorley/whatcable")
        #expect(HomebrewTap.normalizedName("owner/repo.with-punctuation_2") == "owner/repo.with-punctuation_2")
        #expect(HomebrewTap.normalizedName("whatcable") == nil)
        #expect(HomebrewTap.normalizedName("owner/repo/extra") == nil)
        #expect(HomebrewTap.normalizedName("owner/repo name") == nil)
    }
}
