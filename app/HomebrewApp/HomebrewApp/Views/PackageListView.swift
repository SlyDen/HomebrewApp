import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Main browser view showing installed packages.
///
/// The view displays cached packages immediately, refreshes from Homebrew when no
/// cache is available, and provides filtering, search, refresh, JSON export, and
/// execution log controls through native SwiftUI toolbars.
struct PackageListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appAppearancePreference) private var appearancePreference
    @Bindable var library: PackageLibrary
    @Binding var isHomebrewProviderEnabled: Bool
    let cleanupAfterUpgrade: Bool
    let disablesTapTrustChecks: Bool
    @State private var isExporting = false
    @State private var exportDocument = PackageExportDocument()

    /// View body containing the searchable package list and detail pane.
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack {
                    Button("Upgrade All", systemImage: "arrow.up.circle") {
                        upgradeAllPackages()
                    }
                    .disabled(library.isLoading || !isHomebrewProviderEnabled)

                    Button {
                        refreshPackages()
                    } label: {
                        Label(library.isLoading ? "Refreshing" : "Refresh Packages", systemImage: "arrow.clockwise")
                    }
                    .disabled(library.isLoading || !isHomebrewProviderEnabled)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                List(displayedPackages, selection: $library.selectedPackageID) { package in
                    PackageRow(package: package)
                        .tag(package.id)
                        .listRowBackground(appearancePreference.palette.sidebar.opacity(0.62))
                }
                .scrollContentBackground(.hidden)
                .background(appearancePreference.palette.sidebar)
            }
            .background(appearancePreference.palette.sidebar)
            .navigationTitle("Homebrew")
            .navigationSplitViewColumnWidth(min: 360, ideal: 460, max: 560)
            .searchable(text: $library.searchText, prompt: "Search packages")
            .overlay {
                if !isHomebrewProviderEnabled {
                    ContentUnavailableView(
                        "No Active Providers",
                        systemImage: "shippingbox.circle",
                        description: Text("Enable Homebrew in Settings to refresh package data.")
                    )
                } else if displayedPackages.isEmpty && !library.isLoading {
                    ContentUnavailableView(
                        "No Packages",
                        systemImage: "shippingbox",
                        description: Text("Refresh Homebrew or adjust the filter.")
                    )
                }
            }
            .toolbar {
                ToolbarItem {
                    KindFilterMenu(
                        selectedKind: $library.selectedKind,
                        showsOnlyMultipleVersions: $library.showsOnlyMultipleVersions
                    )
                }

                ToolbarItem {
                    PackageSortMenu(sortOption: $library.sortOption)
                }

                ToolbarItemGroup {
                    Button {
                        library.isLogPanelPresented.toggle()
                    } label: {
                        Label(library.isLogPanelPresented ? "Hide Logs" : "Show Logs", systemImage: library.isLogPanelPresented ? "rectangle.bottomthird.inset.filled" : "rectangle.bottomthird.inset.filled")
                    }

                    Button {
                        library.prepareExport()
                        if let data = library.exportData {
                            exportDocument = PackageExportDocument(data: data)
                            isExporting = true
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(displayedPackages.isEmpty)

                    Button {
                        refreshPackages()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(library.isLoading || !isHomebrewProviderEnabled)
                }
            }
        } detail: {
            if let package = selectedPackage {
                PackageDetailView(package: package, library: library)
                    .navigationSplitViewColumnWidth(min: 420, ideal: 760)
            } else {
                ContentUnavailableView(
                    "Select a Package",
                    systemImage: "shippingbox",
                    description: Text("Choose a package from the list to view details and actions.")
                )
                .navigationSplitViewColumnWidth(min: 420, ideal: 760)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if library.isLogPanelPresented {
                    PackageLogPanel(library: library)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                ConsoleDockBar(library: library)
            }
            .animation(.easeInOut(duration: 0.18), value: library.isLogPanelPresented)
        }
        .focusedSceneValue(
            \.refreshPackagesAction,
            RefreshPackagesAction(isDisabled: library.isLoading || !isHomebrewProviderEnabled) {
                refreshPackages()
            }
        )
        .focusedSceneValue(
            \.upgradeAllPackagesAction,
            UpgradeAllPackagesAction(isDisabled: library.isLoading || !isHomebrewProviderEnabled) {
                upgradeAllPackages()
            }
        )
        .task {
            library.disablesTapTrustChecks = disablesTapTrustChecks

            do {
                try library.loadCachedPackages(from: modelContext)
            } catch {
                library.errorMessage = error.localizedDescription
                library.appendLog(.error, "Cache load failed", detail: error.localizedDescription)
            }

            let needsMetadataRefresh = library.packages.isEmpty
                || library.packages.allSatisfy { $0.installedSize == nil }
            if needsMetadataRefresh && isHomebrewProviderEnabled {
                await library.refresh(from: modelContext)
            }
        }
        .onChange(of: library.searchText) { _, _ in
            library.repairSelection()
        }
        .onChange(of: library.selectedKind) { _, _ in
            library.repairSelection()
        }
        .onChange(of: library.showsOnlyMultipleVersions) { _, _ in
            library.repairSelection()
        }
        .onChange(of: isHomebrewProviderEnabled) { _, isEnabled in
            if isEnabled {
                library.repairSelection()
            }
        }
        .onChange(of: disablesTapTrustChecks) { _, isDisabled in
            library.disablesTapTrustChecks = isDisabled
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "homebrew-packages.json"
        ) { result in
            if case .failure(let error) = result {
                library.errorMessage = error.localizedDescription
                library.appendLog(.error, "Export failed", detail: error.localizedDescription)
            }
        }
    }

    /// Packages visible for currently active providers.
    private var displayedPackages: [InstalledPackageDTO] {
        isHomebrewProviderEnabled ? library.filteredPackages : []
    }

    /// Selected package constrained to active providers.
    private var selectedPackage: InstalledPackageDTO? {
        isHomebrewProviderEnabled ? library.selectedPackage : nil
    }

    /// Starts a manual refresh using the active SwiftData context.
    private func refreshPackages() {
        guard isHomebrewProviderEnabled else { return }
        Task { await library.refresh(from: modelContext) }
    }

    /// Starts a bulk upgrade using the active cleanup preference.
    private func upgradeAllPackages() {
        guard isHomebrewProviderEnabled else { return }
        Task {
            await library.upgradeAll(
                cleanupAfterUpgrade: cleanupAfterUpgrade,
                from: modelContext
            )
        }
    }
}

/// Toolbar menu for filtering package results.
private struct KindFilterMenu: View {
    /// Currently selected package kind, or `nil` for all packages.
    @Binding var selectedKind: ManagedPackageKind?

    /// Whether only packages with more than one installed version are shown.
    @Binding var showsOnlyMultipleVersions: Bool

    /// Filter menu body.
    var body: some View {
        Menu {
            Button {
                selectedKind = nil
            } label: {
                Label("All", systemImage: selectedKind == nil ? "checkmark" : "line.3.horizontal.decrease.circle")
            }

            ForEach(ManagedPackageKind.allCases) { kind in
                Button {
                    selectedKind = kind
                } label: {
                    Label(kind.title, systemImage: selectedKind == kind ? "checkmark" : kind.systemImage)
                }
            }

            Divider()

            Toggle(isOn: $showsOnlyMultipleVersions) {
                Label("Multiple Versions", systemImage: "square.stack.3d.up")
            }
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}

/// Bottom panel for detailed package operation logs.
private struct PackageLogPanel: View {
    /// Shared package library that owns log state.
    @Bindable var library: PackageLibrary

    /// System preference used to disable log entrance and scrolling motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Panel body with a header and auto-scrolling log output.
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Label("Logs", systemImage: "terminal")
                    .font(.headline)

                Text("\(library.logs.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.secondary.opacity(0.14), in: Capsule())

                Spacer(minLength: 0)

                Button {
                    library.clearLogs()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(library.logs.isEmpty)

                Button {
                    library.isLogPanelPresented = false
                } label: {
                    Label("Hide", systemImage: "chevron.down")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.bar)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if library.logs.isEmpty {
                            ContentUnavailableView("No Logs", systemImage: "terminal", description: Text("Package activity will appear here."))
                                .frame(maxWidth: .infinity, minHeight: 150)
                        } else {
                            ForEach(library.logs) { entry in
                                PackageLogRow(entry: entry)
                                    .id(entry.id)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(12)
                    .animation(reduceMotion ? nil : .snappy, value: library.logs.count)
                }
                .frame(minHeight: 160, idealHeight: 220, maxHeight: 280)
                .background(Color.black.opacity(0.88))
                .onChange(of: library.logs.count) { _, _ in
                    if let lastID = library.logs.last?.id {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

/// Always-visible bottom dock that opens and summarizes the execution log.
private struct ConsoleDockBar: View {
    /// Shared package library that owns log state.
    @Bindable var library: PackageLibrary

    /// Most recent log entry, if any.
    private var latestEntry: PackageLogEntry? {
        library.logs.last
    }

    /// Number of warning entries currently retained.
    private var warningCount: Int {
        library.logs.filter { $0.level == .warning }.count
    }

    /// Number of error entries currently retained.
    private var errorCount: Int {
        library.logs.filter { $0.level == .error }.count
    }

    /// Dock body styled like a compact debug area strip.
    var body: some View {
        HStack(spacing: 12) {
            Button {
                library.isLogPanelPresented.toggle()
            } label: {
                Image(systemName: library.isLogPanelPresented ? "chevron.down" : "chevron.up")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderless)
            .help(library.isLogPanelPresented ? "Hide logs" : "Show logs")

            Label("Console", systemImage: "terminal")
                .font(.headline)

            CapsuleStatus(level: statusLevel, text: statusText, isActive: library.isLoading)

            ConsoleActivitySummary(
                title: activityTitle,
                detail: activityDetail,
                detailColor: activityDetailColor
            )
            .layoutPriority(-1)

            LevelCounter(level: .warning, count: warningCount)
            LevelCounter(level: .error, count: errorCount)

            Text("\(library.logs.count) logs")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Button {
                library.clearLogs()
            } label: {
                Image(systemName: "trash")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderless)
            .disabled(library.logs.isEmpty)
            .help("Clear logs")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    /// Current package operation status shown in the dock.
    private var statusText: String {
        if library.currentCommandProgress?.hasPrefix("Waiting for administrator password") == true {
            return "Password Required"
        }
        if library.isLoading { return "Running" }
        if library.errorMessage != nil { return "Failed" }
        return "Idle"
    }

    /// Color level for the current status.
    private var statusLevel: PackageLogLevel {
        if library.currentCommandProgress?.hasPrefix("Waiting for administrator password") == true {
            return .warning
        }
        if library.isLoading { return .command }
        if library.errorMessage != nil { return .error }
        return .success
    }

    /// Short label describing the active command or most recent log entry.
    private var activityTitle: String {
        if library.isLoading, library.currentCommandProgress != nil {
            return "Current operation"
        }
        return latestEntry?.title ?? "No package activity yet"
    }

    /// Detail allowed to truncate without contributing to the window's minimum width.
    private var activityDetail: String? {
        if library.isLoading, let currentCommandProgress = library.currentCommandProgress {
            return currentCommandProgress
        }
        return latestEntry?.detail
    }

    /// Color associated with the active command or most recent log entry.
    private var activityDetailColor: Color {
        if library.isLoading {
            return statusLevel.foregroundColor
        }
        return latestEntry?.level.foregroundColor ?? .secondary
    }
}

/// Small colored status capsule used by the console dock.
private struct CapsuleStatus: View {
    /// Log level controlling color.
    let level: PackageLogLevel

    /// Status text.
    let text: String

    /// Whether to show indeterminate activity beside the status text.
    let isActive: Bool

    /// System preference used to avoid custom transition motion.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Capsule body.
    var body: some View {
        HStack(spacing: 5) {
            if isActive {
                ProgressView()
                    .controlSize(.mini)
                    .tint(level.foregroundColor)
                    .transition(.scale.combined(with: .opacity))
            }

            Text(text)
                .contentTransition(.opacity)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(level.foregroundColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(level.backgroundColor, in: Capsule())
        .animation(reduceMotion ? nil : .snappy, value: isActive)
        .animation(reduceMotion ? nil : .snappy, value: text)
    }
}

/// Compact warning/error count shown in the console dock.
private struct LevelCounter: View {
    /// Log level represented by the counter.
    let level: PackageLogLevel

    /// Current count for the level.
    let count: Int

    /// Counter body.
    var body: some View {
        Label(count.formatted(), systemImage: level.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(count == 0 ? .secondary : level.foregroundColor)
            .labelStyle(.titleAndIcon)
            .accessibilityLabel("\(level.title): \(count)")
    }
}

/// One colorful log row.
private struct PackageLogRow: View {
    /// Log entry to render.
    let entry: PackageLogEntry

    /// Time-only timestamp for compact log rows.
    private var timestamp: String {
        entry.timestamp.formatted(date: .omitted, time: .standard)
    }

    /// Row body with timestamp, colored level badge, title, and optional detail text.
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(timestamp)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.58))
                .frame(width: 82, alignment: .leading)

            AnimatedLogLevelBadge(level: entry.level)
                .frame(width: 104, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.system(.callout, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.white)

                if let detail = entry.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(entry.level.detailColor)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(entry.level.rowBackgroundColor, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

/// Log-level capsule that gently appears as a new row enters the panel.
private struct AnimatedLogLevelBadge: View {
    /// Level controlling the icon, label, and color.
    let level: PackageLogLevel

    /// Whether the badge has completed its entrance transition.
    @State private var isPresented = false

    /// System preference used to disable the custom entrance animation.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Animated badge body.
    var body: some View {
        Label(level.title, systemImage: level.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(level.foregroundColor)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(level.backgroundColor, in: Capsule())
            .scaleEffect(isPresented ? 1 : 0.86)
            .opacity(isPresented ? 1 : 0)
            .onAppear {
                if reduceMotion {
                    isPresented = true
                } else {
                    withAnimation(.snappy) {
                        isPresented = true
                    }
                }
            }
    }
}

/// Bottom status bar for refresh progress and service errors.
private struct StatusBar: View {
    /// Whether a package operation is currently running.
    let isLoading: Bool

    /// Optional user-facing error message.
    let message: String?

    /// Status row body.
    var body: some View {
        HStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                Text("Working with packages")
            } else if let message {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(message)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)
        }
        .font(.footnote)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

private extension PackageLogLevel {
    /// Primary text color for the level badge.
    var foregroundColor: Color {
        switch self {
        case .info: .cyan
        case .state: .teal
        case .command: .purple
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }

    /// Detail text color for the row body.
    var detailColor: Color {
        switch self {
        case .info: .cyan.opacity(0.82)
        case .state: .teal.opacity(0.82)
        case .command: .purple.opacity(0.9)
        case .success: .green.opacity(0.82)
        case .warning: .orange.opacity(0.9)
        case .error: .red.opacity(0.9)
        }
    }

    /// Badge background color.
    var backgroundColor: Color {
        foregroundColor.opacity(0.18)
    }

    /// Row background color.
    var rowBackgroundColor: Color {
        foregroundColor.opacity(0.08)
    }
}

#Preview {
    PackageListView(
        library: PackageLibrary(service: MockHomebrewService()),
        isHomebrewProviderEnabled: .constant(true),
        cleanupAfterUpgrade: true,
        disablesTapTrustChecks: false
    )
        .modelContainer(for: [BrewPackage.self, BrewVersion.self], inMemory: true)
}
