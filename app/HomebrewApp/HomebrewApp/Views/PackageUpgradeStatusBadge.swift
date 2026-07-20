import SwiftUI

/// Compact accessible icon describing the latest upgrade result for a package row.
struct PackageUpgradeStatusBadge: View {
    /// Upgrade result rendered by this badge.
    let result: PackageUpgradeResult

    /// Badge color associated with the result state.
    private var color: Color {
        switch result.status {
        case .succeeded: .green
        case .failed: .red
        }
    }

    /// Status icon and assistive description.
    var body: some View {
        Image(systemName: result.status.systemImage)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .accessibilityLabel(Text(result.status.title))
            .help(helpText)
    }

    /// Tooltip text with failure details when Homebrew supplied them.
    private var helpText: String {
        if let message = result.message {
            return String(
                localized: "Upgrade failed: \(message)",
                comment: "Package row tooltip followed by Homebrew's failure description."
            )
        }
        return String(localized: result.status.title)
    }
}
