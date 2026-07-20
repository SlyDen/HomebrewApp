import SwiftUI

/// Subtle row tint reinforcing the icon used for the latest upgrade result.
struct PackageUpgradeRowBackground: View {
    /// Existing sidebar color used when no upgrade result is available.
    let baseColor: Color

    /// Latest upgrade result for the row, when available.
    let status: PackageUpgradeStatus?

    /// Background layers for the package row.
    var body: some View {
        ZStack {
            baseColor

            switch status {
            case .succeeded?:
                Color.green.opacity(0.12)
            case .failed?:
                Color.red.opacity(0.14)
            case nil:
                Color.clear
            }
        }
    }
}
