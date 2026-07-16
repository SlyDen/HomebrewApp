import SwiftData
import SwiftUI

/// Installs one registry formula through the shared package library.
struct FormulaInstallButton: View {
    @Environment(\.modelContext) private var modelContext
    let formulaName: String
    let isFormulaDisabled: Bool
    let isHomebrewProviderEnabled: Bool
    let isInstalled: Bool
    @Bindable var library: PackageLibrary

    /// Context-aware install action used in registry rows and formula details.
    var body: some View {
        Button {
            Task {
                await library.installFormula(named: formulaName, context: modelContext)
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
                || isFormulaDisabled
                || !isHomebrewProviderEnabled
                || library.isLoading
        )
        .help(helpText)
    }

    /// Explains why the install action is unavailable when disabled.
    private var helpText: LocalizedStringResource {
        if isInstalled {
            "This formula is already installed"
        } else if isFormulaDisabled {
            "Homebrew has disabled this formula"
        } else if !isHomebrewProviderEnabled {
            "Enable the Homebrew provider in Settings to install formulae"
        } else {
            "Install this formula with Homebrew"
        }
    }
}
