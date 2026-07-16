import SwiftUI

/// Primary formula identity, summary, version, and external links.
struct FormulaRegistryHeader: View {
    let name: String
    let summary: String?
    let stableVersion: String?
    let homepage: URL?
    let registryPage: URL?

    /// Header body for the selected formula.
    var body: some View {
        VStack(alignment: .leading) {
            Label {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.title2)
                        .bold()

                    if let stableVersion {
                        Text("Stable \(stableVersion)")
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: "shippingbox.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }

            if let summary, summary.isEmpty == false {
                Text(summary)
                    .textSelection(.enabled)
            } else {
                Text("No description available.")
                    .foregroundStyle(.secondary)
            }

            if let registryPage {
                Link(destination: registryPage) {
                    Label("View on Homebrew Formulae", systemImage: "safari")
                }
            }

            if let homepage {
                Link(destination: homepage) {
                    Label("Open Project Homepage", systemImage: "house")
                }
            }
        }
        .padding(.vertical)
    }
}
