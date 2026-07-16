import Foundation

/// Public Homebrew Formulae JSON API client.
nonisolated struct FormulaRegistryService: FormulaRegistryServicing {
    private static let defaultEndpoint: URL = {
        guard let endpoint = URL(string: "https://formulae.brew.sh/api/formula.json") else {
            preconditionFailure("The Homebrew formula registry endpoint must be a valid URL.")
        }
        return endpoint
    }()

    private let session: URLSession
    private let endpoint: URL

    /// Creates a registry service with injectable networking for tests.
    init(session: URLSession = .shared, endpoint: URL = defaultEndpoint) {
        self.session = session
        self.endpoint = endpoint
    }

    /// Downloads and decodes the current Homebrew formula catalog.
    @concurrent func fetchFormulae(forceRefresh: Bool) async throws -> [FormulaRegistryFormula] {
        let cachePolicy: URLRequest.CachePolicy = forceRefresh ? .reloadRevalidatingCacheData : .returnCacheDataElseLoad
        var request = URLRequest(url: endpoint, cachePolicy: cachePolicy, timeoutInterval: 30)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()

        guard let response = response as? HTTPURLResponse else {
            throw FormulaRegistryServiceError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw FormulaRegistryServiceError.httpStatus(response.statusCode)
        }

        return try JSONDecoder().decode([FormulaRegistryFormula].self, from: data)
    }
}
