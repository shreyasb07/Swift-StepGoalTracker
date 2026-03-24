//
//  StepGoalTrackerApp.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 2/2/26.
//

import SwiftUI

@main
struct StepGoalTrackerApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        // Delay log rotation slightly to ensure LogFileWriter is fully initialized
        DispatchQueue.main.async {
            LogRotationManager.shared.rotate()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
