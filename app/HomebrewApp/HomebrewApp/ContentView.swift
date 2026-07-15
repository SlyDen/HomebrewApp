import SwiftData
import SwiftUI

/// Root SwiftUI view for the application.
///
/// `ContentView` owns the observable `PackageLibrary` instance for the window and
/// passes it into the package browser view hierarchy.
struct ContentView: View {
    @AppStorage("appearancePreference") private var appearancePreferenceRawValue = AppearancePreference.system.rawValue
    @State private var library = PackageLibrary()
    @State private var appearancePreference: AppearancePreference

    init() {
        let storedValue = UserDefaults.standard.string(forKey: "appearancePreference") ?? AppearancePreference.system.rawValue
        _appearancePreference = State(initialValue: AppearancePreference(rawValue: storedValue) ?? .system)
    }

    /// Main view body containing the Homebrew package browser.
    var body: some View {
        PackageListView(library: library, appearancePreference: $appearancePreference)
            .appAppearance(appearancePreference)
            .onAppear {
                appearancePreference.apply()
            }
            .onChange(of: appearancePreference) { _, newPreference in
                appearancePreferenceRawValue = newPreference.rawValue
                newPreference.apply()
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BrewPackage.self, BrewVersion.self], inMemory: true)
}
