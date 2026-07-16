import SwiftUI

/// A width-bounded summary of the current package operation.
///
/// The summary accepts the width offered by the console dock instead of using
/// command output as an intrinsic minimum width for the app window.
struct ConsoleActivitySummary: View {
    /// Short label describing the activity.
    let title: String

    /// Optional command or log detail.
    let detail: String?

    /// Color used for command or log detail.
    let detailColor: Color

    /// System preference used to disable progress-label transitions.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// One-line summary that truncates before it can resize the window.
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let detail {
                Text(detail)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(detailColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .contentTransition(.opacity)
                    .animation(reduceMotion ? nil : .snappy, value: detail)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .clipped()
    }
}

#Preview {
    ConsoleActivitySummary(
        title: "Current operation",
        detail: "Installing dependencies for a-formula-with-an-intentionally-long-name",
        detailColor: .blue
    )
    .frame(width: 320)
    .padding()
}
