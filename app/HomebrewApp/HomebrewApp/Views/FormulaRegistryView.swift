import SwiftData
import SwiftUI

/// Searchable browser for formulae published by the official Homebrew registry.
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
            if let formula = store.selectedFormula {
                FormulaRegistryDetailView(
                    formula: formula,
                    isHomebrewProviderEnabled: isHomebrewProviderEnabled,
                    library: library
                )
                    .navigationSplitViewColumnWidth(min: 420, ideal: 760)
            } else {
                ContentUnavailableView(
                    "Select a Formula",
                    systemImage: "shippingbox",
                    description: Text("Choose a registry result to view its versions, dependencies, and links.")
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
                store.setTappedFormulae(library.tappedFormulae)
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
        .onChange(of: library.tappedFormulae) { _, formulae in
            store.setTappedFormulae(formulae)
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
