import SwiftUI

/// Visible menu for combining package type, version-count, and upgrade-result filters.
struct PackageFilterMenu: View {
    /// Currently selected package kind, or `nil` for all package types.
    @Binding var selectedKind: ManagedPackageKind?

    /// Whether only packages with more than one installed version are shown.
    @Binding var showsOnlyMultipleVersions: Bool

    /// Result from the latest upgrade operation used to narrow the list.
    @Binding var selectedUpgradeStatus: PackageUpgradeStatus?

    /// Number of filters currently applied to the package list.
    let activeFilterCount: Int

    /// Action that restores every package-list filter to its default value.
    let clearFilters: () -> Void

    /// Filter menu body.
    var body: some View {
        Menu {
            Picker("Package Type", selection: $selectedKind) {
                Text("All Package Types")
                    .tag(nil as ManagedPackageKind?)

                ForEach(ManagedPackageKind.allCases) { kind in
                    Label(kind.title, systemImage: kind.systemImage)
                        .tag(kind as ManagedPackageKind?)
                }
            }

            Toggle(isOn: $showsOnlyMultipleVersions) {
                Label("Multiple Versions", systemImage: "square.stack.3d.up")
            }

            Divider()

            Picker("Latest Upgrade", selection: $selectedUpgradeStatus) {
                Text("All Upgrade Results")
                    .tag(nil as PackageUpgradeStatus?)

                ForEach(PackageUpgradeStatus.allCases) { status in
                    Label(status.title, systemImage: status.systemImage)
                        .tag(status as PackageUpgradeStatus?)
                }
            }

            Divider()

            Button("Clear Filters", systemImage: "line.3.horizontal.decrease.circle") {
                clearFilters()
            }
            .disabled(activeFilterCount == 0)
        } label: {
            Label {
                if activeFilterCount == 0 {
                    Text("Filters")
                } else {
                    Text(
                        "Filters (\(activeFilterCount))",
                        comment: "Package list filter button followed by the number of active filters."
                    )
                }
            } icon: {
                Image(
                    systemName: activeFilterCount == 0
                        ? "line.3.horizontal.decrease.circle"
                        : "line.3.horizontal.decrease.circle.fill"
                )
            }
        }
    }
}
