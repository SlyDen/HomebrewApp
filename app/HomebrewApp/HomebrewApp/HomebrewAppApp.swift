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
            MainWindowLayout(
                minimumSize: CGSize(width: 760, height: 480),
                idealSize: CGSize(width: 1100, height: 700)
            ) {
                ContentView()
            }
        }
        .modelContainer(for: [BrewPackage.self, BrewVersion.self])
        .windowResizability(.contentMinSize)
        .defaultWindowPlacement { _, context in
            let displayBounds = context.defaultDisplay.visibleRect
            let size = CGSize(width: displayBounds.width * 0.7, height: displayBounds.height * 0.7)
            let position = CGPoint(x: displayBounds.midX - size.width / 2.0, y: displayBounds.midY - size.height / 2.0)
            return WindowPlacement(position, size: size)
        }
        .commands {
            PackageCommands()
        }

        #if os(macOS)
        Settings {
            AppSettingsView()
        }
        #endif
    }
}
