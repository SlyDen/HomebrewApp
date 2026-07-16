import Foundation
import Testing
@testable import HomebrewApp

@MainActor
struct PackageSortOptionTests {
    @Test(
        arguments: [
            (PackageSortOption.name, ["alpha", "beta", "gamma"]),
            (PackageSortOption.size, ["gamma", "alpha", "beta"]),
            (PackageSortOption.updatedDate, ["beta", "gamma", "alpha"])
        ]
    )
    func sortsPackages(option: PackageSortOption, expectedNames: [String]) {
        let packages = [
            package(name: "beta", size: nil, updatedAt: 300),
            package(name: "alpha", size: 100, updatedAt: 100),
            package(name: "gamma", size: 300, updatedAt: 200)
        ]

        #expect(option.sorted(packages).map(\.name) == expectedNames)
    }

    /// Creates a deterministic package snapshot for sort assertions.
    private func package(name: String, size: Int64?, updatedAt: TimeInterval) -> InstalledPackageDTO {
        let date = Date(timeIntervalSince1970: updatedAt)
        return InstalledPackageDTO(
            name: name,
            kind: .formula,
            summary: "Test package",
            homepage: nil,
            installedVersions: [
                InstalledVersionDTO(version: "1.0", isActive: true, installedOn: date)
            ],
            installedOn: date,
            installedSize: size
        )
    }
}
