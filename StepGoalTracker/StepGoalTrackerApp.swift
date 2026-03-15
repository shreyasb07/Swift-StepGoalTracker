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
        LogRotationManager.shared.rotate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
