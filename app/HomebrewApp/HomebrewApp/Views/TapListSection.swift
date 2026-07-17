import SwiftUI

/// Installed-tap list and provider-aware empty state.
struct TapListSection: View {
    let taps: [HomebrewTap]
    let isHomebrewProviderEnabled: Bool
    let isLoading: Bool
    let onRemove: (HomebrewTap) -> Void

    /// Stable rows for each installed tap.
    var body: some View {
        Section("Installed Taps") {
            if isHomebrewProviderEnabled == false {
                Label("Enable the Homebrew provider in Settings to manage taps.", systemImage: "shippingbox")
                    .foregroundStyle(.secondary)
            } else if taps.isEmpty && isLoading {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading installed taps")
                        .foregroundStyle(.secondary)
                }
            } else if taps.isEmpty {
                Label("No formula taps are installed.", systemImage: "tray")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(taps) { tap in
                    TapRow(tap: tap, isBusy: isLoading) {
                        onRemove(tap)
                    }
                }
            }
        }
    }
}
