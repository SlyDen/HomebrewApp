import SwiftUI

/// Availability flags reported by the formula registry.
struct FormulaAvailabilitySection: View {
    let isDeprecated: Bool
    let isDisabled: Bool
    let hasBottle: Bool
    let isKegOnly: Bool

    /// Availability status and installation characteristics.
    var body: some View {
        Section("Availability") {
            if isDisabled {
                Label("Disabled by Homebrew", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
            } else if isDeprecated {
                Label("Deprecated by Homebrew", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            } else {
                Label("Available to install", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            LabeledContent("Prebuilt Bottle") {
                if hasBottle {
                    Text("Available")
                } else {
                    Text("Not reported")
                }
            }

            LabeledContent("Keg Only") {
                if isKegOnly {
                    Text("Yes")
                } else {
                    Text("No")
                }
            }
        }
    }
}
