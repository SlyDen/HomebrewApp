import Foundation

/// Errors specific to the Homebrew Formulae HTTP API.
nonisolated enum FormulaRegistryServiceError: LocalizedError, Equatable, Sendable {
    /// The server response was not HTTP.
    case invalidResponse

    /// The server returned an unsuccessful HTTP status.
    case httpStatus(Int)

    /// Localized message displayed in the registry browser.
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            String(
                localized: "The Homebrew registry returned an invalid response.",
                comment: "Error shown when the formula registry response is not HTTP."
            )
        case .httpStatus(let statusCode):
            String(
                localized: "The Homebrew registry request failed with status \(statusCode).",
                comment: "Registry HTTP error; the variable is the numeric status code."
            )
        }
    }
}
