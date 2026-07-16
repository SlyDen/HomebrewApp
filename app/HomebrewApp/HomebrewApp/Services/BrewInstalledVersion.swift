import Foundation

/// Decodable subset of an installed Homebrew formula version.
struct BrewInstalledVersion: Decodable {
    let version: String
    let installedOnRequest: Bool?
    let installedAsDependency: Bool?
    let installedTime: Int?

    enum CodingKeys: String, CodingKey {
        case version
        case installedOnRequest = "installed_on_request"
        case installedAsDependency = "installed_as_dependency"
        case installedTime = "time"
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
