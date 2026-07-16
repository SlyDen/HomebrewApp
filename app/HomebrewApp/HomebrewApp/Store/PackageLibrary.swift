import Foundation
import Observation
import SwiftData

/// Main observable state container for the package browser.
///
/// `PackageLibrary` coordinates three responsibilities:
///
/// - Loading cached package snapshots from SwiftData for quick startup.
/// - Refreshing live package data through `HomebrewServicing`.
/// - Preparing UI state such as filtering, selection, errors, logs, and JSON export data.
///
/// The type is main-actor isolated because SwiftUI observes it directly and
/// because it reads and writes `ModelContext` values supplied by the view layer.
@MainActor
@Observable
final class PackageLibrary {
    private let service: any HomebrewServicing
    private let maximumLogCount = 500

    /// Current in-memory package snapshots rendered by the UI.
    var packages: [InstalledPackageDTO] = []

    /// Navigation identity for the selected package detail screen.
    var selectedPackageID: InstalledPackageDTO.ID?

    /// User-entered search text applied to package names and summaries.
    var searchText = ""

    /// Optional package-kind filter selected from the toolbar menu.
    var selectedKind: ManagedPackageKind?

    /// Ordering applied to the installed package sidebar.
    var sortOption: PackageSortOption = .name

    /// Whether the list should only show packages with more than one installed version.
    var showsOnlyMultipleVersions = false

    /// Whether a refresh or package action is currently in progress.
    var isLoading = false

    /// Whether child Homebrew commands bypass non-official tap trust checks.
    var disablesTapTrustChecks = false

    /// Concise live status parsed from the currently running Homebrew command.
    var currentCommandProgress: String?

    /// Whether the bottom execution log panel is visible.
    var isLogPanelPresented = false

    /// Color-coded operation log entries shown in the bottom panel.
    var logs: [PackageLogEntry] = []

    /// User-facing error message shown by the status bar.
    var errorMessage: String?

    /// Pre-encoded JSON data used by `PackageExportDocument`.
    var exportData: Data?

    /// Identifies the command whose streamed callbacks may update live progress.
    @ObservationIgnored private var activeProgressSessionID: UUID?

    /// Creates a package library backed by the supplied service.
    ///
    /// - Parameter service: Optional service override for previews and tests. When
    ///   omitted, `HomebrewServiceFactory` selects the platform service.
    init(service: (any HomebrewServicing)? = nil) {
        self.service = service ?? HomebrewServiceFactory.make()
        appendLog(.info, "Package library ready", detail: "Waiting for cache load or refresh.")
    }

    /// Packages after applying the selected kind, version-count, and search filters.
    var filteredPackages: [InstalledPackageDTO] {
        let matchingPackages = packages.filter { package in
            let matchesKind = selectedKind == nil || package.kind == selectedKind
            let matchesVersionCount = !showsOnlyMultipleVersions || package.installedVersions.count > 1
            let matchesSearch = searchText.isEmpty
                || package.name.localizedStandardContains(searchText)
                || package.summary.localizedCaseInsensitiveContains(searchText)
            return matchesKind && matchesVersionCount && matchesSearch
        }
        return sortOption.sorted(matchingPackages)
    }

    /// The currently selected package, if it is still present in the latest data.
    var selectedPackage: InstalledPackageDTO? {
        guard let selectedPackageID else { return filteredPackages.first }
        return packages.first { $0.id == selectedPackageID }
    }

    /// Returns whether Homebrew currently reports the named formula as installed.
    ///
    /// - Parameter name: Exact formula name published by the registry.
    func isFormulaInstalled(named name: String) -> Bool {
        packages.contains { package in
            package.kind == .formula && package.name == name
        }
    }

    /// Installs a formula selected from the Homebrew registry and refreshes the
    /// installed package snapshot afterward.
    ///
    /// - Parameters:
    ///   - formulaName: Exact formula name published by the registry.
    ///   - context: SwiftData model context used by the follow-up refresh.
    func installFormula(named formulaName: String, context: ModelContext) async {
        guard !isLoading, !isFormulaInstalled(named: formulaName) else { return }

        isLoading = true
        errorMessage = nil
        currentCommandProgress = "Installing \(formulaName)"
        appendLog(.state, "Installing formula", detail: "Formula: \(formulaName)")
        appendLog(.command, "Executing command", detail: "brew install --formula \(formulaName)")

        do {
            try await service.installFormula(
                packageName: formulaName,
                disablesTapTrustChecks: disablesTapTrustChecks
            )
            appendLog(.success, "Formula installed", detail: "Refreshing installed packages after \(formulaName).")
            currentCommandProgress = "Refreshing installed packages"
            await refresh(from: context)
        } catch is CancellationError {
            appendLog(.info, "Formula installation cancelled", detail: "Formula: \(formulaName)")
        } catch {
            errorMessage = error.localizedDescription
            appendLog(.error, "Formula installation failed", detail: error.localizedDescription)
        }

        currentCommandProgress = nil
        isLoading = false
    }

    /// Loads package snapshots from SwiftData into memory.
    ///
    /// Call this before a live refresh so the app can render the last known package
    /// list immediately.
    ///
    /// - Parameter context: SwiftData model context provided by the view hierarchy.
    func loadCachedPackages(from context: ModelContext) throws {
        appendLog(.state, "Loading cached packages", detail: "Reading SwiftData package cache.")
        let descriptor = FetchDescriptor<BrewPackage>(sortBy: [SortDescriptor(\BrewPackage.name)])
        packages = try context.fetch(descriptor).map { $0.snapshot() }
        repairSelection()
        appendLog(.success, "Loaded cache", detail: "\(packages.count) packages available from local cache.")
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
        appendLog(.state, "Refreshing package list", detail: "Fetching installed Homebrew packages.")
        appendLog(.command, "Executing command", detail: "brew info --json=v2 --installed")

        do {
            let livePackages = try await service.installedPackages(disablesTapTrustChecks: disablesTapTrustChecks)
            appendLog(.success, "Fetched package list", detail: "Homebrew returned \(livePackages.count) installed packages.")
            try upsert(livePackages, in: context)
            packages = livePackages.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            repairSelection()
            appendLog(.success, "Package list refreshed", detail: "Cache and visible package list are up to date.")
        } catch {
            errorMessage = error.localizedDescription
            appendLog(.error, "Refresh failed", detail: error.localizedDescription)
        }

        isLoading = false
        appendLog(.state, "Idle", detail: "No package operation is currently running.")
    }

    /// Upgrades every outdated Homebrew package, optionally performs a full
    /// cleanup, and refreshes the package cache afterward.
    ///
    /// Cleanup runs only after a successful upgrade. A cleanup failure is surfaced
    /// to the user but does not prevent the package list from reflecting upgrades
    /// that already completed.
    ///
    /// - Parameters:
    ///   - cleanupAfterUpgrade: Whether to run `brew cleanup` after upgrading.
    ///   - context: SwiftData model context used by the follow-up refresh.
    func upgradeAll(cleanupAfterUpgrade: Bool, from context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        currentCommandProgress = "Updating Homebrew metadata"
        appendLog(.state, "Updating Homebrew", detail: "Fetching the latest Homebrew and formula metadata before upgrading.")
        appendLog(.command, "Executing command", detail: "brew update")

        do {
            try await service.updateHomebrew(disablesTapTrustChecks: disablesTapTrustChecks)
            appendLog(.success, "Homebrew update completed", detail: "Homebrew and formula metadata are up to date.")
        } catch {
            currentCommandProgress = nil
            errorMessage = error.localizedDescription
            appendLog(.error, "Homebrew update failed", detail: error.localizedDescription)
            isLoading = false
            appendLog(.state, "Idle", detail: "Upgrade all was stopped before package changes began.")
            return
        }

        currentCommandProgress = "Preparing Homebrew upgrade"
        appendLog(.state, "Starting upgrade all", detail: "Upgrading all outdated, unpinned Homebrew packages.")
        appendLog(.command, "Executing command", detail: "brew upgrade --no-ask")

        let progressSessionID = UUID()
        activeProgressSessionID = progressSessionID

        do {
            try await service.upgradeAll(disablesTapTrustChecks: disablesTapTrustChecks) { [weak self] message in
                guard let self, activeProgressSessionID == progressSessionID else { return }
                currentCommandProgress = message
            }
            activeProgressSessionID = nil
            appendLog(.success, "Upgrade all completed", detail: "All available package upgrades finished.")
        } catch {
            activeProgressSessionID = nil
            currentCommandProgress = nil
            errorMessage = error.localizedDescription
            appendLog(.error, "Upgrade all failed", detail: error.localizedDescription)
            isLoading = false
            appendLog(.state, "Idle", detail: "No package operation is currently running.")
            return
        }

        var cleanupErrorMessage: String?
        if cleanupAfterUpgrade {
            currentCommandProgress = "Cleaning up Homebrew"
            appendLog(.state, "Starting cleanup", detail: "Removing outdated versions and stale cache files.")
            appendLog(.command, "Executing command", detail: "brew cleanup")

            do {
                try await service.cleanup(disablesTapTrustChecks: disablesTapTrustChecks)
                appendLog(.success, "Cleanup completed", detail: "Homebrew cleanup finished.")
            } catch {
                cleanupErrorMessage = error.localizedDescription
                appendLog(.error, "Cleanup failed", detail: error.localizedDescription)
            }
        } else {
            appendLog(.info, "Cleanup skipped", detail: "The cleanup-after-upgrade preference is disabled.")
        }

        currentCommandProgress = "Refreshing installed packages"
        await refresh(from: context)
        currentCommandProgress = nil
        if errorMessage == nil, let cleanupErrorMessage {
            errorMessage = cleanupErrorMessage
        }
    }

    /// Performs a package-level action through the service and refreshes state.
    ///
    /// - Parameters:
    ///   - action: User-selected package action from the detail pane.
    ///   - package: Package that should receive the action.
    ///   - context: SwiftData model context used by the follow-up refresh.
    func perform(_ action: PackageAction, package: InstalledPackageDTO, context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        appendLog(.state, "Starting \(action.title.lowercased())", detail: "Package: \(package.name)")
        appendLog(.command, "Executing command", detail: command(for: action, package: package))

        do {
            switch action {
            case .upgrade:
                try await service.update(
                    packageName: package.name,
                    version: nil,
                    disablesTapTrustChecks: disablesTapTrustChecks
                )
            case .reinstall:
                try await service.reinstall(
                    packageName: package.name,
                    force: false,
                    disablesTapTrustChecks: disablesTapTrustChecks
                )
            case .forceReinstall:
                try await service.reinstall(
                    packageName: package.name,
                    force: true,
                    disablesTapTrustChecks: disablesTapTrustChecks
                )
            case .delete:
                try await service.delete(
                    packageName: package.name,
                    disablesTapTrustChecks: disablesTapTrustChecks
                )
            }
            appendLog(.success, "\(action.title) completed", detail: "Refreshing package list after \(package.name).")
            await refresh(from: context)
        } catch {
            errorMessage = error.localizedDescription
            appendLog(.error, "\(action.title) failed", detail: error.localizedDescription)
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
        appendLog(.state, "Starting \(action.title.lowercased())", detail: "Package: \(package.name), version: \(version.version)")
        appendLog(.command, "Executing command", detail: command(for: action, package: package, version: version))

        do {
            switch action {
            case .delete:
                try await service.deleteVersion(
                    packageName: package.name,
                    version: version.version,
                    disablesTapTrustChecks: disablesTapTrustChecks
                )
            case .makeActive:
                try await service.makeVersionActive(
                    packageName: package.name,
                    version: version.version,
                    disablesTapTrustChecks: disablesTapTrustChecks
                )
            case .update:
                try await service.update(
                    packageName: package.name,
                    version: version.version,
                    disablesTapTrustChecks: disablesTapTrustChecks
                )
            }
            appendLog(.success, "\(action.title) completed", detail: "Refreshing package list after \(package.name) \(version.version).")
            await refresh(from: context)
        } catch {
            errorMessage = error.localizedDescription
            appendLog(.error, "\(action.title) failed", detail: error.localizedDescription)
        }

        isLoading = false
    }

    /// Encodes the current package list into the JSON export payload.
    ///
    /// The data is prepared here instead of inside `FileDocument` so encoding stays
    /// on the main actor with the observable state that owns the package snapshots.
    func prepareExport() {
        appendLog(.state, "Preparing export", detail: "Encoding \(packages.count) packages as JSON.")
        let payload = PackageExportDocumentPayload(exportedAt: .now, packageManager: "homebrew", packages: packages)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        exportData = try? encoder.encode(payload)

        if let exportData {
            appendLog(.success, "Export ready", detail: "Prepared \(exportData.count.formatted()) bytes of JSON.")
        } else {
            appendLog(.error, "Export failed", detail: "The package list could not be encoded as JSON.")
        }
    }

    /// Removes all current log entries.
    func clearLogs() {
        logs.removeAll()
        appendLog(.info, "Logs cleared")
    }

    /// Keeps the selected package pointed at a visible package after filtering or refresh changes.
    func repairSelection() {
        if let selectedPackageID, filteredPackages.contains(where: { $0.id == selectedPackageID }) {
            return
        }

        selectedPackageID = filteredPackages.first?.id
        if let selectedPackageID {
            appendLog(.state, "Selection changed", detail: selectedPackageID)
        } else {
            appendLog(.warning, "No package selected", detail: "The current filter has no visible packages.")
        }
    }

    /// Appends one log row and trims older rows to keep memory bounded.
    func appendLog(_ level: PackageLogLevel, _ title: String, detail: String? = nil) {
        logs.append(PackageLogEntry(level: level, title: title, detail: detail))
        if logs.count > maximumLogCount {
            logs.removeFirst(logs.count - maximumLogCount)
        }
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
        appendLog(.state, "Updating local cache", detail: "Writing \(incomingPackages.count) package snapshots to SwiftData.")
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
                    installedSize: package.installedSize,
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
        appendLog(.success, "Local cache saved", detail: "SwiftData now mirrors the latest package list.")
    }

    /// User-facing command string for a package-level action.
    private func command(for action: PackageAction, package: InstalledPackageDTO) -> String {
        switch action {
        case .upgrade:
            "brew upgrade \(package.name)"
        case .reinstall:
            "brew reinstall \(package.name)"
        case .forceReinstall:
            "brew reinstall --force \(package.name)"
        case .delete:
            "brew uninstall \(package.name)"
        }
    }

    /// User-facing command string for a version-level action.
    private func command(for action: PackageVersionAction, package: InstalledPackageDTO, version: InstalledVersionDTO) -> String {
        switch action {
        case .delete:
            "brew uninstall \(package.name)@\(version.version)"
        case .makeActive:
            "brew link --overwrite \(package.name)@\(version.version)"
        case .update:
            "brew upgrade \(package.name)"
        }
    }
}
