import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Main browser view showing installed packages.
///
/// The view displays cached packages immediately, refreshes from Homebrew when no
/// cache is available, and provides filtering, search, refresh, and JSON export
/// controls through native SwiftUI toolbars.
struct PackageListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var library: PackageLibrary
    @State private var isExporting = false
    @State private var exportDocument = PackageExportDocument()

    /// View body containing the searchable package list and navigation stack.
    var body: some View {
        NavigationStack {
            List(library.filteredPackages) { package in
                NavigationLink(value: package.id) {
                    PackageRow(package: package)
                }
            }
            .navigationTitle("Homebrew")
            .navigationDestination(for: InstalledPackageDTO.ID.self) { packageID in
                if let package = library.packages.first(where: { $0.id == packageID }) {
                    PackageDetailView(package: package, library: library)
                } else {
                    ContentUnavailableView("Package Not Found", systemImage: "shippingbox", description: Text("Refresh the list and try again."))
                }
            }
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
            .safeAreaInset(edge: .bottom) {
                if library.isLoading || library.errorMessage != nil {
                    StatusBar(isLoading: library.isLoading, message: library.errorMessage)
                }
            }
            .task {
                do {
                    try library.loadCachedPackages(from: modelContext)
                } catch {
                    library.errorMessage = error.localizedDescription
                }

                if library.packages.isEmpty {
                    await library.refresh(from: modelContext)
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "homebrew-packages.json"
            ) { result in
                if case .failure(let error) = result {
                    library.errorMessage = error.localizedDescription
                }
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
                Text("Refreshing packages")
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

#Preview {
    PackageListView(library: PackageLibrary(service: MockHomebrewService()))
        .modelContainer(for: [BrewPackage.self, BrewVersion.self], inMemory: true)
}
