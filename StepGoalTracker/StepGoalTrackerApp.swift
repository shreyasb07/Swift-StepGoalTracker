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
        // Debug — check if AppIcon.png is in bundle
            if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png") {
                Logger.success("AppIcon.png found at: \(url.path)")
            } else {
                Logger.error("AppIcon.png NOT found in bundle")
                // List all files in bundle to see what's there
                if let resources = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: nil) {
                    Logger.debug("PNG files in bundle: \(resources.map(\.lastPathComponent))")
                }
            }
        
        
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        LogRotationManager.shared.rotate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
