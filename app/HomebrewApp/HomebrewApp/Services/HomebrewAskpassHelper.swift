import Foundation

/// Temporary `SUDO_ASKPASS` helper that presents a native hidden-password dialog.
///
/// The password is returned directly from `osascript` to `sudo`; it is never held
/// by app model state or included in command logs.
struct HomebrewAskpassHelper {
    /// Private temporary directory containing the helper executable.
    let directoryURL: URL

    /// Executable path supplied to Homebrew through `SUDO_ASKPASS`.
    let executableURL: URL

    /// Creates a user-only helper that asks for an administrator password.
    static func create(fileManager: FileManager = .default) throws -> HomebrewAskpassHelper {
        let directoryURL = fileManager.temporaryDirectory.appending(
            path: "HomebrewApp-Askpass-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700]
        )

        let executableURL = directoryURL.appending(path: "askpass")
        let script = """
        #!/bin/zsh
        exec /usr/bin/osascript - "$1" <<'APPLESCRIPT'
        on run argv
            set promptText to "Homebrew needs administrator access."
            if (count of argv) > 0 then set promptText to item 1 of argv
            set dialogResult to display dialog promptText default answer "" with hidden answer buttons {"Cancel", "Authenticate"} default button "Authenticate" cancel button "Cancel" with title "HomebrewApp Administrator Access" with icon caution
            return text returned of dialogResult
        end run
        APPLESCRIPT
        """

        do {
            try Data(script.utf8).write(to: executableURL, options: .atomic)
            try fileManager.setAttributes(
                [.posixPermissions: 0o700],
                ofItemAtPath: executableURL.path
            )
            return HomebrewAskpassHelper(directoryURL: directoryURL, executableURL: executableURL)
        } catch {
            try? fileManager.removeItem(at: directoryURL)
            throw error
        }
    }

    /// Removes the helper immediately after its Homebrew process finishes.
    func remove(fileManager: FileManager = .default) {
        try? fileManager.removeItem(at: directoryURL)
    }
}
