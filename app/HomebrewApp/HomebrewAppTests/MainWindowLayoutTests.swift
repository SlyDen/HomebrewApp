import AppKit
import SwiftUI
import Testing
@testable import HomebrewApp

struct MainWindowLayoutTests {
    @Test @MainActor func fittingSizeDoesNotGrowWithTransientContent() {
        let minimumSize = CGSize(width: 760, height: 480)
        let idealSize = CGSize(width: 1100, height: 700)
        let shortContent = NSHostingView(
            rootView: MainWindowLayout(
                minimumSize: minimumSize,
                idealSize: idealSize
            ) {
                Text("Idle")
            }
        )
        let oversizedContent = NSHostingView(
            rootView: MainWindowLayout(
                minimumSize: minimumSize,
                idealSize: idealSize
            ) {
                Text(String(repeating: "Installing dependencies for formula ", count: 100))
                    .fixedSize()
            }
        )

        #expect(shortContent.fittingSize == idealSize)
        #expect(oversizedContent.fittingSize == idealSize)
    }
}
