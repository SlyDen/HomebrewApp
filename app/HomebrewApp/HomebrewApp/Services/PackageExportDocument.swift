import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// File document wrapper for exporting package state as JSON.
///
/// The JSON bytes are encoded by `PackageLibrary` and passed into this document so
/// the `FileDocument` implementation only needs to read and write raw data.
struct PackageExportDocument: FileDocument {
    /// Supported document content type.
    static var readableContentTypes: [UTType] { [.json] }

    /// Encoded JSON document bytes.
    var data: Data

    /// Creates a document from already encoded JSON data.
    ///
    /// - Parameter data: JSON bytes to write when the file exporter completes.
    init(data: Data = Data("{}".utf8)) {
        self.data = data
    }

    /// Reads JSON data from an imported file document.
    ///
    /// Import support is minimal today, but keeping the initializer valid preserves
    /// the full `FileDocument` contract for later bulk-install/import work.
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    /// Writes the encoded JSON bytes to the destination selected by the user.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
