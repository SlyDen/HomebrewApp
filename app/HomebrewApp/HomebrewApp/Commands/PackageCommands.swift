import SwiftUI

/// Menu commands for package list actions in the active window.
struct PackageCommands: Commands {
    @FocusedValue(\.refreshPackagesAction) private var refreshPackagesAction
    @FocusedValue(\.upgradeAllPackagesAction) private var upgradeAllPackagesAction

    /// Command menu body.
    var body: some Commands {
        CommandMenu("Packages") {
            Button("Refresh Packages") {
                refreshPackagesAction?.perform()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(refreshPackagesAction?.isDisabled ?? true)

            Divider()

            Button("Upgrade All Packages") {
                upgradeAllPackagesAction?.perform()
            }
            .disabled(upgradeAllPackagesAction?.isDisabled ?? true)
        }
    }
}

/// Focused action exposed by the package browser for app menu commands.
struct RefreshPackagesAction {
    let isDisabled: Bool
    let perform: () -> Void
}

/// Focused action exposed by the package browser for bulk upgrades.
struct UpgradeAllPackagesAction {
    let isDisabled: Bool
    let perform: () -> Void
}

extension FocusedValues {
    @Entry var refreshPackagesAction: RefreshPackagesAction?
    @Entry var upgradeAllPackagesAction: UpgradeAllPackagesAction?
}
