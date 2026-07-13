import SwiftData
import SwiftUI

/// Detail view for a selected package.
///
/// The detail panel shows package metadata, installed version tags, and a small
/// details section. Version tags expose actions through menus and delegate those
/// actions back to `PackageLibrary`.
struct PackageDetailView: View {
    @Environment(\.modelContext) private var modelContext

    /// Package snapshot displayed by this detail panel.
    let package: InstalledPackageDTO

    /// Shared observable package library used to perform version actions.
    @Bindable var library: PackageLibrary

    /// Formatted package install date for the details section.
    private var installedDate: String {
        package.installedOn.formatted(date: .abbreviated, time: .omitted)
    }

    /// Detail list body.
    var body: some View {
        List {
            Section {
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

                    if let homepage = package.homepage {
                        Link(destination: homepage) {
                            Label(homepage.host() ?? homepage.absoluteString, systemImage: "safari")
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Installed Versions") {
                FlowLayout(spacing: 8) {
                    ForEach(package.installedVersions) { version in
                        VersionTag(package: package, version: version, library: library)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Details") {
                LabeledContent("Installed", value: installedDate)
                LabeledContent("Identifier", value: package.id)
            }
        }
        .navigationTitle(package.name)
    }
}

/// Menu-backed version tag shown in a package detail panel.
private struct VersionTag: View {
    @Environment(\.modelContext) private var modelContext

    /// Package that owns the version.
    let package: InstalledPackageDTO

    /// Version represented by this tag.
    let version: InstalledVersionDTO

    /// Shared package library used to perform selected actions.
    @Bindable var library: PackageLibrary

    /// Version tag menu body.
    var body: some View {
        Menu {
            Button {
                Task { await library.perform(.makeActive, package: package, version: version, context: modelContext) }
            } label: {
                Label(PackageVersionAction.makeActive.title, systemImage: PackageVersionAction.makeActive.systemImage)
            }
            .disabled(version.isActive)

            Button {
                Task { await library.perform(.update, package: package, version: version, context: modelContext) }
            } label: {
                Label(PackageVersionAction.update.title, systemImage: PackageVersionAction.update.systemImage)
            }

            Button(role: .destructive) {
                Task { await library.perform(.delete, package: package, version: version, context: modelContext) }
            } label: {
                Label(PackageVersionAction.delete.title, systemImage: PackageVersionAction.delete.systemImage)
            }
        } label: {
            Label {
                Text(version.version)
                    .font(.callout.weight(.medium))
            } icon: {
                if version.isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(version.isActive ? Color.green.opacity(0.12) : Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(version.isActive ? "Version \(version.version), active" : "Version \(version.version)")
        .accessibilityHint("Shows version actions")
    }
}

/// Simple wrapping layout used for version tags.
///
/// SwiftUI stacks do not wrap content by default. This layout measures each tag
/// and places it on the current row until it would exceed the available width,
/// then starts a new row.
private struct FlowLayout: Layout {
    /// Horizontal and vertical spacing between subviews.
    var spacing: CGFloat = 8

    /// Calculates the total size required for all wrapped rows.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 320
        var rows: [CGSize] = [CGSize(width: 0, height: 0)]

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rows[rows.count - 1].width + size.width + spacing > maxWidth, rows[rows.count - 1].width > 0 {
                rows.append(CGSize(width: 0, height: 0))
            }

            rows[rows.count - 1].width += rows[rows.count - 1].width == 0 ? size.width : size.width + spacing
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
        }

        return CGSize(width: maxWidth, height: rows.map(\.height).reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * spacing)
    }

    /// Places each subview into wrapped rows within the provided bounds.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x > bounds.minX, origin.x + size.width > bounds.maxX {
                origin.x = bounds.minX
                origin.y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: origin, proposal: ProposedViewSize(size))
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
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
