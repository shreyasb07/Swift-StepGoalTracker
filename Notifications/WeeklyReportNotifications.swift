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
        daysGoalHit: Int,
        averageSteps: Double,
        currentStreak: Int,
        previousStreak: Int
    ) {
        // Remove any existing weekly report to avoid duplicates
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["weekly_report"]
        )

        let content = UNMutableNotificationContent()
        content.title = weeklyReportTitle(daysGoalHit: daysGoalHit)
        content.body = weeklyReportBody(
            daysGoalHit: daysGoalHit,
            averageSteps: averageSteps,
            currentStreak: currentStreak,
            previousStreak: previousStreak
        )
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
                print(
                    "Failed to schedule weekly report: \(error.localizedDescription)"
                )
            }
        }
    }

    private func weeklyReportTitle(daysGoalHit: Int) -> String {
        switch daysGoalHit {
        case 7: return "Perfect week! 🏆"
        case 5...6: return "Great week! 🌟"
        case 3...4: return "Solid effort this week 💪"
        default: return "Your weekly step summary"
        }
    }

    private func weeklyReportBody(
        daysGoalHit: Int,
        averageSteps: Double,
        currentStreak: Int,
        previousStreak: Int
    ) -> String {
        var parts: [String] = []

        parts.append(
            "You hit your goal \(daysGoalHit)/7 days with an average of \(Int(averageSteps)) steps/day."
        )

        if currentStreak > previousStreak {
            parts.append(
                "Your streak grew to \(currentStreak) days — keep it going!"
            )
        } else if currentStreak > 0 {
            parts.append("Current streak: \(currentStreak) days.")
        } else {
            parts.append("Start fresh this week — you've got this!")
        }

        return parts.joined(separator: " ")
    }
}
