import Foundation
import Testing
@testable import HomebrewApp

@MainActor
struct BrewInstalledVersionTests {
    @Test func decodesHomebrewTimeAsInstallDate() throws {
        let data = Data(
            """
            {
              "version": "1.2.3",
              "installed_on_request": true,
              "installed_as_dependency": false,
              "time": 1750000000
            }
            """.utf8
        )

        let version = try JSONDecoder().decode(BrewInstalledVersion.self, from: data)

        #expect(version.installedOn == Date(timeIntervalSince1970: 1_750_000_000))
    }
}
