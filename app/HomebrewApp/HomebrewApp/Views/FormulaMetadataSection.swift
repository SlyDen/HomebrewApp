import SwiftUI

/// Name, tap, version, license, and alias metadata for a formula.
struct FormulaMetadataSection: View {
    let fullName: String
    let tap: String
    let stableVersion: String?
    let headVersion: String?
    let license: String?
    let aliases: [String]

    /// Registry metadata labels.
    var body: some View {
        Section("Details") {
            LabeledContent("Full Name", value: fullName)
            LabeledContent("Tap", value: tap)

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
