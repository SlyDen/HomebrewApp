import SwiftUI

/// Bottom error banner retained when a refresh fails after cached results exist.
struct FormulaRegistryErrorBar: View {
    let message: String
    @Bindable var store: FormulaRegistryStore

    /// Dismissible registry error message.
    var body: some View {
        HStack {
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
                .lineLimit(2)

            Spacer(minLength: 0)

            Button("Dismiss", systemImage: "xmark") {
                store.clearError()
            }
            .labelStyle(.iconOnly)
        }
        .padding()
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
