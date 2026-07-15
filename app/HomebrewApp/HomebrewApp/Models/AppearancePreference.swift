import SwiftUI

#if os(macOS)
import AppKit
#endif

/// User-selectable app appearance mode persisted between launches.
enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    /// SwiftUI color scheme override for platforms that use SwiftUI's environment directly.
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
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
        }
    }

    #if os(macOS)
    /// AppKit appearance represented by this preference.
    fileprivate var nsAppearance: NSAppearance? {
        switch self {
        case .system:
            nil
        case .light:
            NSAppearance(named: .aqua)
        case .dark:
            NSAppearance(named: .darkAqua)
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
        #endif
    }
}

/// Applies an app appearance preference using the platform-appropriate mechanism.
private struct AppAppearanceModifier: ViewModifier {
    let preference: AppearancePreference

    func body(content: Content) -> some View {
        #if os(macOS)
        content.background(WindowAppearanceApplier(preference: preference).frame(width: 0, height: 0))
        #else
        content.preferredColorScheme(preference.colorScheme)
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
