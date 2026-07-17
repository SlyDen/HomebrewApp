import SwiftData
import SwiftUI

/// Installs one catalog package through the shared package library.
struct RegistryInstallButton: View {
    @Environment(\.modelContext) private var modelContext
    let packageName: String
    let kind: ManagedPackageKind
    let isPackageDisabled: Bool
    let isHomebrewProviderEnabled: Bool
    let isInstalled: Bool
    @Bindable var library: PackageLibrary

    /// Context-aware install action used in catalog rows and package details.
    var body: some View {
        Button {
            Task {
                await library.installPackage(
                    named: packageName,
                    kind: kind,
                    context: modelContext
                )
            }
        } label: {
            Label(
                isInstalled ? "Installed" : "Install",
                systemImage: isInstalled ? "checkmark.circle.fill" : "square.and.arrow.down"
            )
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(
            isInstalled
                || isPackageDisabled
                || isHomebrewProviderEnabled == false
                || library.isLoading
        )
        .help(helpText)
    }

    /// Explains why the install action is unavailable when disabled.
    private var helpText: LocalizedStringResource {
        if isInstalled {
            switch kind {
            case .formula: "This formula is already installed"
            case .cask: "This cask is already installed"
            }
        } else if isPackageDisabled {
            switch kind {
            case .formula: "Homebrew has disabled this formula"
            case .cask: "Homebrew has disabled this cask"
            }
        } else if isHomebrewProviderEnabled == false {
            "Enable the Homebrew provider in Settings to install packages"
        } else {
            switch kind {
            case .formula: "Install this formula with Homebrew"
            case .cask: "Install this cask with Homebrew"
            }
        }
    }
}
