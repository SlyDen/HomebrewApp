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
    @Bindable var library: PackageLibrary
    @State private var isExporting = false
    @State private var exportDocument = PackageExportDocument()

    /// View body containing the searchable package list and detail pane.
    var body: some View {
        NavigationSplitView {
            List(library.filteredPackages, selection: $library.selectedPackageID) { package in
                PackageRow(package: package)
                    .tag(package.id)
            }
            .navigationTitle("Homebrew")
            .navigationSplitViewColumnWidth(min: 240, ideal: 300, max: 360)
            .searchable(text: $library.searchText, prompt: "Search packages")
            .overlay {
                if library.filteredPackages.isEmpty && !library.isLoading {
                    ContentUnavailableView(
                        "No Packages",
                        systemImage: "shippingbox",
                        description: Text("Refresh Homebrew or adjust the filter.")
                    )
                }
            }
            .toolbar {
                ToolbarItem {
                    KindFilterMenu(selectedKind: $library.selectedKind)
                }

                ToolbarItemGroup {
                    Button {
                        library.isLogPanelPresented.toggle()
                    } label: {
                        Label(library.isLogPanelPresented ? "Hide Logs" : "Show Logs", systemImage: library.isLogPanelPresented ? "rectangle.bottomthird.inset.filled" : "rectangle.bottomthird.inset.filled.badge.plus")
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
                    .disabled(library.packages.isEmpty)

                    Button {
                        Task { await library.refresh(from: modelContext) }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(library.isLoading)
                }
            }
        } detail: {
            if let package = library.selectedPackage {
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
        .task {
            do {
                try library.loadCachedPackages(from: modelContext)
            } catch {
                library.errorMessage = error.localizedDescription
                library.appendLog(.error, "Cache load failed", detail: error.localizedDescription)
            }

            if library.packages.isEmpty {
                await library.refresh(from: modelContext)
            }
        }
        .onChange(of: library.searchText) { _, _ in
            library.repairSelection()
        }
        .onChange(of: library.selectedKind) { _, _ in
            library.repairSelection()
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
}

/// Compact row for a package in the main list.
private struct PackageRow: View {
    /// Package snapshot rendered by the row.
    let package: InstalledPackageDTO

    /// Row body with package category icon, name, summary, and version count.
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(package.name)
                    .font(.headline)
                Text(package.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text("\(package.installedVersions.count) version\(package.installedVersions.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: package.kind.systemImage)
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Toolbar menu for filtering package results by kind.
private struct KindFilterMenu: View {
    /// Currently selected package kind, or `nil` for all packages.
    @Binding var selectedKind: ManagedPackageKind?

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
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}

/// Bottom panel for detailed package operation logs.
private struct PackageLogPanel: View {
    /// Shared package library that owns log state.
    @Bindable var library: PackageLibrary

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
                            }
                        }
                    }
                    .padding(12)
                }
                .frame(minHeight: 160, idealHeight: 220, maxHeight: 280)
                .background(Color.black.opacity(0.88))
                .onChange(of: library.logs.count) { _, _ in
                    if let lastID = library.logs.last?.id {
                        withAnimation(.easeOut(duration: 0.2)) {
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

            CapsuleStatus(level: statusLevel, text: statusText)

            if let latestEntry {
                Text(latestEntry.title)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let detail = latestEntry.detail {
                    Text(detail)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(latestEntry.level.foregroundColor)
                        .lineLimit(1)
                }
            } else {
                Text("No package activity yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

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
        if library.isLoading { return "Running" }
        if library.errorMessage != nil { return "Failed" }
        return "Idle"
    }

    /// Color level for the current status.
    private var statusLevel: PackageLogLevel {
        if library.isLoading { return .command }
        if library.errorMessage != nil { return .error }
        return .success
    }
}

/// Small colored status capsule used by the console dock.
private struct CapsuleStatus: View {
    /// Log level controlling color.
    let level: PackageLogLevel

    /// Status text.
    let text: String

    /// Capsule body.
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(level.foregroundColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(level.backgroundColor, in: Capsule())
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

            Label(entry.level.title, systemImage: entry.level.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(entry.level.foregroundColor)
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(entry.level.backgroundColor, in: Capsule())
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

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(entry.level.rowBackgroundColor, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
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
    PackageListView(library: PackageLibrary(service: MockHomebrewService()))
        .modelContainer(for: [BrewPackage.self, BrewVersion.self], inMemory: true)
}
