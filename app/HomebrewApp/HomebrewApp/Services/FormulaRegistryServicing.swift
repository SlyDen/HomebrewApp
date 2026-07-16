/// Service contract for loading formulae from the Homebrew registry.
nonisolated protocol FormulaRegistryServicing: Sendable {
    /// Fetches all formulae published by the official Homebrew registry.
    ///
    /// - Parameter forceRefresh: Whether to revalidate cached HTTP data.
    @concurrent func fetchFormulae(forceRefresh: Bool) async throws -> [FormulaRegistryFormula]
}
