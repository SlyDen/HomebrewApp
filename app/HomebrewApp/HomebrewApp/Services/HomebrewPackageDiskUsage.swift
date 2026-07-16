import Foundation

/// Calculates logical disk usage for Homebrew-managed package directories.
nonisolated struct HomebrewPackageDiskUsage {
    /// Builds package paths from the Homebrew prefix before measuring them.
    @concurrent static func sizes(
        for packages: [InstalledPackageDTO],
        homebrewPrefix: URL
    ) async -> [String: Int64] {
        let cellar = homebrewPrefix.appending(path: "Cellar", directoryHint: .isDirectory)
        let caskroom = homebrewPrefix.appending(path: "Caskroom", directoryHint: .isDirectory)
        let directories = Dictionary(uniqueKeysWithValues: packages.map { package in
            let root = package.kind == .formula ? cellar : caskroom
            return (
                package.id,
                root.appending(path: package.name, directoryHint: .isDirectory)
            )
        })
        return await sizes(for: directories)
    }

    /// Walks package directories away from the main actor and returns byte counts
    /// keyed by `InstalledPackageDTO.id`.
    @concurrent static func sizes(for packageDirectories: [String: URL]) async -> [String: Int64] {
        measuredSizes(for: packageDirectories)
    }

    /// Synchronous filesystem walk executed by the concurrent async entry point.
    private static func measuredSizes(for packageDirectories: [String: URL]) -> [String: Int64] {
        var sizes: [String: Int64] = [:]
        let fileManager = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey]

        for (packageID, directory) in packageDirectories {
            guard fileManager.fileExists(atPath: directory.path),
                  let enumerator = fileManager.enumerator(
                    at: directory,
                    includingPropertiesForKeys: Array(resourceKeys)
                  ) else {
                continue
            }

            var byteCount: Int64 = 0
            for case let fileURL as URL in enumerator {
                guard let values = try? fileURL.resourceValues(forKeys: resourceKeys),
                      values.isRegularFile == true else {
                    continue
                }
                byteCount += Int64(values.fileSize ?? 0)
            }
            sizes[packageID] = byteCount
        }

        return sizes
    }
}
