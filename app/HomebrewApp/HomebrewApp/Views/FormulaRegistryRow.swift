import SwiftUI

/// Compact formula metadata shown in one registry result row.
struct FormulaRegistryRow: View {
    let name: String
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

                    if let stableVersion {
                        Text("Version \(stableVersion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: "shippingbox")
                    .symbolRenderingMode(.hierarchical)
            }

            Spacer(minLength: 0)

            FormulaInstallButton(
                formulaName: name,
                isFormulaDisabled: isDisabled,
                isHomebrewProviderEnabled: isHomebrewProviderEnabled,
                isInstalled: isInstalled,
                library: library
            )
        }
    }
}
