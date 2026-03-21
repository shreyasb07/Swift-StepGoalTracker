//
//  Logger.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/14/26.
//

import Foundation

enum LogLevel: String {
    case info = "ℹ️ INFO"
    case debug = "🐛 DEBUG"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    case success = "✅ SUCCESS"
}

struct Logger {
    static func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    static func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    static func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(
            message,
            level: .warning,
            file: file,
            function: function,
            line: line
        )
    }

    static func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    static func success(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(
            message,
            level: .success,
            file: file,
            function: function,
            line: line
        )
    }

    private static func log(
        _ message: String,
        level: LogLevel,
        file: String,
        function: String,
        line: Int
    ) {
        let fileName = (file as NSString).lastPathComponent
        let timeStamp = DateFormatter.logFormatter.string(from: Date())
        let entry =
            "[\(timeStamp)] \(level.rawValue) \(fileName):\(line) \(function) -> \(message)"
        #if DEBUG
            // Console output — debug builds only
            print(entry)
        #endif
        
        // File output — always, including release builds
        // so we can collect logs from real devices
        #if os(iOS)
        LogFileWriter.shared.write(entry)
        #endif
    }
}

extension DateFormatter {
    fileprivate static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
