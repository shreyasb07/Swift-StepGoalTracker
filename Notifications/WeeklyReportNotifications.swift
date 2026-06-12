//
//  WeeklyReportNotifications.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/10/26.
//

import Foundation
import UserNotifications


// MARK: - WeeklyReport Notifications
extension NotificationManager {
    // MARK: - Weekly Report
    func scheduleWeeklyReport(
    ) {
        // Remove any existing weekly report to avoid duplicates
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["weekly_report"]
        )

        let content = UNMutableNotificationContent()
        content.userInfo = ["mutable-content": 1] // Triggers extension
        // These act as "Fallbacks" in case the extension fails or hits a timeout
        content.title = "Weekly Wrap-up 👟"
        content.body = "Checking your stats from last week... Swipe to see how you did!"
        content.sound = .default

        // Fire every Monday at 9am
        var dateComponents = DateComponents()
        dateComponents.weekday = 2  // Monday
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "weekly_report",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Logger.error(
                    "Failed to schedule weekly report: \(error.localizedDescription)"
                )
            }
        }
    }
}
