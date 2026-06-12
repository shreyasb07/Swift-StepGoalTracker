//
//  AppDelegate.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/26/26.
//

import Foundation
import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    // We will inject the HealthManager here later
    var healthManager: HealthManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Register the background task here
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppGroupConstants.streakTaskIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        return true
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()

        task.expirationHandler = {
            // Cleanup if needed
        }

        Task {
            let shared = UserDefaults(suiteName: AppGroupConstants.suiteName)
            let goal = shared?.double(forKey: AppGroupConstants.step_goal_key) ?? 10000
            
            // Call the manager safely
            await healthManager?.refreshStreak(goal: goal)
            await MainActor.run {
                healthManager?.lastBackgroundRefresh = Date()
            }
            
            task.setTaskCompleted(success: true)
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: AppGroupConstants.streakTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Logger.error("Could not schedule app refresh: \(error)")
        }
    }
}
