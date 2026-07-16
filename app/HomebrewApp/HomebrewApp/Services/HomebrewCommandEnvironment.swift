import Foundation

/// Builds the environment inherited by Homebrew child processes.
struct HomebrewCommandEnvironment {
    /// Applies app-controlled Homebrew flags to an inherited environment.
    ///
    /// When tap-trust bypass is disabled, any inherited override is removed so
    /// the persisted UI preference remains authoritative.
    nonisolated static func make(
        inheriting baseEnvironment: [String: String],
        resolvedPATH: String,
        disablesTapTrustChecks: Bool,
        askpassPath: String?
    ) -> [String: String] {
        var environment = baseEnvironment
        environment["PATH"] = resolvedPATH
        environment["HOMEBREW_NO_ANALYTICS"] = "1"
        environment["HOMEBREW_NO_AUTO_UPDATE"] = "1"
        environment["HOMEBREW_NO_INSTALL_CLEANUP"] = "1"
        environment["HOMEBREW_NO_ENV_HINTS"] = "1"

        if disablesTapTrustChecks {
            environment["HOMEBREW_NO_REQUIRE_TAP_TRUST"] = "1"
        } else {
            environment.removeValue(forKey: "HOMEBREW_NO_REQUIRE_TAP_TRUST")
        }

        if let askpassPath {
            environment["SUDO_ASKPASS"] = askpassPath
        }

        return environment
    }
}
