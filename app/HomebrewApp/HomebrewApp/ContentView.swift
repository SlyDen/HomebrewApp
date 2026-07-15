import SwiftData
import SwiftUI

/// Root SwiftUI view for the application.
///
/// `ContentView` owns the observable `PackageLibrary` instance for the window and
/// passes it into the package browser view hierarchy.
struct ContentView: View {
    @State private var library = PackageLibrary()

    /// Main view body containing the Homebrew package browser.
    var body: some View {
        PackageListView(library: library)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BrewPackage.self, BrewVersion.self], inMemory: true)
}
