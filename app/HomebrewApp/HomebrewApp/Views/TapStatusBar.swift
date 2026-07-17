import SwiftUI

/// Bottom status surface for tap commands and failures.
struct TapStatusBar: View {
    let operationMessage: String?
    let errorMessage: String?
    let isLoading: Bool
    let onDismissError: () -> Void

    /// Current progress or error with a dismiss action for failures.
    var body: some View {
        HStack {
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)

                Spacer(minLength: 0)

                Button("Dismiss Error", systemImage: "xmark", action: onDismissError)
                    .labelStyle(.iconOnly)
            } else if isLoading, let operationMessage {
                ProgressView()
                    .controlSize(.small)
                Text(operationMessage)
                Spacer(minLength: 0)
            }
        }
        .padding()
        .background(.bar)
    }
}
