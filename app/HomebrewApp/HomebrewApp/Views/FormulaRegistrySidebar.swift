import SwiftUI

/// Sidebar containing registry search results and refresh controls.
struct FormulaRegistrySidebar: View {
    @Environment(\.appAppearancePreference) private var appearancePreference
    @Bindable var store: FormulaRegistryStore
    @Bindable var library: PackageLibrary
    let isHomebrewProviderEnabled: Bool
    @State private var isTapManagerPresented = false

    /// Search result list with loading, failure, and empty states.
    var body: some View {
        List(store.searchResults, selection: $store.selectedFormulaID) { formula in
            FormulaRegistryRow(
                name: formula.name,
                fullName: formula.fullName,
                tap: formula.tap,
                summary: formula.summary,
                stableVersion: formula.versions.stable,
                isDeprecated: formula.isDeprecated,
                isDisabled: formula.isDisabled,
                isHomebrewProviderEnabled: isHomebrewProviderEnabled,
                isInstalled: library.isFormulaInstalled(named: formula.name),
                library: library
            )
            .tag(formula.id)
            .listRowBackground(appearancePreference.palette.sidebar.opacity(0.62))
        }
        .scrollContentBackground(.hidden)
        .background(appearancePreference.palette.sidebar)
        .navigationTitle("Formula Registry")
        .searchable(text: $store.searchText, prompt: "Search formulae")
        .overlay {
            if store.isLoading && store.formulae.isEmpty {
                ContentUnavailableView {
                    Label("Loading Formulae", systemImage: "arrow.down.circle")
                } description: {
                    Text("Fetching the current catalog from Homebrew.")
                } actions: {
                    ProgressView()
                        .controlSize(.small)
                }
            } else if let errorMessage = store.errorMessage, store.formulae.isEmpty {
                ContentUnavailableView {
                    Label("Registry Unavailable", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Try Again", systemImage: "arrow.clockwise") {
                        Task { await store.load(forceRefresh: true) }
                    }
                }
            } else if store.searchResults.isEmpty && store.searchText.isEmpty == false {
                ContentUnavailableView(
                    "No Matching Formulae",
                    systemImage: "magnifyingglass",
                    description: Text("Try a formula name, alias, or description.")
                )
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Manage Taps", systemImage: "externaldrive.badge.plus") {
                    isTapManagerPresented = true
                }
                .disabled(isHomebrewProviderEnabled == false)

                Button("Refresh Registry", systemImage: "arrow.clockwise") {
                    Task {
                        await store.load(forceRefresh: true)
                        await library.refreshTaps()
                        store.setTappedFormulae(library.tappedFormulae)
                    }
                }
                .disabled(store.isLoading || library.isLoadingTaps)
            }
        }
        .sheet(isPresented: $isTapManagerPresented) {
            TapManagementView(
                library: library,
                isHomebrewProviderEnabled: isHomebrewProviderEnabled
            )
        }
    }
}
