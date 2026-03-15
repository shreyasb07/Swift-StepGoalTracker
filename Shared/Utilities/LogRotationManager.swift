//
//  LogRotationManager.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/15/26.
//

import Foundation
import SwiftUI

class LogRotationManager {
    static let shared = LogRotationManager()
    private init() {}

    @AppStorage("logRetentionDays") private var retentionDays: Int = 14

    func rotate() {
        Logger.info("Running log rotation — retaining \(retentionDays) days")
        LogFileWriter.shared.deleteLogFiles(olderThan: retentionDays)
    }
}
