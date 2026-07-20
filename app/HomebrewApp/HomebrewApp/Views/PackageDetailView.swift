import SwiftData
import SwiftUI

/// Detail view for a selected package.
///
/// The detail panel shows package metadata, installed versions, and package or
/// version actions delegated back to `PackageLibrary`.
struct PackageDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appAppearancePreference) private var appearancePreference

    /// Package snapshot displayed by this detail panel.
    let package: InstalledPackageDTO

    /// Shared observable package library used to perform package actions.
    @Bindable var library: PackageLibrary

    /// Formatted package install date for the details section.
    private var installedDate: String {
        package.installedOn.formatted(date: .abbreviated, time: .shortened)
    }

    /// Detail list body.
    var body: some View {
        List {
            Section {
                PackageHeader(package: package)
                    .padding(.vertical, 8)
            }

            Section("Actions") {
                PackageActionButton(action: .upgrade, package: package, library: library)
                PackageActionButton(action: .reinstall, package: package, library: library)
                PackageActionButton(action: .forceReinstall, package: package, library: library)
                PackageActionButton(action: .delete, package: package, library: library)
            }

            Section("Installed Versions") {
                if package.installedVersions.isEmpty {
                    Text("No installed versions reported")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(package.installedVersions) { version in
                        VersionRow(package: package, version: version, library: library)
                    }
                }
            }

            Section("Details") {
                LabeledContent("Name", value: package.name)
                LabeledContent("Kind", value: package.kind.title)
                LabeledContent("Installed", value: installedDate)
                LabeledContent("Versions", value: package.installedVersions.count.formatted())
                LabeledContent("Identifier", value: package.id)

                if let homepage = package.homepage {
                    Link(destination: homepage) {
                        LabeledContent("Homepage", value: homepage.absoluteString)
                    }
                } else {
                    LabeledContent("Homepage", value: "Not reported")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(appearancePreference.palette.editor)
        .navigationTitle(package.name)
    }
}

/// Header content for the selected package detail pane.
private struct PackageHeader: View {
    /// Package snapshot rendered by the header.
    let package: InstalledPackageDTO

    /// Header body with package icon, name, kind, summary, and homepage link.
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.name)
                        .font(.title2.weight(.semibold))
                    Text(package.kind.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: package.kind.systemImage)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }

            Text(package.summary)
                .font(.body)
                .textSelection(.enabled)

            if let homepage = package.homepage {
                Link(destination: homepage) {
                    Label(homepage.host() ?? homepage.absoluteString, systemImage: "safari")
                }
            }
        }
    }
}

/// Button row for a whole-package action.
private struct PackageActionButton: View {
    @Environment(\.modelContext) private var modelContext

    /// Package-level action represented by this row.
    let action: PackageAction

    /// Package receiving the action.
    let package: InstalledPackageDTO

    /// Shared package library used to perform the selected action.
    @Bindable var library: PackageLibrary

    /// Action button body.
    var body: some View {
        Button(role: action == .delete ? .destructive : nil) {
            Task { await library.perform(action, package: package, context: modelContext) }
        } label: {
            Label(action.title, systemImage: action.systemImage)
        }
        .disabled(library.isLoading)
    }
}

/// Row showing one installed version and its available actions.
private struct VersionRow: View {
    @Environment(\.modelContext) private var modelContext

    /// Package that owns the version.
    let package: InstalledPackageDTO

    /// Version represented by this row.
    let version: InstalledVersionDTO

    /// Shared package library used to perform selected actions.
    @Bindable var library: PackageLibrary

    /// Optional formatted install date for this version.
    private var installedDate: String? {
        version.installedOn?.formatted(date: .abbreviated, time: .shortened)
    }

    /// Version row body.
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: version.isActive ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(version.isActive ? .green : .secondary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(version.version)
                    .font(.headline)
                    .textSelection(.enabled)

                HStack(spacing: 8) {
                    Text(version.isActive ? "Active" : "Installed")
                    if let installedDate {
                        Text(installedDate)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Menu {
                Button {
                    Task {
                        await library.perform(.makeActive, package: package, version: version, context: modelContext)
                    }
                } label: {
                    Label(
                        PackageVersionAction.makeActive.title,
                        systemImage: PackageVersionAction.makeActive.systemImage
                    )
                }
                .disabled(version.isActive || library.isLoading)

                Button {
                    Task {
                        await library.perform(.update, package: package, version: version, context: modelContext)
                    }
                } label: {
                    Label(PackageVersionAction.update.title, systemImage: PackageVersionAction.update.systemImage)
                }
                .disabled(library.isLoading)

                Button(role: .destructive) {
                    Task { await library.perform(.delete, package: package, version: version, context: modelContext) }
                } label: {
                    Label(PackageVersionAction.delete.title, systemImage: PackageVersionAction.delete.systemImage)
                }
                .disabled(library.isLoading)
            } label: {
                Label("Version Actions", systemImage: "ellipsis.circle")
                    .labelStyle(.iconOnly)
            }
            .menuStyle(.button)
            .accessibilityLabel("Actions for version \(version.version)")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(version.isActive ? "Version \(version.version), active" : "Version \(version.version)")
    }
}

#Preview {
    NavigationSplitView {
        List(selection: .constant("homebrew:formula:git")) {
            Text("git")
                .tag("homebrew:formula:git")
        }
    } detail: {
        PackageDetailView(
            package: InstalledPackageDTO(
                name: "git",
                kind: .formula,
                summary: "Distributed revision control system",
                homepage: URL(string: "https://git-scm.com"),
                installedVersions: [
                    InstalledVersionDTO(version: "2.50.1", isActive: true, installedOn: .now),
                    InstalledVersionDTO(version: "2.49.0", isActive: false, installedOn: .now)
                ],
                installedOn: .now
            ),
            library: PackageLibrary(service: MockHomebrewService())
        )
    }
    .modelContainer(for: [BrewPackage.self, BrewVersion.self], inMemory: true)
}
