import SwiftUI

#if os(macOS)
import AppKit
#endif

/// User-selectable app appearance mode persisted between launches.
enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    case standard
    case sakura
    case ember
    case sunrise
    case midnight
    case neonNoir
    case cobalt
    case coralReef
    case emerald

    var id: String { rawValue }

    /// System appearance choices shown before color theme presets.
    static let appearanceChoices: [AppearancePreference] = [.system, .light, .dark]

    /// Xcode-inspired color theme presets.
    static let presetThemes: [AppearancePreference] = [
        .standard,
        .sakura,
        .ember,
        .sunrise,
        .midnight,
        .neonNoir,
        .cobalt,
        .coralReef,
        .emerald
    ]

    /// SwiftUI color scheme override for platforms that use SwiftUI's environment directly.
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light, .sunrise:
            .light
        case .dark, .standard, .sakura, .ember, .midnight, .neonNoir, .cobalt, .coralReef, .emerald:
            .dark
        }
    }

    /// User-facing title for appearance controls.
    var title: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        case .standard:
            "Standard"
        case .sakura:
            "Sakura"
        case .ember:
            "Ember"
        case .sunrise:
            "Sunrise"
        case .midnight:
            "Midnight"
        case .neonNoir:
            "Neon Noir"
        case .cobalt:
            "Cobalt"
        case .coralReef:
            "Coral Reef"
        case .emerald:
            "Emerald"
        }
    }

    /// SF Symbol used by appearance controls.
    var systemImage: String {
        switch self {
        case .system:
            "circle.lefthalf.filled"
        case .light:
            "sun.max"
        case .dark:
            "moon"
        case .standard:
            "textformat"
        case .sakura:
            "camera.macro"
        case .ember:
            "flame"
        case .sunrise:
            "sunrise"
        case .midnight:
            "moon.stars"
        case .neonNoir:
            "sparkles"
        case .cobalt:
            "drop"
        case .coralReef:
            "water.waves"
        case .emerald:
            "leaf"
        }
    }

    /// Primary accent color for the selected theme.
    var accentColor: Color {
        palette.accent
    }

    /// Font design used to make preset themes feel distinct without sacrificing Dynamic Type.
    var fontDesign: Font.Design {
        switch self {
        case .standard, .dark, .midnight, .cobalt, .neonNoir:
            .monospaced
        case .sakura, .coralReef:
            .rounded
        case .ember, .sunrise, .emerald:
            .serif
        case .system, .light:
            .default
        }
    }

    /// Colors used by the settings preview tile.
    var palette: ThemePalette {
        switch self {
        case .system:
            ThemePalette(
                sidebar: Color(nsColor: .controlBackgroundColor),
                editor: Color(nsColor: .textBackgroundColor),
                primaryLine: .primary.opacity(0.72),
                secondaryLine: .secondary.opacity(0.45),
                accent: .accentColor,
                highlight: Color(red: 0.45, green: 0.69, blue: 1.0)
            )
        case .light:
            ThemePalette(
                sidebar: Color(red: 0.91, green: 0.93, blue: 0.96),
                editor: .white,
                primaryLine: Color(red: 0.18, green: 0.21, blue: 0.26),
                secondaryLine: Color(red: 0.48, green: 0.52, blue: 0.58),
                accent: Color(red: 0.0, green: 0.36, blue: 0.9),
                highlight: Color(red: 0.66, green: 0.81, blue: 1.0)
            )
        case .dark:
            ThemePalette(
                sidebar: Color(red: 0.15, green: 0.16, blue: 0.18),
                editor: Color(red: 0.10, green: 0.11, blue: 0.13),
                primaryLine: Color(red: 0.78, green: 0.81, blue: 0.87),
                secondaryLine: Color(red: 0.48, green: 0.52, blue: 0.59),
                accent: Color(red: 0.33, green: 0.62, blue: 1.0),
                highlight: Color(red: 0.24, green: 0.36, blue: 0.56)
            )
        case .standard:
            ThemePalette(
                sidebar: Color(red: 0.13, green: 0.15, blue: 0.18),
                editor: Color(red: 0.09, green: 0.11, blue: 0.14),
                primaryLine: Color(red: 0.92, green: 0.40, blue: 0.70),
                secondaryLine: Color(red: 0.50, green: 0.83, blue: 0.93),
                accent: Color(red: 0.22, green: 0.63, blue: 0.96),
                highlight: Color(red: 0.21, green: 0.29, blue: 0.39)
            )
        case .sakura:
            ThemePalette(
                sidebar: Color(red: 0.20, green: 0.07, blue: 0.20),
                editor: Color(red: 0.13, green: 0.06, blue: 0.14),
                primaryLine: Color(red: 1.0, green: 0.55, blue: 0.78),
                secondaryLine: Color(red: 0.93, green: 0.71, blue: 1.0),
                accent: Color(red: 0.95, green: 0.28, blue: 0.70),
                highlight: Color(red: 0.40, green: 0.13, blue: 0.33)
            )
        case .ember:
            ThemePalette(
                sidebar: Color(red: 0.25, green: 0.08, blue: 0.03),
                editor: Color(red: 0.15, green: 0.05, blue: 0.03),
                primaryLine: Color(red: 1.0, green: 0.58, blue: 0.35),
                secondaryLine: Color(red: 1.0, green: 0.80, blue: 0.54),
                accent: Color(red: 1.0, green: 0.35, blue: 0.18),
                highlight: Color(red: 0.42, green: 0.16, blue: 0.08)
            )
        case .sunrise:
            ThemePalette(
                sidebar: Color(red: 1.0, green: 0.91, blue: 0.73),
                editor: Color(red: 1.0, green: 0.97, blue: 0.89),
                primaryLine: Color(red: 0.87, green: 0.38, blue: 0.05),
                secondaryLine: Color(red: 0.55, green: 0.35, blue: 0.12),
                accent: Color(red: 0.96, green: 0.55, blue: 0.0),
                highlight: Color(red: 1.0, green: 0.82, blue: 0.42)
            )
        case .midnight:
            ThemePalette(
                sidebar: Color(red: 0.02, green: 0.18, blue: 0.25),
                editor: Color(red: 0.02, green: 0.10, blue: 0.16),
                primaryLine: Color(red: 0.58, green: 0.74, blue: 1.0),
                secondaryLine: Color(red: 0.43, green: 0.95, blue: 0.95),
                accent: Color(red: 0.00, green: 0.64, blue: 0.86),
                highlight: Color(red: 0.03, green: 0.29, blue: 0.39)
            )
        case .neonNoir:
            ThemePalette(
                sidebar: Color(red: 0.08, green: 0.08, blue: 0.27),
                editor: Color(red: 0.04, green: 0.05, blue: 0.16),
                primaryLine: Color(red: 0.77, green: 0.57, blue: 1.0),
                secondaryLine: Color(red: 0.53, green: 0.80, blue: 1.0),
                accent: Color(red: 0.55, green: 0.37, blue: 1.0),
                highlight: Color(red: 0.16, green: 0.13, blue: 0.46)
            )
        case .cobalt:
            ThemePalette(
                sidebar: Color(red: 0.03, green: 0.18, blue: 0.34),
                editor: Color(red: 0.02, green: 0.09, blue: 0.20),
                primaryLine: Color(red: 0.20, green: 0.86, blue: 1.0),
                secondaryLine: Color(red: 0.50, green: 0.70, blue: 1.0),
                accent: Color(red: 0.02, green: 0.62, blue: 1.0),
                highlight: Color(red: 0.04, green: 0.27, blue: 0.52)
            )
        case .coralReef:
            ThemePalette(
                sidebar: Color(red: 0.02, green: 0.26, blue: 0.25),
                editor: Color(red: 0.02, green: 0.16, blue: 0.17),
                primaryLine: Color(red: 0.40, green: 0.95, blue: 0.81),
                secondaryLine: Color(red: 0.85, green: 0.53, blue: 0.92),
                accent: Color(red: 0.12, green: 0.76, blue: 0.63),
                highlight: Color(red: 0.06, green: 0.36, blue: 0.33)
            )
        case .emerald:
            ThemePalette(
                sidebar: Color(red: 0.06, green: 0.24, blue: 0.11),
                editor: Color(red: 0.03, green: 0.14, blue: 0.08),
                primaryLine: Color(red: 0.35, green: 0.93, blue: 0.55),
                secondaryLine: Color(red: 0.95, green: 0.73, blue: 0.22),
                accent: Color(red: 0.13, green: 0.70, blue: 0.34),
                highlight: Color(red: 0.10, green: 0.34, blue: 0.16)
            )
        }
    }

    #if os(macOS)
    /// AppKit appearance represented by this preference.
    fileprivate var nsAppearance: NSAppearance? {
        switch colorScheme {
        case nil:
            nil
        case .light:
            NSAppearance(named: .aqua)
        case .dark:
            NSAppearance(named: .darkAqua)
        @unknown default:
            nil
        }
    }

    /// Asset catalog image used for the app and Dock icon under this preference.
    fileprivate var appIconImageName: String {
        switch self {
        case .system:
            "HomebrewIconSystem"
        case .light:
            "HomebrewIconLight"
        case .dark:
            "HomebrewIconDark"
        case .standard:
            "HomebrewIconStandard"
        case .sakura:
            "HomebrewIconSakura"
        case .ember:
            "HomebrewIconEmber"
        case .sunrise:
            "HomebrewIconSunrise"
        case .midnight:
            "HomebrewIconMidnight"
        case .neonNoir:
            "HomebrewIconNeonNoir"
        case .cobalt:
            "HomebrewIconCobalt"
        case .coralReef:
            "HomebrewIconCoralReef"
        case .emerald:
            "HomebrewIconEmerald"
        }
    }
    #endif

    /// Applies the selected appearance to the app and any windows already on screen.
    @MainActor
    func apply() {
        #if os(macOS)
        let appearance = nsAppearance
        NSApp.appearance = appearance
        NSApp.windows.forEach { window in
            window.appearance = appearance
            window.contentView?.needsDisplay = true
            window.viewsNeedDisplay = true
        }
        if let icon = NSImage(named: appIconImageName) {
            NSApp.applicationIconImage = icon
        }
        #endif
    }
}

/// Colors that define one app theme preview and accent.
struct ThemePalette {
    let sidebar: Color
    let editor: Color
    let primaryLine: Color
    let secondaryLine: Color
    let accent: Color
    let highlight: Color
}

private struct AppAppearancePreferenceKey: EnvironmentKey {
    static let defaultValue: AppearancePreference = .system
}

extension EnvironmentValues {
    /// Currently selected app appearance theme.
    var appAppearancePreference: AppearancePreference {
        get { self[AppAppearancePreferenceKey.self] }
        set { self[AppAppearancePreferenceKey.self] = newValue }
    }
}

/// Applies an app appearance preference using the platform-appropriate mechanism.
private struct AppAppearanceModifier: ViewModifier {
    let preference: AppearancePreference

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .environment(\.appAppearancePreference, preference)
            .tint(preference.accentColor)
            .fontDesign(preference.fontDesign)
            .background(preference.palette.editor)
            .background(WindowAppearanceApplier(preference: preference).frame(width: 0, height: 0))
        #else
        content
            .environment(\.appAppearancePreference, preference)
            .tint(preference.accentColor)
            .fontDesign(preference.fontDesign)
            .background(preference.palette.editor)
            .preferredColorScheme(preference.colorScheme)
        #endif
    }
}

#if os(macOS)
/// Hidden view that applies the selected appearance to the containing macOS window.
private struct WindowAppearanceApplier: NSViewRepresentable {
    let preference: AppearancePreference

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        apply(to: nsView.window)
        DispatchQueue.main.async {
            apply(to: nsView.window)
        }
    }

    private func apply(to window: NSWindow?) {
        let appearance = preference.nsAppearance
        NSApp.appearance = appearance
        window?.appearance = appearance
        window?.contentView?.needsDisplay = true
        window?.viewsNeedDisplay = true
    }
}
#endif

extension View {
    /// Applies the selected app appearance to this view hierarchy.
    func appAppearance(_ preference: AppearancePreference) -> some View {
        modifier(AppAppearanceModifier(preference: preference))
    }
}
