import SwiftUI

/// One installed tap row with package counts, trust state, and removal action.
struct TapRow: View {
    let tap: HomebrewTap
    let isBusy: Bool
    let onRemove: () -> Void

    /// Compact tap metadata and destructive action.
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(tap.name)
                    .font(.headline)

                Text("\(tap.formulaNames.count) formulae, \(tap.caskTokens.count) casks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if tap.isTrusted {
                Label("Trusted", systemImage: "checkmark.shield")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .help("Homebrew trusts this tap")
            }

            Button("Remove \(tap.name)", systemImage: "trash", role: .destructive, action: onRemove)
                .labelStyle(.iconOnly)
                .disabled(isBusy)
                .help("Remove \(tap.name)")
        }
    }
}
