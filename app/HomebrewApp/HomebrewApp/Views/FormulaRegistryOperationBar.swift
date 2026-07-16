import SwiftUI

/// Bottom status banner for formula installation and installed-package refreshes.
struct FormulaRegistryOperationBar: View {
    @Bindable var library: PackageLibrary

    /// Current package operation progress or error state.
    var body: some View {
        HStack {
            if library.isLoading {
                ProgressView()
                    .controlSize(.small)

                Text(library.currentCommandProgress ?? "Working with Homebrew")
                    .lineLimit(2)
            } else if let errorMessage = library.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if library.errorMessage != nil, !library.isLoading {
                Button("Dismiss", systemImage: "xmark") {
                    library.errorMessage = nil
                }
                .labelStyle(.iconOnly)
            }
        }
        .padding()
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
