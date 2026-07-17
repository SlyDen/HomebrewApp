import SwiftUI

/// Sidebar containing catalog search results and refresh controls.
struct FormulaRegistrySidebar: View {
    @Environment(\.appAppearancePreference) private var appearancePreference
    @Bindable var store: FormulaRegistryStore
    @Bindable var library: PackageLibrary
    let isHomebrewProviderEnabled: Bool
    @State private var isTapManagerPresented = false

    /// Search result list with loading, failure, and empty states.
    var body: some View {
        List(store.searchResults, selection: $store.selectedFormulaID) { package in
            FormulaRegistryRow(
                name: package.name,
                kind: package.kind,
                fullName: package.fullName,
                tap: package.tap,
                summary: package.summary,
                stableVersion: package.versions.stable,
                isDeprecated: package.isDeprecated,
                isDisabled: package.isDisabled,
                isHomebrewProviderEnabled: isHomebrewProviderEnabled,
                isInstalled: library.isPackageInstalled(named: package.name, kind: package.kind),
                library: library
            )
            .tag(package.id)
            .listRowBackground(appearancePreference.palette.sidebar.opacity(0.62))
        }
        .scrollContentBackground(.hidden)
        .background(appearancePreference.palette.sidebar)
        .navigationTitle("Homebrew Catalog")
        .searchable(text: $store.searchText, prompt: "Search formulae and casks")
        .overlay {
            if store.isLoading && store.formulae.isEmpty {
                ContentUnavailableView {
                    Label("Loading Catalog", systemImage: "arrow.down.circle")
                } description: {
                    Text("Fetching formulae and loading packages from installed taps.")
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
                    "No Matching Packages",
                    systemImage: "magnifyingglass",
                    description: Text("Try a formula, cask, alias, tap, or description.")
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
                        store.setTappedCatalogItems(library.tappedCatalogItems)
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
