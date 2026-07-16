import SwiftUI

/// Toolbar menu for ordering the installed package sidebar.
struct PackageSortMenu: View {
    @Binding var sortOption: PackageSortOption

    /// Sort choices with the current choice marked by a checkmark.
    var body: some View {
        Menu {
            ForEach(PackageSortOption.allCases) { option in
                Button {
                    sortOption = option
                } label: {
                    Label(
                        option.title,
                        systemImage: sortOption == option ? "checkmark" : option.systemImage
                    )
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }
}
