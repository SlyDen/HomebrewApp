import Foundation
import Observation

/// Observable state for browsing and searching the public Homebrew formula registry.
@MainActor
@Observable
final class FormulaRegistryStore {
    @ObservationIgnored private let service: any FormulaRegistryServicing

    /// Formulae fetched from the public Homebrew registry before local tap merging.
    private var registryFormulae: [FormulaRegistryFormula] = []

    /// Formula names discovered from taps installed on this Mac.
    private var tappedFormulae: [FormulaRegistryFormula] = []

    /// Complete searchable catalog from the public registry and installed taps.
    private(set) var formulae: [FormulaRegistryFormula] = []

    /// Prepared formula results matching the current query.
    private(set) var searchResults: [FormulaRegistryFormula] = []

    /// User-entered query matched against formula metadata.
    var searchText = "" {
        didSet { updateSearchResults() }
    }

    /// Selection identity for the registry detail pane.
    var selectedFormulaID: FormulaRegistryFormula.ID? {
        didSet { updateSelectedFormula() }
    }

    /// Selected formula cached separately from the full catalog for narrow observation.
    private(set) var selectedFormula: FormulaRegistryFormula?

    /// Whether the registry catalog is currently loading.
    private(set) var isLoading = false

    /// User-facing load error, when the most recent request failed.
    private(set) var errorMessage: String?

    /// Creates registry state backed by the supplied service.
    init(service: any FormulaRegistryServicing = FormulaRegistryService()) {
        self.service = service
    }

    /// Loads the registry once, or revalidates it when explicitly requested.
    func load(forceRefresh: Bool = false) async {
        guard isLoading == false else { return }
        guard forceRefresh || registryFormulae.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let incomingFormulae = try await service.fetchFormulae(forceRefresh: forceRefresh)
            try Task.checkCancellation()
            registryFormulae = incomingFormulae
            rebuildCatalog()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Clears the most recent registry load error.
    func clearError() {
        errorMessage = nil
    }

    /// Replaces formula names supplied by installed taps and updates current search.
    func setTappedFormulae(_ formulae: [FormulaRegistryFormula]) {
        tappedFormulae = formulae
        rebuildCatalog()
    }

    /// Merges registry metadata with locally tapped formula names using full names as identity.
    private func rebuildCatalog() {
        var formulaeByID = Dictionary(uniqueKeysWithValues: registryFormulae.map { ($0.id, $0) })
        for formula in tappedFormulae where formulaeByID[formula.id] == nil {
            formulaeByID[formula.id] = formula
        }
        formulae = formulaeByID.values.sorted {
            $0.fullName.localizedStandardCompare($1.fullName) == .orderedAscending
        }
        updateSearchResults()
    }

    /// Updates the cached result set only when the catalog or query changes.
    private func updateSearchResults() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            searchResults = formulae
        } else {
            searchResults = formulae.filter { formula in
                formula.name.localizedStandardContains(query)
                    || formula.fullName.localizedStandardContains(query)
                    || formula.aliases.contains { $0.localizedStandardContains(query) }
                    || formula.summary?.localizedStandardContains(query) == true
            }
        }

        repairSelection()
    }

    /// Keeps selection constrained to the current result set.
    private func repairSelection() {
        let currentSelectionIsVisible = selectedFormulaID.map { selectedID in
            searchResults.contains { $0.id == selectedID }
        } ?? false
        let nextID = currentSelectionIsVisible ? selectedFormulaID : searchResults.first?.id

        if selectedFormulaID != nextID {
            selectedFormulaID = nextID
        } else {
            updateSelectedFormula()
        }
    }

    /// Updates the narrow selected-formula snapshot after selection changes.
    private func updateSelectedFormula() {
        guard let selectedFormulaID else {
            selectedFormula = nil
            return
        }
        selectedFormula = searchResults.first { $0.id == selectedFormulaID }
    }
}
