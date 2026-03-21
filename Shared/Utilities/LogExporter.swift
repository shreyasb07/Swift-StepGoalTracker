//
//  LogExporter.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/15/26.
//

import Foundation
import ZipArchive

class LogExporter {
    static let shared = LogExporter()
    private init() {}

    private let fileManager = FileManager.default

    //MARK: - Exports Directory
    private var exportsDirectory: URL {
        let documents = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        return documents.appendingPathComponent("exports", isDirectory: true)
    }

    // MARK: - Export
    func exportLogs(forDays days: Int) async throws -> URL {
        try createExportsDirectoryIfNeeded()

        let logFiles = LogFileWriter.shared.logFiles(for: days)

        guard !logFiles.isEmpty else {
            Logger.warning("No log files found for the last \(days) days")
            throw LogExportError.noLogsFound
        }
        Logger.info(
            "Exporting \(logFiles.count) log files for the last \(days) days"
        )

        let zipURL = try await zipLogFiles(logFiles)
        Logger.success(
            "Successfully exported logs to \(zipURL.lastPathComponent)"
        )
        return zipURL
    }

    // MARK: - Zip
    private func zipLogFiles(_ files: [URL]) async throws -> URL {
        return try await Task.detached(priority: .userInitiated) {
            let dateString = DateFormatter.exportDateFormatter.string(
                from: Date()
            )
            let zipFileName = "Stepido_logs_\(dateString).zip"
            let zipURL = self.exportsDirectory.appendingPathComponent(
                zipFileName
            )

            //Remove existing zip if present
            try? self.fileManager.removeItem(at: zipURL)

            // ZipArchive - one clean line to zip all files
            let success = SSZipArchive.createZipFile(
                atPath: zipURL.path,
                withFilesAtPaths: files.map(\.path)
            )

            guard success else {
                Logger.error(
                    "SSZipArchive failed to create zip file at \(zipURL.path)"
                )
                throw LogExportError.zipCreationFailed
            }
            Logger.debug(
                "Zip created with \(files.count) files: \(zipFileName)"
            )
            return zipURL
        }.value
    }

    // MARK: - Helpers
    private func createExportsDirectoryIfNeeded() throws {
        guard !fileManager.fileExists(atPath: exportsDirectory.path) else {
            return
        }
        do {
            try fileManager.createDirectory(
                at: exportsDirectory,
                withIntermediateDirectories: true
            )
            Logger.info("Exports directory created at \(exportsDirectory.path)")
        } catch {
            Logger.error(
                "Failed to create exports directory: \(error.localizedDescription)"
            )
            throw LogExportError.directoryCreationFailed
        }
    }

    func deleteAllExports() {
        guard
            let files = try? fileManager.contentsOfDirectory(
                at: exportsDirectory,
                includingPropertiesForKeys: nil
            )
        else { return }

        for file in files {
            try? fileManager.removeItem(at: file)
        }
        Logger.info("All exports deleted")
    }
}

// MARK: - Errors
enum LogExportError: LocalizedError {
    case noLogsFound
    case zipCreationFailed
    case directoryCreationFailed

    var errorDescription: String? {
        switch self {
        case .noLogsFound:
            return "No log files found for the selected period."
        case .zipCreationFailed:
            return "Failed to create the zip archive."
        case .directoryCreationFailed:
            return "Failed to create the exports directory."
        }
    }
}

// MARK: - DateFormatter
extension DateFormatter {
    fileprivate static let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
