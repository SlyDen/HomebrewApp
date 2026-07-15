import SwiftUI

/// Shared keys for app-level preferences stored in UserDefaults.
enum AppPreferenceKeys {
    static let appearancePreference = "appearancePreference"
    static let isHomebrewProviderEnabled = "isHomebrewProviderEnabled"
}

/// Xcode-style app settings window with toolbar tabs for preference groups.
struct AppSettingsView: View {
    @AppStorage(AppPreferenceKeys.appearancePreference) private var appearancePreferenceRawValue = AppearancePreference.system.rawValue
    @AppStorage(AppPreferenceKeys.isHomebrewProviderEnabled) private var isHomebrewProviderEnabled = true

    /// Settings window body grouped into native macOS preference tabs.
    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                GeneralSettingsPane(appearancePreference: appearancePreferenceBinding)
            }

            Tab("Providers", systemImage: "shippingbox") {
                ProvidersSettingsPane(isHomebrewProviderEnabled: $isHomebrewProviderEnabled)
            }
        }
        .scenePadding()
        .frame(width: 660, height: 520)
        .appAppearance(appearancePreference)
    }

    /// Current appearance preference decoded from persisted storage.
    private var appearancePreference: AppearancePreference {
        AppearancePreference(rawValue: appearancePreferenceRawValue) ?? .system
    }

    /// Binding that keeps the settings picker, storage, and active windows in sync.
    private var appearancePreferenceBinding: Binding<AppearancePreference> {
        Binding {
            appearancePreference
        } set: { newPreference in
            appearancePreferenceRawValue = newPreference.rawValue
            newPreference.apply()
        }
    }
}

/// General app preferences.
private struct GeneralSettingsPane: View {
    @Binding var appearancePreference: AppearancePreference

    private let columns = [
        GridItem(.fixed(112), spacing: 14),
        GridItem(.fixed(112), spacing: 14),
        GridItem(.fixed(112), spacing: 14)
    ]

    var body: some View {
        Form {
            Section("Appearance") {
                HStack(spacing: 14) {
                    ForEach(AppearancePreference.appearanceChoices) { preference in
                        ThemeOptionButton(
                            preference: preference,
                            isSelected: appearancePreference == preference
                        ) {
                            appearancePreference = preference
                            preference.apply()
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Presets") {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                    ForEach(AppearancePreference.presetThemes) { preference in
                        ThemeOptionButton(
                            preference: preference,
                            isSelected: appearancePreference == preference
                        ) {
                            appearancePreference = preference
                            preference.apply()
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
    }
}

/// Visual theme option styled like Xcode's Settings theme choices.
private struct ThemeOptionButton: View {
    let preference: AppearancePreference
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ThemePreview(preference: preference)
                    .frame(width: 92, height: 62)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isSelected ? Color.accentColor : .secondary.opacity(0.28), lineWidth: isSelected ? 3 : 1)
                    }
                    .shadow(color: .black.opacity(isSelected ? 0.18 : 0.08), radius: isSelected ? 5 : 2, y: 1)
                    .overlay(alignment: .bottomTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, Color.accentColor)
                                .font(.system(size: 17, weight: .semibold))
                                .padding(5)
                        }
                    }

                Label(preference.title, systemImage: preference.systemImage)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(width: 112)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Theme: \(preference.title)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Small static preview of the app chrome under an appearance preference.
private struct ThemePreview: View {
    let preference: AppearancePreference

    var body: some View {
        GeometryReader { geometry in
            let sidebarWidth = geometry.size.width * 0.34
            let palette = preference.palette

            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    palette.sidebar
                        .frame(width: sidebarWidth)

                    palette.editor
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 4) {
                        Circle().fill(.red).frame(width: 6, height: 6)
                        Circle().fill(.yellow).frame(width: 6, height: 6)
                        Circle().fill(.green).frame(width: 6, height: 6)
                    }

                    HStack(spacing: 6) {
                        VStack(alignment: .leading, spacing: 4) {
                            Capsule().fill(palette.secondaryLine).frame(width: 18, height: 4)
                            Capsule().fill(palette.secondaryLine).frame(width: 24, height: 4)
                            Capsule().fill(palette.accent.opacity(0.75)).frame(width: 20, height: 4)
                        }
                        .frame(width: sidebarWidth - 12, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Capsule().fill(palette.primaryLine).frame(width: 42, height: 5)
                            Capsule().fill(palette.highlight).frame(width: 28, height: 4)
                            Capsule().fill(palette.secondaryLine).frame(width: 35, height: 4)
                            Capsule().fill(palette.accent).frame(width: 52, height: 5)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(8)
            }
            .background(palette.editor)
        }
    }
}

/// Package provider preferences.
private struct ProvidersSettingsPane: View {
    @Binding var isHomebrewProviderEnabled: Bool

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $isHomebrewProviderEnabled) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Homebrew")
                        Text("Use Homebrew as an active package provider.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    AppSettingsView()
}
