import SwiftUI

/// Interface for listing, adding, refreshing, and removing Homebrew taps.
struct TapManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var library: PackageLibrary
    let isHomebrewProviderEnabled: Bool
    @State private var newTapName = ""
    @State private var pendingRemoval: HomebrewTap?
    @State private var isRemovalConfirmationPresented = false

    /// Tap-management form with a confirmed destructive removal flow.
    var body: some View {
        NavigationStack {
            List {
                TapInputSection(
                    tapName: $newTapName,
                    isHomebrewProviderEnabled: isHomebrewProviderEnabled,
                    isBusy: library.isLoadingTaps || library.isLoading,
                    onAdd: addTap
                )

                TapListSection(
                    taps: library.taps,
                    isHomebrewProviderEnabled: isHomebrewProviderEnabled,
                    isLoading: library.isLoadingTaps,
                    onRemove: requestRemoval
                )
            }
            .navigationTitle("Homebrew Taps")
            .safeAreaInset(edge: .bottom) {
                if library.isLoadingTaps || library.tapErrorMessage != nil {
                    TapStatusBar(
                        operationMessage: library.tapOperationMessage,
                        errorMessage: library.tapErrorMessage,
                        isLoading: library.isLoadingTaps,
                        onDismissError: { library.tapErrorMessage = nil }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }

                ToolbarItem {
                    Button("Refresh Taps", systemImage: "arrow.clockwise") {
                        Task { await library.refreshTaps() }
                    }
                    .disabled(
                        isHomebrewProviderEnabled == false
                            || library.isLoadingTaps
                            || library.isLoading
                    )
                }
            }
        }
        .task {
            guard isHomebrewProviderEnabled else { return }
            await library.refreshTaps()
        }
        .confirmationDialog(
            "Remove Tap?",
            isPresented: $isRemovalConfirmationPresented,
            presenting: pendingRemoval
        ) { tap in
            Button("Remove \(tap.name)", role: .destructive) {
                Task { await library.removeTap(tap) }
            }
        } message: { tap in
            Text("This removes \(tap.name) and its \(tap.packageCount) packages from Homebrew search.")
        }
    }

    /// Adds the valid input and clears the field after success.
    private func addTap() {
        guard HomebrewTap.normalizedName(newTapName) != nil else { return }
        Task {
            if await library.addTap(named: newTapName) {
                newTapName = ""
            }
        }
    }

    /// Stages a tap for explicit destructive confirmation.
    private func requestRemoval(_ tap: HomebrewTap) {
        pendingRemoval = tap
        isRemovalConfirmationPresented = true
    }
}
