import Foundation

/// Main-actor callback used to publish concise progress from a Homebrew command.
typealias HomebrewProgressHandler = @MainActor @Sendable (String) -> Void

/// Serializes progress callbacks and exposes a completion point for process shutdown.
///
/// Pipe callbacks can arrive on different threads. Chaining each delivery behind the
/// previous task preserves the order in which parsed messages reach this object, while
/// `finish()` lets the process runner wait until the main actor has applied them all.
nonisolated final class HomebrewProgressDelivery: @unchecked Sendable {
    private let lock = NSLock()
    private let progress: HomebrewProgressHandler
    private var pendingDelivery: Task<Void, Never>?

    /// Creates a delivery queue for one command's progress callback.
    init(progress: @escaping HomebrewProgressHandler) {
        self.progress = progress
    }

    /// Adds parsed messages to the ordered main-actor delivery chain.
    func publish(_ messages: [String]) {
        guard messages.isEmpty == false else { return }

        lock.withLock {
            let previousDelivery = pendingDelivery
            let progress = self.progress
            pendingDelivery = Task {
                await previousDelivery?.value
                for message in messages {
                    await progress(message)
                }
            }
        }
    }

    /// Waits until every message published so far has reached the progress callback.
    func finish() async {
        let finalDelivery = lock.withLock { pendingDelivery }
        await finalDelivery?.value
    }
}

/// Converts streamed Homebrew output into complete lines before parsing it.
///
/// `FileHandle` readability callbacks are not actor-isolated. All mutable buffer
/// state is protected by `lock`, and parsed messages cross to the main actor
/// before reaching observable UI state.
nonisolated final class HomebrewProcessOutputObserver: @unchecked Sendable {
    private let lock = NSLock()
    private var bufferedData = Data()
    private let delivery: HomebrewProgressDelivery

    /// Creates an observer that reports parsed progress on the main actor.
    init(progress: @escaping HomebrewProgressHandler) {
        delivery = HomebrewProgressDelivery(progress: progress)
    }

    /// Creates an observer that shares an ordered delivery queue with another pipe.
    init(delivery: HomebrewProgressDelivery) {
        self.delivery = delivery
    }

    /// Accepts an arbitrary stdout or stderr chunk.
    func consume(_ data: Data) {
        guard !data.isEmpty else { return }

        lock.lock()
        bufferedData.append(data)
        let lines = removeCompleteLines()
        lock.unlock()

        publish(lines)
    }

    /// Publishes any final unterminated line after the process exits.
    func finish() {
        lock.lock()
        let finalLine = bufferedData.isEmpty ? nil : String(bytes: bufferedData, encoding: .utf8)
        bufferedData.removeAll(keepingCapacity: false)
        lock.unlock()

        if let finalLine {
            publish([finalLine])
        }
    }

    /// Removes and decodes all newline-terminated records currently buffered.
    private func removeCompleteLines() -> [String] {
        var lines: [String] = []

        while let newlineIndex = bufferedData.firstIndex(of: 0x0A) {
            let lineData = bufferedData[..<newlineIndex]
            if let line = String(bytes: lineData, encoding: .utf8) {
                lines.append(line)
            }
            bufferedData.removeSubrange(...newlineIndex)
        }

        return lines
    }

    /// Parses lines and delivers meaningful changes to observable state.
    private func publish(_ lines: [String]) {
        let messages = lines.compactMap(HomebrewOutputParser.progressMessage(from:))
        delivery.publish(messages)
    }
}

/// Extracts concise package-operation progress from Homebrew's human-readable output.
struct HomebrewOutputParser {
    /// Returns a user-facing progress message for a significant Homebrew output line.
    nonisolated static func progressMessage(from output: String) -> String? {
        let line = removingANSIEscapeSequences(from: output)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !line.isEmpty else { return nil }

        if line.localizedCaseInsensitiveContains("password may be necessary") {
            if let packageName = packageNameRequiringAdministratorAccess(in: line) {
                return "Waiting for administrator password for \(packageName)"
            }
            return "Waiting for administrator password"
        }

        if line.hasPrefix("Error:") {
            return line
        }

        guard line.hasPrefix("==> ") else { return nil }
        let message = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
        let meaningfulPrefixes = [
            "Upgrading ",
            "Installing dependencies for ",
            "Installing Cask ",
            "Running installer for ",
            "Pouring ",
            "Linking ",
            "Downloading "
        ]

        return meaningfulPrefixes.contains { message.hasPrefix($0) } ? message : nil
    }

    /// Extracts the package token from Homebrew's sudo installer notice.
    nonisolated private static func packageNameRequiringAdministratorAccess(in line: String) -> String? {
        guard let start = line.range(of: "Running installer for ")?.upperBound,
              let end = line.range(of: " with sudo", range: start..<line.endIndex)?.lowerBound,
              start < end else {
            return nil
        }

        return String(line[start..<end])
    }

    /// Removes terminal control sequences so matching also works for colored output.
    nonisolated private static func removingANSIEscapeSequences(from value: String) -> String {
        var result = String.UnicodeScalarView()
        var iterator = value.unicodeScalars.makeIterator()

        while let scalar = iterator.next() {
            guard scalar.value == 0x1B else {
                result.append(scalar)
                continue
            }

            guard let next = iterator.next(), next.value == 0x5B else { continue }
            while let controlScalar = iterator.next() {
                if (0x40...0x7E).contains(controlScalar.value) {
                    break
                }
            }
        }

        return String(result)
    }
}
