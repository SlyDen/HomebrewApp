import SwiftData
import SwiftUI

/// Root SwiftUI view for the application.
///
/// `ContentView` owns the observable `PackageLibrary` instance for the window and
/// passes it into the package browser view hierarchy.
struct ContentView: View {
    @AppStorage(AppPreferenceKeys.appearancePreference)
    private var appearancePreferenceRawValue = AppearancePreference.system.rawValue
    @AppStorage(AppPreferenceKeys.isHomebrewProviderEnabled) private var isHomebrewProviderEnabled = true
    @AppStorage(AppPreferenceKeys.cleanupAfterUpgrade) private var cleanupAfterUpgrade = true
    @AppStorage(AppPreferenceKeys.disablesTapTrustChecks) private var disablesTapTrustChecks = false
    @State private var library = PackageLibrary()
    @State private var formulaRegistry = FormulaRegistryStore()

    /// Main view body containing the Homebrew package browser.
    var body: some View {
        TabView {
            Tab("Installed", systemImage: "shippingbox") {
                PackageListView(
                    library: library,
                    isHomebrewProviderEnabled: $isHomebrewProviderEnabled,
                    cleanupAfterUpgrade: cleanupAfterUpgrade,
                    disablesTapTrustChecks: disablesTapTrustChecks
                )
            }

            Tab("Discover", systemImage: "magnifyingglass") {
                FormulaRegistryView(
                    store: formulaRegistry,
                    library: library,
                    isHomebrewProviderEnabled: isHomebrewProviderEnabled,
                    disablesTapTrustChecks: disablesTapTrustChecks
                )
            }
        }
        .appAppearance(appearancePreference)
        .onAppear {
            appearancePreference.apply()
        }
        .onChange(of: appearancePreferenceRawValue) { _, newRawValue in
            (AppearancePreference(rawValue: newRawValue) ?? .system).apply()
        }
    }

    /// Current appearance preference decoded from persisted storage.
    private var appearancePreference: AppearancePreference {
        AppearancePreference(rawValue: appearancePreferenceRawValue) ?? .system
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BrewPackage.self, BrewVersion.self], inMemory: true)
}
