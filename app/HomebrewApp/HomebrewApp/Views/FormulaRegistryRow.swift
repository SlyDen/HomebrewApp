import SwiftUI

/// Compact package metadata shown in one catalog result row.
struct FormulaRegistryRow: View {
    let name: String
    let kind: ManagedPackageKind
    let fullName: String
    let tap: String
    let summary: String?
    let stableVersion: String?
    let isDeprecated: Bool
    let isDisabled: Bool
    let isHomebrewProviderEnabled: Bool
    let isInstalled: Bool
    @Bindable var library: PackageLibrary

    /// Row body with stable identity metadata and availability status.
    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading) {
                    HStack {
                        Text(name)
                            .font(.headline)

                        if isDisabled {
                            Text("Disabled")
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else if isDeprecated {
                            Text("Deprecated")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    if let summary, summary.isEmpty == false {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if tap != "homebrew/core" {
                        Text(tap)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let stableVersion {
                        Text("Version \(stableVersion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: kind.systemImage)
                    .symbolRenderingMode(.hierarchical)
            }

            Spacer(minLength: 0)

            RegistryInstallButton(
                packageName: fullName,
                kind: kind,
                isPackageDisabled: isDisabled,
                isHomebrewProviderEnabled: isHomebrewProviderEnabled,
                isInstalled: isInstalled,
                library: library
            )
        }
    }
}
