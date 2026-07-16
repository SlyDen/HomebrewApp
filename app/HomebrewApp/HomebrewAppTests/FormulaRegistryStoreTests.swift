import Foundation
import Testing
@testable import HomebrewApp

@MainActor
struct FormulaRegistryStoreTests {
    @Test func decodesOfficialFormulaMetadataShape() throws {
        let data = Data(
            """
            {
              "name": "wget",
              "full_name": "wget",
              "tap": "homebrew/core",
              "aliases": ["wget2"],
              "desc": "Internet file retriever",
              "homepage": "https://www.gnu.org/software/wget/",
              "license": "GPL-3.0-or-later",
              "versions": { "stable": "1.25.0", "head": "HEAD", "bottle": true },
              "dependencies": ["gettext", "libidn2"],
              "build_dependencies": ["pkgconf"],
              "keg_only": false,
              "deprecated": false,
              "disabled": false
            }
            """.utf8
        )

        let formula = try JSONDecoder().decode(FormulaRegistryFormula.self, from: data)

        #expect(formula.name == "wget")
        #expect(formula.summary == "Internet file retriever")
        #expect(formula.versions.stable == "1.25.0")
        #expect(formula.versions.hasBottle)
        #expect(formula.dependencies == ["gettext", "libidn2"])
        #expect(formula.buildDependencies == ["pkgconf"])
        #expect(formula.registryPage?.absoluteString == "https://formulae.brew.sh/formula/wget")
    }

    @Test func searchesNamesAliasesAndDescriptions() async {
        let store = FormulaRegistryStore(
            service: StubFormulaRegistryService(formulae: FormulaRegistryFixtures.formulae)
        )
        await store.load()

        store.searchText = "rg"
        #expect(store.searchResults.map(\.name) == ["ripgrep"])

        store.searchText = "revision control"
        #expect(store.searchResults.map(\.name) == ["git"])

        store.searchText = "postgres"
        #expect(store.searchResults.map(\.name) == ["libpq"])
    }

    @Test func repairsSelectionWhenSearchChanges() async {
        let store = FormulaRegistryStore(
            service: StubFormulaRegistryService(formulae: FormulaRegistryFixtures.formulae)
        )
        await store.load()
        store.selectedFormulaID = "ripgrep"

        store.searchText = "Postgres"

        #expect(store.selectedFormulaID == "libpq")
        #expect(store.selectedFormula?.name == "libpq")
    }

    @Test func whitespaceQueryShowsFullSortedCatalog() async {
        let store = FormulaRegistryStore(
            service: StubFormulaRegistryService(formulae: FormulaRegistryFixtures.formulae.reversed())
        )
        await store.load()

        store.searchText = "   \n"

        #expect(store.searchResults.map(\.name) == ["git", "libpq", "ripgrep"])
    }
}

private nonisolated struct StubFormulaRegistryService: FormulaRegistryServicing {
    let formulae: [FormulaRegistryFormula]

    @concurrent func fetchFormulae(forceRefresh: Bool) async throws -> [FormulaRegistryFormula] {
        formulae
    }
}

private nonisolated enum FormulaRegistryFixtures {
    static let formulae = [
        FormulaRegistryFormula(
            name: "git",
            summary: "Distributed revision control system",
            versions: FormulaRegistryVersions(stable: "2.50.1", head: "HEAD", hasBottle: true)
        ),
        FormulaRegistryFormula(
            name: "libpq",
            aliases: ["postgresql-client"],
            summary: "Postgres C API library",
            versions: FormulaRegistryVersions(stable: "17.5", head: nil, hasBottle: true)
        ),
        FormulaRegistryFormula(
            name: "ripgrep",
            aliases: ["rg"],
            summary: "Search tool like grep",
            versions: FormulaRegistryVersions(stable: "14.1.1", head: "HEAD", hasBottle: true)
        )
    ]
}
