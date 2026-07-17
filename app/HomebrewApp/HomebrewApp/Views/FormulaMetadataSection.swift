import SwiftUI

/// Name, type, tap, and available registry metadata for a package.
struct FormulaMetadataSection: View {
    let kind: ManagedPackageKind
    let fullName: String
    let tap: String
    let stableVersion: String?
    let headVersion: String?
    let license: String?
    let aliases: [String]

    /// Registry metadata labels.
    var body: some View {
        Section("Details") {
            LabeledContent("Type", value: kind.title)
            LabeledContent("Full Name", value: fullName)
            LabeledContent("Tap", value: tap)

            if kind == .formula {
                LabeledContent("Stable Version") {
                    if let stableVersion {
                        Text(stableVersion)
                    } else {
                        Text("Not reported")
                    }
                }

                if let headVersion {
                    LabeledContent("Head Version", value: headVersion)
                }

                LabeledContent("License") {
                    if let license, license.isEmpty == false {
                        Text(license)
                    } else {
                        Text("Not reported")
                    }
                }

                if aliases.isEmpty == false {
                    LabeledContent("Aliases", value: aliases.formatted())
                }
            }
        }
    }
}
