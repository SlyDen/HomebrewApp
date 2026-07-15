import Foundation

/// Service contract for loading and mutating installed packages.
///
/// The UI depends on this package-manager-shaped interface rather than directly
/// invoking Homebrew. Additional package managers can implement the same contract
/// and feed `InstalledPackageDTO` snapshots into `PackageLibrary`.
protocol HomebrewServicing: Sendable {
    /// Returns the packages currently installed by the backing package manager.
    func installedPackages() async throws -> [InstalledPackageDTO]

    /// Deletes a specific package version.
    ///
    /// - Parameters:
    ///   - packageName: Package name or token.
    ///   - version: Version selected by the user.
    func deleteVersion(packageName: String, version: String) async throws

    /// Makes a specific version active where the package manager supports it.
    ///
    /// - Parameters:
    ///   - packageName: Package name or token.
    ///   - version: Version selected by the user.
    func makeVersionActive(packageName: String, version: String) async throws

    /// Upgrades a package.
    ///
    /// - Parameters:
    ///   - packageName: Package name or token.
    ///   - version: Optional selected version context.
    func update(packageName: String, version: String?) async throws

    /// Reinstalls a package.
    ///
    /// - Parameters:
    ///   - packageName: Package name or token.
    ///   - force: Whether the package manager should overwrite existing artifacts.
    func reinstall(packageName: String, force: Bool) async throws

    /// Deletes a whole package from the system.
    ///
    /// - Parameter packageName: Package name or token.
    func delete(packageName: String) async throws
}

/// Errors produced by the Homebrew service layer.
enum HomebrewServiceError: LocalizedError {
    /// Homebrew CLI access is unavailable on this platform.
    case unsupportedPlatform

    /// A command exited with a nonzero status or failed to launch.
    case commandFailed(executablePath: String, arguments: [String], message: String)

    /// A command exceeded the service timeout and was terminated.
    case commandTimedOut(executablePath: String, arguments: [String], seconds: TimeInterval)

    /// Localized message suitable for the app's status bar.
    var errorDescription: String? {
        switch self {
        case .unsupportedPlatform:
            "Homebrew CLI access is not available from this iOS app. Connect a macOS helper to refresh live package data."
        case .commandFailed(let executablePath, let arguments, let message):
            "\(executablePath) \(arguments.joined(separator: " ")) failed: \(message)"
        case .commandTimedOut(let executablePath, let arguments, let seconds):
            "\(executablePath) \(arguments.joined(separator: " ")) timed out after \(Int(seconds)) seconds."
        }
    }
}

/// Builds the concrete package service for the current platform.
struct HomebrewServiceFactory {
    /// Returns a CLI-backed service on macOS and sample data elsewhere.
    static func make() -> any HomebrewServicing {
        #if os(macOS)
        HomebrewCLIService()
        #else
        MockHomebrewService()
        #endif
    }
}

/// Sample package service used for previews and non-macOS builds.
struct MockHomebrewService: HomebrewServicing {
    /// Returns deterministic sample data for UI previews and tests.
    func installedPackages() async throws -> [InstalledPackageDTO] {
        let now = Date()

        return [
            InstalledPackageDTO(
                name: "git",
                kind: .formula,
                summary: "Distributed revision control system",
                homepage: URL(string: "https://git-scm.com"),
                installedVersions: [
                    InstalledVersionDTO(version: "2.50.1", isActive: true, installedOn: now.addingTimeInterval(-86_400 * 2)),
                    InstalledVersionDTO(version: "2.49.0", isActive: false, installedOn: now.addingTimeInterval(-86_400 * 28))
                ],
                installedOn: now.addingTimeInterval(-86_400 * 28)
            ),
            InstalledPackageDTO(
                name: "postgresql@17",
                kind: .formula,
                summary: "Object-relational database system",
                homepage: URL(string: "https://www.postgresql.org"),
                installedVersions: [
                    InstalledVersionDTO(version: "17.5", isActive: true, installedOn: now.addingTimeInterval(-86_400 * 7))
                ],
                installedOn: now.addingTimeInterval(-86_400 * 7)
            ),
            InstalledPackageDTO(
                name: "visual-studio-code",
                kind: .cask,
                summary: "Open-source code editor",
                homepage: URL(string: "https://code.visualstudio.com"),
                installedVersions: [
                    InstalledVersionDTO(version: "1.102.0", isActive: true, installedOn: now.addingTimeInterval(-86_400))
                ],
                installedOn: now.addingTimeInterval(-86_400)
            )
        ]
    }

    /// No-op sample delete action.
    func deleteVersion(packageName: String, version: String) async throws {}

    /// No-op sample activation action.
    func makeVersionActive(packageName: String, version: String) async throws {}

    /// No-op sample update action.
    func update(packageName: String, version: String?) async throws {}

    /// No-op sample reinstall action.
    func reinstall(packageName: String, force: Bool) async throws {}

    /// No-op sample delete action.
    func delete(packageName: String) async throws {}
}

#if os(macOS)
/// Homebrew CLI-backed package service.
///
/// Commands are delegated to `/bin/zsh -lc` so the user's login shell setup can
/// initialize Homebrew through `.zprofile`. The service also injects common
/// Homebrew environment flags to keep reads noninteractive and predictable.
struct HomebrewCLIService: HomebrewServicing {
    /// Loads installed formulae and casks from `brew info --json=v2 --installed`.
    ///
    /// The JSON command is slower than `brew list`, but it provides descriptions,
    /// homepage URLs, installed timestamps, and version metadata needed by the UI
    /// and export document.
    func installedPackages() async throws -> [InstalledPackageDTO] {
        let data = try await brewJSON(arguments: ["info", "--json=v2", "--installed"])

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let response = try decoder.decode(BrewInfoResponse.self, from: data)

        return response.formulae.map { $0.package(kind: .formula) } + response.casks.map { $0.package(kind: .cask) }
    }

    /// Runs `brew uninstall` for a version-specific package token.
    func deleteVersion(packageName: String, version: String) async throws {
        _ = try await brewJSON(arguments: ["uninstall", "\(packageName)@\(version)"])
    }

    /// Runs `brew link --overwrite` for a version-specific package token.
    func makeVersionActive(packageName: String, version: String) async throws {
        _ = try await brewJSON(arguments: ["link", "--overwrite", "\(packageName)@\(version)"])
    }

    /// Runs `brew upgrade` for the selected package.
    func update(packageName: String, version: String?) async throws {
        _ = try await brewJSON(arguments: ["upgrade", packageName])
    }

    /// Runs `brew reinstall` for the selected package.
    func reinstall(packageName: String, force: Bool) async throws {
        let arguments = force ? ["reinstall", "--force", packageName] : ["reinstall", packageName]
        _ = try await brewJSON(arguments: arguments)
    }

    /// Runs `brew uninstall` for the selected package.
    func delete(packageName: String) async throws {
        _ = try await brewJSON(arguments: ["uninstall", packageName])
    }

    /// Runs a Homebrew command and returns stdout as raw data.
    private func brewJSON(arguments: [String]) async throws -> Data {
        try await runBrew(arguments: arguments)
    }

    /// Wraps a Homebrew command in a login zsh invocation.
    ///
    /// Homebrew is commonly initialized from `.zprofile` through
    /// `eval "$(/opt/homebrew/bin/brew shellenv)"`. Launching a login shell allows
    /// that setup to run without loading interactive `.zshrc` prompt plugins.
    private func runBrew(arguments: [String]) async throws -> Data {
        let shellURL = URL(fileURLWithPath: "/bin/zsh")
        let command = "exec brew \(arguments.map(\.quotedForShell).joined(separator: " "))"
        return try await runExecutable(shellURL, arguments: ["-lc", command], reportedExecutablePath: "brew", reportedArguments: arguments)
    }

    /// Launches an executable and streams stdout/stderr until it exits.
    ///
    /// `brew info --json=v2 --installed` can emit enough JSON to fill a pipe. The
    /// readability handlers continuously drain stdout and stderr so Homebrew does
    /// not block while writing. A timeout terminates hung commands and resumes the
    /// continuation exactly once through `ProcessCompletion`.
    ///
    /// - Parameters:
    ///   - executableURL: Executable to launch.
    ///   - arguments: Arguments passed to the executable.
    ///   - reportedExecutablePath: Optional command name shown in user-facing errors.
    ///   - reportedArguments: Optional argument list shown in user-facing errors.
    ///   - timeout: Maximum runtime before the process is terminated.
    /// - Returns: Complete stdout data collected from the process.
    private func runExecutable(
        _ executableURL: URL,
        arguments: [String],
        reportedExecutablePath: String? = nil,
        reportedArguments: [String]? = nil,
        timeout: TimeInterval = 45
    ) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments

            var environment = ProcessInfo.processInfo.environment
            environment["PATH"] = resolvedPATH
            environment["HOMEBREW_NO_ANALYTICS"] = "1"
            environment["HOMEBREW_NO_AUTO_UPDATE"] = "1"
            environment["HOMEBREW_NO_INSTALL_CLEANUP"] = "1"
            environment["HOMEBREW_NO_ENV_HINTS"] = "1"
            process.environment = environment

            let displayPath = reportedExecutablePath ?? executableURL.path
            let displayArguments = reportedArguments ?? arguments
            let output = Pipe()
            let error = Pipe()
            let outputBuffer = ProcessOutputBuffer()
            let errorBuffer = ProcessOutputBuffer()
            let completion = ProcessCompletion(continuation)

            output.fileHandleForReading.readabilityHandler = { handle in
                outputBuffer.append(handle.availableData)
            }
            error.fileHandleForReading.readabilityHandler = { handle in
                errorBuffer.append(handle.availableData)
            }

            process.standardOutput = output
            process.standardError = error
            process.terminationHandler = { process in
                output.fileHandleForReading.readabilityHandler = nil
                error.fileHandleForReading.readabilityHandler = nil
                outputBuffer.append(output.fileHandleForReading.readDataToEndOfFile())
                errorBuffer.append(error.fileHandleForReading.readDataToEndOfFile())

                if process.terminationStatus == 0 {
                    completion.finish(.success(outputBuffer.data))
                } else {
                    let message = String(data: errorBuffer.data, encoding: .utf8) ?? "process exited with status \(process.terminationStatus)"
                    completion.finish(
                        .failure(
                            HomebrewServiceError.commandFailed(
                                executablePath: displayPath,
                                arguments: displayArguments,
                                message: message.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                        )
                    )
                }
            }

            do {
                try process.run()
            } catch {
                completion.finish(
                    .failure(
                        HomebrewServiceError.commandFailed(
                            executablePath: displayPath,
                            arguments: displayArguments,
                            message: error.localizedDescription
                        )
                    )
                )
                return
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                guard process.isRunning else { return }
                process.terminate()
                completion.finish(
                    .failure(
                        HomebrewServiceError.commandTimedOut(
                            executablePath: displayPath,
                            arguments: displayArguments,
                            seconds: timeout
                        )
                    )
                )
            }
        }
    }

    /// PATH supplied to the launched shell before it reads user startup files.
    ///
    /// The default paths include Apple Silicon and Intel Homebrew locations so
    /// `.zprofile` can call `brew shellenv` even when the app itself was launched
    /// with a minimal GUI environment.
    private var resolvedPATH: String {
        let defaultPaths = [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ]
        let currentPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        return (defaultPaths + currentPath.split(separator: ":").map(String.init))
            .removingDuplicates()
            .joined(separator: ":")
    }
}

/// Thread-safe one-shot continuation wrapper for process completion.
///
/// Process termination and timeout callbacks can race. This helper guarantees
/// that only the first result resumes the Swift continuation.
nonisolated private final class ProcessCompletion: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Data, any Error>?

    /// Creates a one-shot wrapper around a continuation.
    init(_ continuation: CheckedContinuation<Data, any Error>) {
        self.continuation = continuation
    }

    /// Completes the continuation if it has not already been resumed.
    func finish(_ result: Result<Data, any Error>) {
        lock.lock()
        let continuation = continuation
        self.continuation = nil
        lock.unlock()

        guard let continuation else { return }

        switch result {
        case .success(let data):
            continuation.resume(returning: data)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

/// Thread-safe data accumulator used by pipe readability callbacks.
nonisolated private final class ProcessOutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = Data()

    /// Snapshot of all bytes collected so far.
    var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    /// Appends a non-empty chunk from a pipe.
    func append(_ data: Data) {
        guard !data.isEmpty else { return }
        lock.lock()
        storage.append(data)
        lock.unlock()
    }
}

/// Top-level response returned by `brew info --json=v2`.
private struct BrewInfoResponse: Decodable {
    /// Installed formulae in the response.
    var formulae: [BrewFormula] = []

    /// Installed casks in the response.
    var casks: [BrewCask] = []
}

/// Decodable subset of Homebrew formula metadata used by the app.
private struct BrewFormula: Decodable {
    let name: String
    let desc: String?
    let homepage: URL?
    let installed: [BrewInstalledVersion]

    /// Converts Homebrew formula metadata into the app's package snapshot format.
    func package(kind: ManagedPackageKind) -> InstalledPackageDTO {
        InstalledPackageDTO(
            name: name,
            kind: kind,
            summary: desc ?? "No description available",
            homepage: homepage,
            installedVersions: installed.map { $0.versionDTO },
            installedOn: installed.compactMap(\.installedOn).min() ?? .now
        )
    }
}

/// Decodable subset of Homebrew cask metadata used by the app.
private struct BrewCask: Decodable {
    let token: String
    let desc: String?
    let homepage: URL?
    let installed: String?
    let installedTime: Int?

    enum CodingKeys: String, CodingKey {
        case token
        case desc
        case homepage
        case installed
        case installedTime = "installed_time"
    }

    /// Converts Homebrew cask metadata into the app's package snapshot format.
    func package(kind: ManagedPackageKind) -> InstalledPackageDTO {
        let date = installedTime.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? .now
        return InstalledPackageDTO(
            name: token,
            kind: kind,
            summary: desc ?? "No description available",
            homepage: homepage,
            installedVersions: [InstalledVersionDTO(version: installed ?? "installed", isActive: true, installedOn: date)],
            installedOn: date
        )
    }
}

/// Decodable subset of an installed Homebrew formula version.
private struct BrewInstalledVersion: Decodable {
    let version: String
    let installedOnRequest: Bool?
    let installedAsDependency: Bool?
    let installedTime: Int?

    enum CodingKeys: String, CodingKey {
        case version
        case installedOnRequest = "installed_on_request"
        case installedAsDependency = "installed_as_dependency"
        case installedTime = "installed_time"
    }

    /// Install timestamp converted from Homebrew's seconds-since-epoch field.
    var installedOn: Date? {
        installedTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }

    /// Converts Homebrew version metadata into the UI/export DTO.
    var versionDTO: InstalledVersionDTO {
        InstalledVersionDTO(version: version, isActive: true, installedOn: installedOn)
    }
}

private extension Array where Element: Hashable {
    /// Returns this array without duplicate elements while preserving order.
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

private extension String {
    /// Single-quotes a string for safe use as one shell argument.
    var quotedForShell: String {
        "'\(replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
#endif
