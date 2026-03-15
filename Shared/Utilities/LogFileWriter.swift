//
//  LogFileWriter.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/14/26.
//

import Foundation

class LogFileWriter {
    static let shared = LogFileWriter()
    private init() {
        createLogsDirectoryIfNeeded()
    }
    
    //MARK: - Paths
    private let fileManager = FileManager.default
    
    private var logsDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Logs", isDirectory: true)
    }
    
    private var currentLogFile: URL {
        let dateString = DateFormatter.logFileDateFormatter.string(from: Date())
        return logsDirectory.appendingPathComponent("\(dateString).log")
    }
    
    //MARK: - Serial Queue
    // All file writes happen on this queue so we never block the main thread
    private let writeQueue = DispatchQueue(
        label: "com.stepmaster.logwriter",
        qos: .background
    )
    
    //MARK: - Setup
    private func createLogsDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: logsDirectory.path) else { return }
        do {
            try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
            Logger.info("Logs directory created at \(logsDirectory.path)")
        } catch {
            Logger.error("Failed to create logs directory: \(error.localizedDescription)")
        }
    }
    
    //MARK: - Write
    func write(_ message: String) {
        writeQueue.async {
            let entry = message + "\n"
            guard let data = entry.data(using: .utf8) else { return }
            
            if self.fileManager.fileExists(atPath: self.currentLogFile.path) {
                // Append to existing file
                if let handle = try? FileHandle(forWritingTo: self.currentLogFile) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                // Create new file for today
                self.fileManager.createFile(atPath: self.currentLogFile.path, contents: data)
            }
        }
    }
    
    //MARK: - Fetch
    func allLogFiles() -> [URL] {
        let files = try? fileManager.contentsOfDirectory(
            at: logsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )
        return (files ?? [])
            .filter { $0.pathExtension == "log" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent } // newest first
    }
    
    
    func logFiles(for days: Int) -> [URL] {
        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        )!
        return allLogFiles().filter { url in
            let dateString = url.deletingPathExtension().lastPathComponent
            guard let date = DateFormatter.logFileDateFormatter.date(from: dateString)
            else { return false }
            return date >= cutoff
        }
    }
    
    // MARK: - Delete
    func deleteLogFiles(olderThan days: Int) {
        writeQueue.async {
            let filesToDelete = self.allLogFiles().filter { url in
                let dateString = url.deletingPathExtension().lastPathComponent
                guard let date = DateFormatter.logFileDateFormatter.date(from: dateString)
                else { return false }
                let cutoff = Calendar.current.date(
                    byAdding: .day,
                    value: -days,
                    to: Date()
                )!
                return date < cutoff
            }

            for file in filesToDelete {
                do {
                    try self.fileManager.removeItem(at: file)
                    Logger.info("Deleted old log file: \(file.lastPathComponent)")
                } catch {
                    Logger.error("Failed to delete log file \(file.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
    }

    func deleteAllLogFiles() {
        writeQueue.async {
            for file in self.allLogFiles() {
                try? self.fileManager.removeItem(at: file)
            }
            Logger.info("All log files deleted")
        }
    }
    
    
}

// MARK: - DateFormatter Extension
private extension DateFormatter {
    static let logFileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
