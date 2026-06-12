//
//  NotificationManager+Extension.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/26/26.
//

import Foundation
import UserNotifications

#if DEBUG
extension NotificationManager {
    func scheduleDebugWeeklyReport() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Wrap-up [DEBUG]"
        content.body = "This is placeholder text that the Extension should replace."
        content.sound = .default
        
        // CRITICAL: This must match the ID in your NotificationService.swift
        let identifier = "weekly_report"
        
        // Fire in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.error("DEBUG Error: \(error.localizedDescription)")
            } else {
                Logger.error("DEBUG: Weekly report scheduled for 5 seconds from now.")
            }
        }
    }
    
    func previewAndScheduleWeeklyReport(goal: Double, healthManager: HealthManager) {
            Task {
                // 1. Manually trigger a refresh to get the latest numbers
                await healthManager.refreshStreak(goal: goal)
                
                // 2. Grab the values we just calculated
                let currentStreak = await healthManager.currentStreak
                let averageSteps = 8420 // You could pull this from a 'weeklyAverage' property if you add one
                
                // 3. Construct the actual string your Extension will build
                let expectedBody = "You averaged \(averageSteps) steps/day and continued your streak to \(currentStreak) days. Keep it up!"
                
                print("--------------------------------")
                print("🚀 DEBUG NOTIFICATION PREVIEW")
                print("Body: \(expectedBody)")
                print("--------------------------------")

                // 4. Schedule the notification
                let content = UNMutableNotificationContent()
                content.title = "Weekly Wrap-up 👟"
                content.body = expectedBody // Extension will also try to calculate this
                content.sound = .default
                
                let request = UNNotificationRequest(
                    identifier: "weekly_report",
                    content: content,
                    trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                )
                
                try? await UNUserNotificationCenter.current().add(request)
            }
        }
}
#endif
