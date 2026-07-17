import SwiftUI

/// Detail panel for one formula or cask available through Homebrew.
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
                    kind: formula.kind,
                    summary: formula.summary,
                    stableVersion: formula.versions.stable,
                    homepage: formula.homepage,
                    registryPage: formula.registryPage
                )
            }

            Section("Actions") {
                RegistryInstallButton(
                    packageName: formula.fullName,
                    kind: formula.kind,
                    isPackageDisabled: formula.isDisabled,
                    isHomebrewProviderEnabled: isHomebrewProviderEnabled,
                    isInstalled: library.isPackageInstalled(named: formula.name, kind: formula.kind),
                    library: library
                )
            }

            FormulaAvailabilitySection(
                kind: formula.kind,
                isDeprecated: formula.isDeprecated,
                isDisabled: formula.isDisabled,
                hasBottle: formula.versions.hasBottle,
                isKegOnly: formula.isKegOnly
            )

            FormulaMetadataSection(
                kind: formula.kind,
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
