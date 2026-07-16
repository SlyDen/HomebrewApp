import SwiftUI

/// Runtime and build dependencies declared by a formula.
struct FormulaDependenciesSection: View {
    let dependencies: [String]
    let buildDependencies: [String]

    /// Dependency lists with distinct runtime and build labels.
    var body: some View {
        Section("Dependencies") {
            ForEach(dependencies, id: \.self) { dependency in
                Label(dependency, systemImage: "shippingbox")
            }

            ForEach(buildDependencies, id: \.self) { dependency in
                Label(dependency, systemImage: "hammer")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
