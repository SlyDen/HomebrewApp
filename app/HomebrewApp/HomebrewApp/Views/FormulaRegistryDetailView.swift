import SwiftUI

/// Detail panel for one formula published by Homebrew.
struct FormulaRegistryDetailView: View {
    @Environment(\.appAppearancePreference) private var appearancePreference
    let formula: FormulaRegistryFormula
    let isHomebrewProviderEnabled: Bool
    @Bindable var library: PackageLibrary

    /// Formula metadata organized into focused sections.
    var body: some View {
        List {
            Section {
                FormulaRegistryHeader(
                    name: formula.name,
                    summary: formula.summary,
                    stableVersion: formula.versions.stable,
                    homepage: formula.homepage,
                    registryPage: formula.registryPage
                )
            }

            Section("Actions") {
                FormulaInstallButton(
                    formulaName: formula.fullName,
                    isFormulaDisabled: formula.isDisabled,
                    isHomebrewProviderEnabled: isHomebrewProviderEnabled,
                    isInstalled: library.isFormulaInstalled(named: formula.name),
                    library: library
                )
            }

            FormulaAvailabilitySection(
                isDeprecated: formula.isDeprecated,
                isDisabled: formula.isDisabled,
                hasBottle: formula.versions.hasBottle,
                isKegOnly: formula.isKegOnly
            )

            FormulaMetadataSection(
                fullName: formula.fullName,
                tap: formula.tap,
                stableVersion: formula.versions.stable,
                headVersion: formula.versions.head,
                license: formula.license,
                aliases: formula.aliases
            )

            if formula.dependencies.isEmpty == false || formula.buildDependencies.isEmpty == false {
                FormulaDependenciesSection(
                    dependencies: formula.dependencies,
                    buildDependencies: formula.buildDependencies
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(appearancePreference.palette.editor)
        .navigationTitle(formula.name)
    }
}
