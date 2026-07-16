import Foundation

/// Ordering choices for the installed package sidebar.
enum PackageSortOption: String, CaseIterable, Identifiable, Sendable {
    /// Sort package names alphabetically.
    case name

    /// Sort known package sizes from largest to smallest.
    case size

    /// Sort packages by their most recent install or upgrade date.
    case updatedDate

    /// Stable identity used by SwiftUI menus.
    var id: String { rawValue }

    /// Localizable menu title.
    var title: LocalizedStringResource {
        switch self {
        case .name: "Name"
        case .size: "Size"
        case .updatedDate: "Updated Date"
        }
    }

    /// SF Symbol used by the sort menu.
    var systemImage: String {
        switch self {
        case .name: "textformat"
        case .size: "internaldrive"
        case .updatedDate: "calendar"
        }
    }

    /// Returns packages ordered according to this option.
    func sorted(_ packages: [InstalledPackageDTO]) -> [InstalledPackageDTO] {
        packages.sorted { lhs, rhs in
            switch self {
            case .name:
                compareNames(lhs, rhs)
            case .size:
                compareSizes(lhs, rhs)
            case .updatedDate:
                compareUpdatedDates(lhs, rhs)
            }
        }
    }

    /// Alphabetical comparison used directly and as a deterministic tie-breaker.
    private func compareNames(_ lhs: InstalledPackageDTO, _ rhs: InstalledPackageDTO) -> Bool {
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    /// Largest-first size comparison with unknown values placed last.
    private func compareSizes(_ lhs: InstalledPackageDTO, _ rhs: InstalledPackageDTO) -> Bool {
        switch (lhs.installedSize, rhs.installedSize) {
        case let (lhsSize?, rhsSize?) where lhsSize != rhsSize:
            lhsSize > rhsSize
        case (.some, nil):
            true
        case (nil, .some):
            false
        default:
            compareNames(lhs, rhs)
        }
    }

    /// Newest-first update comparison with name as a deterministic tie-breaker.
    private func compareUpdatedDates(_ lhs: InstalledPackageDTO, _ rhs: InstalledPackageDTO) -> Bool {
        if lhs.updatedOn != rhs.updatedOn {
            return lhs.updatedOn > rhs.updatedOn
        }
        return compareNames(lhs, rhs)
    }
}
