import SwiftUI

/// Compact installed package metadata shown in the main sidebar.
struct PackageRow: View {
    let package: InstalledPackageDTO

    /// Package category, summary, size, update date, and installed version count.
    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(package.name)
                    .font(.headline)

                Text(package.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack {
                    if let installedSize = package.installedSize {
                        Label {
                            Text(installedSize, format: .byteCount(style: .file))
                        } icon: {
                            Image(systemName: "internaldrive")
                        }
                    }

                    Label {
                        Text(
                            "Updated \(package.updatedOn, format: .dateTime.year().month().day())",
                            comment: "Package metadata followed by the most recent install or upgrade date."
                        )
                    } icon: {
                        Image(systemName: "calendar")
                    }

                    if package.installedVersions.count == 1 {
                        Text("1 version")
                    } else {
                        Text("\(package.installedVersions.count) versions")
                    }
                }
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
