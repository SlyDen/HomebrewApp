import SwiftData
import SwiftUI

/// Searchable browser for public formulae and packages from installed taps.
struct FormulaRegistryView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var store: FormulaRegistryStore
    @Bindable var library: PackageLibrary
    let isHomebrewProviderEnabled: Bool
    let disablesTapTrustChecks: Bool

    /// Registry browser with a results sidebar and formula detail pane.
    var body: some View {
        NavigationSplitView {
            FormulaRegistrySidebar(
                store: store,
                library: library,
                isHomebrewProviderEnabled: isHomebrewProviderEnabled
            )
                .navigationSplitViewColumnWidth(min: 360, ideal: 460, max: 560)
        } detail: {
            if let package = store.selectedFormula {
                FormulaRegistryDetailView(
                    formula: package,
                    isHomebrewProviderEnabled: isHomebrewProviderEnabled,
                    library: library
                )
                    .navigationSplitViewColumnWidth(min: 420, ideal: 760)
            } else {
                ContentUnavailableView(
                    "Select a Package",
                    systemImage: "shippingbox",
                    description: Text("Choose a catalog result to view its details and installation action.")
                )
                .navigationSplitViewColumnWidth(min: 420, ideal: 760)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if let errorMessage = store.errorMessage, store.formulae.isEmpty == false {
                    FormulaRegistryErrorBar(message: errorMessage, store: store)
                }

                if library.isLoading || library.errorMessage != nil {
                    FormulaRegistryOperationBar(library: library)
                }
            }
        }
        .task {
            await store.load()
        }
        .task {
            library.disablesTapTrustChecks = disablesTapTrustChecks

            if isHomebrewProviderEnabled {
                await library.refreshTaps()
                store.setTappedCatalogItems(library.tappedCatalogItems)
            }

            guard library.packages.isEmpty else { return }

            do {
                try library.loadCachedPackages(from: modelContext)
            } catch {
                library.errorMessage = error.localizedDescription
                library.appendLog(.error, "Cache load failed", detail: error.localizedDescription)
            }

            if library.packages.isEmpty, isHomebrewProviderEnabled {
                await library.refresh(from: modelContext)
            }
        }
        .onChange(of: disablesTapTrustChecks) { _, isDisabled in
            library.disablesTapTrustChecks = isDisabled
        }
        .onChange(of: library.tappedCatalogItems) { _, packages in
            store.setTappedCatalogItems(packages)
        }
    }
}

#Preview {
    FormulaRegistryView(
        store: FormulaRegistryStore(
            service: PreviewFormulaRegistryService()
        ),
        library: PackageLibrary(service: MockHomebrewService()),
        isHomebrewProviderEnabled: true,
        disablesTapTrustChecks: false
    )
    .modelContainer(for: [BrewPackage.self, BrewVersion.self], inMemory: true)
}
