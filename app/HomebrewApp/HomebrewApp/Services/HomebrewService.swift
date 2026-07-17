import Foundation

/// Service contract for loading and mutating installed packages.
///
/// The UI depends on this package-manager-shaped interface rather than directly
/// invoking Homebrew. Additional package managers can implement the same contract
/// and feed `InstalledPackageDTO` snapshots into `PackageLibrary`.
protocol HomebrewServicing: Sendable {
    /// Returns the packages currently installed by the backing package manager.
    func installedPackages(disablesTapTrustChecks: Bool) async throws -> [InstalledPackageDTO]

    /// Returns installed taps and the fully qualified package names they publish.
    ///
    /// - Parameter disablesTapTrustChecks: Whether to bypass non-official tap trust checks.
    func installedTaps(disablesTapTrustChecks: Bool) async throws -> [HomebrewTap]

    /// Adds a formula tap using its canonical `user/repository` name.
    ///
    /// - Parameters:
    ///   - name: Canonical tap name accepted by Homebrew.
    ///   - disablesTapTrustChecks: Whether to bypass non-official tap trust checks.
    func addTap(name: String, disablesTapTrustChecks: Bool) async throws

    /// Removes an installed tap using its canonical `user/repository` name.
    ///
    /// - Parameters:
    ///   - name: Canonical installed tap name.
    ///   - disablesTapTrustChecks: Whether to bypass non-official tap trust checks.
    func removeTap(name: String, disablesTapTrustChecks: Bool) async throws

    /// Installs a formula or cask from the Homebrew catalog.
    ///
    /// - Parameters:
    ///   - packageName: Short or tap-qualified package name published by Homebrew.
    ///   - kind: Whether Homebrew should resolve the package as a formula or cask.
    ///   - disablesTapTrustChecks: Whether to bypass non-official tap trust checks.
    func installPackage(
        packageName: String,
        kind: ManagedPackageKind,
        disablesTapTrustChecks: Bool
    ) async throws

    /// Fetches the newest Homebrew and formula metadata before package upgrades.
    func updateHomebrew(disablesTapTrustChecks: Bool) async throws

    /// Upgrades all outdated, unpinned packages.
    ///
    /// - Parameters:
    ///   - disablesTapTrustChecks: Whether to bypass non-official tap trust checks.
    ///   - progress: Optional main-actor handler for concise command progress.
    func upgradeAll(disablesTapTrustChecks: Bool, progress: HomebrewProgressHandler?) async throws

    /// Removes outdated package versions and stale Homebrew cache files.
    func cleanup(disablesTapTrustChecks: Bool) async throws

    /// Deletes a specific package version.
    ///
    /// - Parameters:
    ///   - packageName: Package name or token.
    ///   - version: Version selected by the user.
    func deleteVersion(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws

    /// Makes a specific version active where the package manager supports it.
    ///
    /// - Parameters:
    ///   - packageName: Package name or token.
    ///   - version: Version selected by the user.
    func makeVersionActive(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws

    /// Upgrades a package.
    ///
    /// - Parameters:
    ///   - packageName: Package name or token.
    ///   - version: Optional selected version context.
    func update(packageName: String, version: String?, disablesTapTrustChecks: Bool) async throws

    /// Reinstalls a package.
    ///
    /// - Parameters:
    ///   - packageName: Package name or token.
    ///   - force: Whether the package manager should overwrite existing artifacts.
    func reinstall(packageName: String, force: Bool, disablesTapTrustChecks: Bool) async throws

    /// Deletes a whole package from the system.
    ///
    /// - Parameter packageName: Package name or token.
    func delete(packageName: String, disablesTapTrustChecks: Bool) async throws
}

/// Errors produced by the Homebrew service layer.
enum HomebrewServiceError: LocalizedError {
    /// Homebrew CLI access is unavailable on this platform.
    case unsupportedPlatform

    /// A command exited with a nonzero status or failed to launch.
    case commandFailed(executablePath: String, arguments: [String], message: String)

    /// A command exceeded the service timeout and was terminated.
    case commandTimedOut(executablePath: String, arguments: [String], seconds: TimeInterval)

    /// The temporary helper used by `sudo -A` could not be prepared.
    case authenticationHelperFailed(message: String)

    /// Localized message suitable for the app's status bar.
    var errorDescription: String? {
        switch self {
        case .unsupportedPlatform:
            "Homebrew CLI access is not available from this iOS app. Connect a macOS helper to refresh live package data."
        case .commandFailed(let executablePath, let arguments, let message):
            "\(executablePath) \(arguments.joined(separator: " ")) failed: \(message)"
        case .commandTimedOut(let executablePath, let arguments, let seconds):
            "\(executablePath) \(arguments.joined(separator: " ")) timed out after \(Int(seconds)) seconds."
        case .authenticationHelperFailed(let message):
            "Administrator authentication could not be prepared: \(message)"
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
    func installedPackages(disablesTapTrustChecks: Bool) async throws -> [InstalledPackageDTO] {
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

    /// Returns deterministic sample tap data for previews and tests.
    func installedTaps(disablesTapTrustChecks: Bool) async throws -> [HomebrewTap] {
        [
            HomebrewTap(
                name: "darrylmorley/whatcable",
                formulaNames: ["darrylmorley/whatcable/whatcable-cli"],
                caskTokens: ["darrylmorley/whatcable/whatcable"],
                remote: "https://github.com/darrylmorley/homebrew-whatcable"
            )
        ]
    }

    /// No-op sample tap addition.
    func addTap(name: String, disablesTapTrustChecks: Bool) async throws {}

    /// No-op sample tap removal.
    func removeTap(name: String, disablesTapTrustChecks: Bool) async throws {}

    /// No-op sample package installation.
    func installPackage(
        packageName: String,
        kind: ManagedPackageKind,
        disablesTapTrustChecks: Bool
    ) async throws {}

    /// No-op sample Homebrew metadata update.
    func updateHomebrew(disablesTapTrustChecks: Bool) async throws {}

    /// No-op sample bulk upgrade action.
    func upgradeAll(disablesTapTrustChecks: Bool, progress: HomebrewProgressHandler?) async throws {
        progress?("Upgrading git")
    }

    /// No-op sample cleanup action.
    func cleanup(disablesTapTrustChecks: Bool) async throws {}

    /// No-op sample delete action.
    func deleteVersion(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws {}

    /// No-op sample activation action.
    func makeVersionActive(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws {}

    /// No-op sample update action.
    func update(packageName: String, version: String?, disablesTapTrustChecks: Bool) async throws {}

    /// No-op sample reinstall action.
    func reinstall(packageName: String, force: Bool, disablesTapTrustChecks: Bool) async throws {}

    /// No-op sample delete action.
    func delete(packageName: String, disablesTapTrustChecks: Bool) async throws {}
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
    func installedPackages(disablesTapTrustChecks: Bool) async throws -> [InstalledPackageDTO] {
        let data = try await brewJSON(
            arguments: ["info", "--json=v2", "--installed"],
            disablesTapTrustChecks: disablesTapTrustChecks
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let response = try decoder.decode(BrewInfoResponse.self, from: data)

        let packages = response.formulae.map { $0.package(kind: .formula) }
            + response.casks.map { $0.package(kind: .cask) }
        let sizes = await installedPackageSizes(for: packages, disablesTapTrustChecks: disablesTapTrustChecks)
        return packages.map { package in
            package.withInstalledSize(sizes[package.id])
        }
    }

    /// Runs a type-qualified install for a package selected from the catalog.
    func installPackage(
        packageName: String,
        kind: ManagedPackageKind,
        disablesTapTrustChecks: Bool
    ) async throws {
        let command = HomebrewInstallCommand(packageName: packageName, kind: kind)
        _ = try await brewJSON(
            arguments: command.arguments,
            timeout: 60 * 60,
            allowsAdministratorAuthentication: true,
            disablesTapTrustChecks: disablesTapTrustChecks
        )
    }

    /// Runs `brew update` as the mandatory first phase of a bulk upgrade.
    func updateHomebrew(disablesTapTrustChecks: Bool) async throws {
        _ = try await brewJSON(
            arguments: ["update"],
            timeout: 30 * 60,
            disablesTapTrustChecks: disablesTapTrustChecks
        )
    }

    /// Runs `brew upgrade --no-ask` for all outdated, unpinned packages.
    func upgradeAll(disablesTapTrustChecks: Bool, progress: HomebrewProgressHandler?) async throws {
        _ = try await brewJSON(
            arguments: ["upgrade", "--no-ask"],
            timeout: 60 * 60,
            progress: progress,
            allowsAdministratorAuthentication: true,
            disablesTapTrustChecks: disablesTapTrustChecks
        )
    }

    /// Runs a full `brew cleanup` after a bulk upgrade when requested.
    func cleanup(disablesTapTrustChecks: Bool) async throws {
        _ = try await brewJSON(
            arguments: ["cleanup"],
            timeout: 15 * 60,
            disablesTapTrustChecks: disablesTapTrustChecks
        )
    }

    /// Runs `brew uninstall` for a version-specific package token.
    func deleteVersion(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws {
        _ = try await brewJSON(
            arguments: ["uninstall", "\(packageName)@\(version)"],
            disablesTapTrustChecks: disablesTapTrustChecks
        )
    }

    /// Runs `brew link --overwrite` for a version-specific package token.
    func makeVersionActive(packageName: String, version: String, disablesTapTrustChecks: Bool) async throws {
        _ = try await brewJSON(
            arguments: ["link", "--overwrite", "\(packageName)@\(version)"],
            disablesTapTrustChecks: disablesTapTrustChecks
        )
    }

    /// Runs `brew upgrade` for the selected package.
    func update(packageName: String, version: String?, disablesTapTrustChecks: Bool) async throws {
        _ = try await brewJSON(
            arguments: ["upgrade", packageName],
            allowsAdministratorAuthentication: true,
            disablesTapTrustChecks: disablesTapTrustChecks
        )
    }

    /// Runs `brew reinstall` for the selected package.
    func reinstall(packageName: String, force: Bool, disablesTapTrustChecks: Bool) async throws {
        let arguments = force ? ["reinstall", "--force", packageName] : ["reinstall", packageName]
        _ = try await brewJSON(
            arguments: arguments,
            allowsAdministratorAuthentication: true,
            disablesTapTrustChecks: disablesTapTrustChecks
        )
    }

    /// Runs `brew uninstall` for the selected package.
    func delete(packageName: String, disablesTapTrustChecks: Bool) async throws {
        _ = try await brewJSON(
            arguments: ["uninstall", packageName],
            allowsAdministratorAuthentication: true,
            disablesTapTrustChecks: disablesTapTrustChecks
        )
    }

    /// Measures package directories without failing the main package refresh when
    /// disk-usage metadata is unavailable.
    private func installedPackageSizes(
        for packages: [InstalledPackageDTO],
        disablesTapTrustChecks: Bool
    ) async -> [String: Int64] {
        guard let data = try? await brewJSON(
            arguments: ["--prefix"],
            disablesTapTrustChecks: disablesTapTrustChecks
        ),
        let output = String(bytes: data, encoding: .utf8) else {
            return [:]
        }
        let path = output
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard path.isEmpty == false else { return [:] }
        let prefix = URL(filePath: path, directoryHint: .isDirectory)
        return await HomebrewPackageDiskUsage.sizes(for: packages, homebrewPrefix: prefix)
    }

    /// Runs a Homebrew command and returns stdout as raw data.
    private func brewJSON(
        arguments: [String],
        timeout: TimeInterval = 45,
        progress: HomebrewProgressHandler? = nil,
        allowsAdministratorAuthentication: Bool = false,
        disablesTapTrustChecks: Bool
    ) async throws -> Data {
        try await runBrew(
            arguments: arguments,
            timeout: timeout,
            progress: progress,
            allowsAdministratorAuthentication: allowsAdministratorAuthentication,
            disablesTapTrustChecks: disablesTapTrustChecks
        )
    }

    /// Wraps a Homebrew command in a login zsh invocation.
    ///
    /// Homebrew is commonly initialized from `.zprofile` through
    /// `eval "$(/opt/homebrew/bin/brew shellenv)"`. Launching a login shell allows
    /// that setup to run without loading interactive `.zshrc` prompt plugins.
    private func runBrew(
        arguments: [String],
        timeout: TimeInterval,
        progress: HomebrewProgressHandler?,
        allowsAdministratorAuthentication: Bool,
        disablesTapTrustChecks: Bool
    ) async throws -> Data {
        let shellURL = URL(fileURLWithPath: "/bin/zsh")
        let command = "exec brew \(arguments.map(\.quotedForShell).joined(separator: " "))"
        return try await runExecutable(
            shellURL,
            arguments: ["-lc", command],
            reportedExecutablePath: "brew",
            reportedArguments: arguments,
            timeout: timeout,
            progress: progress,
            allowsAdministratorAuthentication: allowsAdministratorAuthentication,
            disablesTapTrustChecks: disablesTapTrustChecks
        )
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
        timeout: TimeInterval = 45,
        progress: HomebrewProgressHandler? = nil,
        allowsAdministratorAuthentication: Bool = false,
        disablesTapTrustChecks: Bool
    ) async throws -> Data {
        let authenticationHelper: HomebrewAskpassHelper?
        if allowsAdministratorAuthentication {
            do {
                authenticationHelper = try HomebrewAskpassHelper.create()
            } catch {
                throw HomebrewServiceError.authenticationHelperFailed(message: error.localizedDescription)
            }
        } else {
            authenticationHelper = nil
        }
        defer { authenticationHelper?.remove() }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments

            process.environment = HomebrewCommandEnvironment.make(
                inheriting: ProcessInfo.processInfo.environment,
                resolvedPATH: resolvedPATH,
                disablesTapTrustChecks: disablesTapTrustChecks,
                askpassPath: authenticationHelper?.executableURL.path
            )

            let displayPath = reportedExecutablePath ?? executableURL.path
            let displayArguments = reportedArguments ?? arguments
            let output = Pipe()
            let error = Pipe()
            let outputBuffer = ProcessOutputBuffer()
            let errorBuffer = ProcessOutputBuffer()
            let completion = ProcessCompletion(continuation)
            let outputObserver = progress.map { HomebrewProcessOutputObserver(progress: $0) }
            let errorObserver = progress.map { HomebrewProcessOutputObserver(progress: $0) }

            output.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                outputBuffer.append(data)
                outputObserver?.consume(data)
            }
            error.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                errorBuffer.append(data)
                errorObserver?.consume(data)
            }

            process.standardOutput = output
            process.standardError = error
            process.terminationHandler = { process in
                output.fileHandleForReading.readabilityHandler = nil
                error.fileHandleForReading.readabilityHandler = nil
                let remainingOutput = output.fileHandleForReading.readDataToEndOfFile()
                let remainingError = error.fileHandleForReading.readDataToEndOfFile()
                outputBuffer.append(remainingOutput)
                errorBuffer.append(remainingError)
                outputObserver?.consume(remainingOutput)
                errorObserver?.consume(remainingError)
                outputObserver?.finish()
                errorObserver?.finish()

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

extension HomebrewCLIService {
    /// Loads installed taps and their formula names from Homebrew's JSON output.
    func installedTaps(disablesTapTrustChecks: Bool) async throws -> [HomebrewTap] {
        let data = try await brewJSON(
            arguments: ["tap-info", "--installed", "--json"],
            disablesTapTrustChecks: disablesTapTrustChecks
        )
        return try JSONDecoder().decode([HomebrewTap].self, from: data)
            .filter(\.isInstalled)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Runs `brew tap` for a canonical tap name.
    func addTap(name: String, disablesTapTrustChecks: Bool) async throws {
        _ = try await brewJSON(
            arguments: ["tap", name],
            timeout: 10 * 60,
            disablesTapTrustChecks: disablesTapTrustChecks
        )
    }

    /// Runs `brew untap` for a canonical tap name.
    func removeTap(name: String, disablesTapTrustChecks: Bool) async throws {
        _ = try await brewJSON(
            arguments: ["untap", name],
            timeout: 10 * 60,
            disablesTapTrustChecks: disablesTapTrustChecks
        )
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
