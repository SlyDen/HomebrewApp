import SwiftUI

/// Input controls for adding one Homebrew tap by canonical name.
struct TapInputSection: View {
    @Binding var tapName: String
    let isHomebrewProviderEnabled: Bool
    let isBusy: Bool
    let onAdd: () -> Void

    /// Tap-name field with validation-aware submission controls.
    var body: some View {
        Section("Add Tap") {
            HStack {
                TextField("user/repository", text: $tapName)
                    .onSubmit(onAdd)

                Button("Add Tap", systemImage: "plus", action: onAdd)
                    .disabled(canAdd == false)
            }

            Text("Enter a GitHub tap name, for example darrylmorley/whatcable.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Whether the current input can start a Homebrew tap command.
    private var canAdd: Bool {
        isHomebrewProviderEnabled
            && isBusy == false
            && HomebrewTap.normalizedName(tapName) != nil
    }
}
