import SwiftUI

/// Keeps the main window's sizing contract independent from dynamic content.
///
/// A standard `WindowGroup` derives its minimum size from its content. Package
/// actions replace and disable several controls at once, which can temporarily
/// produce a much larger fitting size. This layout reports stable minimum and
/// ideal sizes while still accepting every larger size chosen by the user.
struct MainWindowLayout: Layout {
    /// Smallest supported main-window content size.
    let minimumSize: CGSize

    /// Size used when the window system requests an unspecified fitting size.
    let idealSize: CGSize

    /// Returns a stable size for minimum and ideal layout queries.
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        CGSize(
            width: resolvedDimension(
                proposal.width,
                minimum: minimumSize.width,
                ideal: idealSize.width
            ),
            height: resolvedDimension(
                proposal.height,
                minimum: minimumSize.height,
                ideal: idealSize.height
            )
        )
    }

    /// Gives the window content the complete size selected by the user.
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let contentProposal = ProposedViewSize(bounds.size)

        for subview in subviews {
            subview.place(
                at: bounds.origin,
                anchor: .topLeading,
                proposal: contentProposal
            )
        }
    }

    /// Resolves minimum, ideal, and user-selected dimensions without consulting
    /// transient child fitting sizes.
    private func resolvedDimension(
        _ proposedDimension: CGFloat?,
        minimum: CGFloat,
        ideal: CGFloat
    ) -> CGFloat {
        guard let proposedDimension, proposedDimension.isFinite else {
            return max(minimum, ideal)
        }

        return max(minimum, proposedDimension)
    }
}

#Preview {
    MainWindowLayout(
        minimumSize: CGSize(width: 760, height: 480),
        idealSize: CGSize(width: 1100, height: 700)
    ) {
        Color.accentColor
    }
    .frame(width: 900, height: 600)
}
