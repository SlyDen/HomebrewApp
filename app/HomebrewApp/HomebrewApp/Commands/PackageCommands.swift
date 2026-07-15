import SwiftUI

/// Menu commands for package list actions in the active window.
struct PackageCommands: Commands {
    @FocusedValue(\.refreshPackagesAction) private var refreshPackagesAction

    /// Command menu body.
    var body: some Commands {
        CommandMenu("Packages") {
            Button("Refresh Packages") {
                refreshPackagesAction?.perform()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(refreshPackagesAction?.isDisabled ?? true)
        }
    }
}

/// Focused action exposed by the package browser for app menu commands.
struct RefreshPackagesAction {
    let isDisabled: Bool
    let perform: () -> Void
}

private struct RefreshPackagesActionKey: FocusedValueKey {
    typealias Value = RefreshPackagesAction
}

extension FocusedValues {
    var refreshPackagesAction: RefreshPackagesAction? {
        get { self[RefreshPackagesActionKey.self] }
        set { self[RefreshPackagesActionKey.self] = newValue }
    }
}
