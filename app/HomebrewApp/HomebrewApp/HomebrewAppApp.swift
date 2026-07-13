import SwiftData
import SwiftUI

/// Application entry point.
///
/// The app installs the SwiftData model container used to cache Homebrew package
/// and version snapshots between launches.
@main
struct HomebrewAppApp: App {
    /// Scene graph for the single-window package browser app.
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [BrewPackage.self, BrewVersion.self])
    }
}
