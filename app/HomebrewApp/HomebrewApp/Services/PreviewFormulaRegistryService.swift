import Foundation

/// Deterministic registry service used only by the SwiftUI preview.
nonisolated struct PreviewFormulaRegistryService: FormulaRegistryServicing {
    @concurrent func fetchFormulae(forceRefresh: Bool) async throws -> [FormulaRegistryFormula] {
        [
            FormulaRegistryFormula(
                name: "git",
                summary: "Distributed revision control system",
                homepage: URL(string: "https://git-scm.com"),
                license: "GPL-2.0-only",
                versions: FormulaRegistryVersions(stable: "2.50.1", head: "HEAD", hasBottle: true),
                dependencies: ["gettext", "pcre2"]
            ),
            FormulaRegistryFormula(
                name: "ripgrep",
                aliases: ["rg"],
                summary: "Search tool like grep and The Silver Searcher",
                homepage: URL(string: "https://github.com/BurntSushi/ripgrep"),
                license: "Unlicense OR MIT",
                versions: FormulaRegistryVersions(stable: "14.1.1", head: "HEAD", hasBottle: true)
            )
        ]
    }
}
