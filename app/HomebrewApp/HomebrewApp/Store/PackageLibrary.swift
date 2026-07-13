import Foundation
import Observation
import SwiftData

/// Main observable state container for the package browser.
///
/// `PackageLibrary` coordinates three responsibilities:
///
/// - Loading cached package snapshots from SwiftData for quick startup.
/// - Refreshing live package data through `HomebrewServicing`.
/// - Preparing UI state such as filtering, selection, errors, and JSON export data.
///
/// The type is main-actor isolated because SwiftUI observes it directly and
/// because it reads and writes `ModelContext` values supplied by the view layer.
@MainActor
@Observable
final class PackageLibrary {
    private let service: any HomebrewServicing

    /// Current in-memory package snapshots rendered by the UI.
    var packages: [InstalledPackageDTO] = []

    /// Navigation identity for the selected package detail screen.
    var selectedPackageID: InstalledPackageDTO.ID?

    /// User-entered search text applied to package names and summaries.
    var searchText = ""

    /// Optional package-kind filter selected from the toolbar menu.
    var selectedKind: ManagedPackageKind?

    /// Whether a refresh or package action is currently in progress.
    var isLoading = false

    /// User-facing error message shown by the status bar.
    var errorMessage: String?

    /// Pre-encoded JSON data used by `PackageExportDocument`.
    var exportData: Data?

    /// Creates a package library backed by the supplied service.
    ///
    /// - Parameter service: Optional service override for previews and tests. When
    ///   omitted, `HomebrewServiceFactory` selects the platform service.
    init(service: (any HomebrewServicing)? = nil) {
        self.service = service ?? HomebrewServiceFactory.make()
    }

    /// Packages after applying the selected kind filter and search text.
    var filteredPackages: [InstalledPackageDTO] {
        packages.filter { package in
            let matchesKind = selectedKind == nil || package.kind == selectedKind
            let matchesSearch = searchText.isEmpty
                || package.name.localizedStandardContains(searchText)
                || package.summary.localizedCaseInsensitiveContains(searchText)
            return matchesKind && matchesSearch
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The currently selected package, if it is still present in the latest data.
    var selectedPackage: InstalledPackageDTO? {
        guard let selectedPackageID else { return filteredPackages.first }
        return packages.first { $0.id == selectedPackageID }
    }

    /// Loads package snapshots from SwiftData into memory.
    ///
    /// Call this before a live refresh so the app can render the last known package
    /// list immediately.
    ///
    /// - Parameter context: SwiftData model context provided by the view hierarchy.
    func loadCachedPackages(from context: ModelContext) throws {
        let descriptor = FetchDescriptor<BrewPackage>(sortBy: [SortDescriptor(\BrewPackage.name)])
        packages = try context.fetch(descriptor).map { $0.snapshot() }
        if selectedPackageID == nil {
            selectedPackageID = filteredPackages.first?.id
        }
    }

    /// Refreshes packages from the service and persists the resulting snapshot.
    ///
    /// Errors are captured in `errorMessage` so the view can display them without
    /// needing its own command or persistence error handling.
    ///
    /// - Parameter context: SwiftData model context used to upsert cached records.
    func refresh(from context: ModelContext) async {
        isLoading = true
        errorMessage = nil

        do {
            let livePackages = try await service.installedPackages()
            try upsert(livePackages, in: context)
            packages = livePackages.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            selectedPackageID = selectedPackageID ?? packages.first?.id
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Performs a version-level action through the service and refreshes state.
    ///
    /// - Parameters:
    ///   - action: User-selected action from a version tag menu.
    ///   - package: Package that owns the selected version.
    ///   - version: Version selected by the user.
    ///   - context: SwiftData model context used by the follow-up refresh.
    func perform(_ action: PackageVersionAction, package: InstalledPackageDTO, version: InstalledVersionDTO, context: ModelContext) async {
        isLoading = true
        errorMessage = nil

        do {
            switch action {
            case .delete:
                try await service.deleteVersion(packageName: package.name, version: version.version)
            case .makeActive:
                try await service.makeVersionActive(packageName: package.name, version: version.version)
            case .update:
                try await service.update(packageName: package.name, version: version.version)
            }
            await refresh(from: context)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Encodes the current package list into the JSON export payload.
    ///
    /// The data is prepared here instead of inside `FileDocument` so encoding stays
    /// on the main actor with the observable state that owns the package snapshots.
    func prepareExport() {
        let payload = PackageExportDocumentPayload(exportedAt: .now, packageManager: "homebrew", packages: packages)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        exportData = try? encoder.encode(payload)
    }

    /// Reconciles live package snapshots with the SwiftData cache.
    ///
    /// Existing records are updated, new records are inserted, and records missing
    /// from the latest refresh are deleted so the cache mirrors Homebrew state.
    ///
    /// - Parameters:
    ///   - incomingPackages: Live snapshots returned by the package service.
    ///   - context: SwiftData model context to mutate and save.
    private func upsert(_ incomingPackages: [InstalledPackageDTO], in context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<BrewPackage>())
        var existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let incomingIDs = Set(incomingPackages.map(\.id))

        for package in incomingPackages {
            if let storedPackage = existingByID[package.id] {
                storedPackage.update(from: package)
            } else {
                let storedPackage = BrewPackage(
                    id: package.id,
                    name: package.name,
                    kind: package.kind,
                    packageSummary: package.summary,
                    homepage: package.homepage,
                    installedOn: package.installedOn,
                    versions: package.installedVersions.map { BrewVersion(version: $0.version, isActive: $0.isActive, installedOn: $0.installedOn) }
                )
                context.insert(storedPackage)
                existingByID[package.id] = storedPackage
            }
        }

        for storedPackage in existing where !incomingIDs.contains(storedPackage.id) {
            context.delete(storedPackage)
        }

        try context.save()
    }
}
