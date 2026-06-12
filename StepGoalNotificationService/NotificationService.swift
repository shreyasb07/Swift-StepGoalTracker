//
//  NotificationService.swift
//  StepGoalNotificationService
//
//  Created by Shreyas Bhosale on 3/24/26.
//

import HealthKit
import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    let healthStore = HKHealthStore()

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler:
            @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent =
            (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else { return }
        // 1. Only intercept the weekly report
        if request.identifier == "weekly_report" {
            //            updateWeeklyReportWithLiveSteps(content: bestAttemptContent)
            fetchLiveWeeklyStats { average, daysGoalHit in
                let shared = UserDefaults(
                    suiteName: AppGroupConstants.suiteName
                )
                let currentStreak =
                    shared?.integer(forKey: AppGroupConstants.currentStreakKey)
                    ?? 0
                let previousStreak =
                    shared?.integer(forKey: AppGroupConstants.previousStreakKey)
                    ?? 0

                bestAttemptContent.title = self.weeklyReportTitle(
                    daysGoalHit: daysGoalHit
                )

                let notificationBody = self.weeklyReportBody(
                    daysGoalHit: daysGoalHit,
                    averageSteps: average,
                    currentStreak: currentStreak,
                    previousStreak: previousStreak
                )
                bestAttemptContent.body = notificationBody
                contentHandler(bestAttemptContent)
            }
        } else {
            contentHandler(bestAttemptContent)
        }
    }

    private func fetchLiveWeeklyStats(
        completion: @escaping (Double, Int) -> Void
    ) {
        //Access the step goal from our shared appgroup
        let sharedDefaults = UserDefaults(
            suiteName: AppGroupConstants.suiteName
        )
        let goal =
            sharedDefaults?.double(forKey: AppGroupConstants.step_goal_key)
            ?? 10000

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        let calendar = Calendar.mondayFirst
        let now = Date()

        guard
            let startOfThisWeek = calendar.dateInterval(
                of: .weekOfYear,
                for: now
            )?.start
        else {
            completion(0, 0)
            return
        }
        guard
            let startOfLastWeek = calendar.date(
                byAdding: .day,
                value: -7,
                to: startOfThisWeek
            ),
            let endOfLastWeek = calendar.date(
                byAdding: .second,
                value: -1,
                to: startOfThisWeek
            )
        else {
            completion(0, 0)
            return
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfLastWeek,
            end: endOfLastWeek,
            options: .strictStartDate
        )

        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startOfLastWeek,
            intervalComponents: DateComponents(day: 1)
        )
        query.initialResultsHandler = { _, results, error in
            guard let stats = results else {
                completion(0, 0)
                return
            }
            var totalSteps: Double = 0
            var daysGoalHit = 0

            stats.enumerateStatistics(from: startOfLastWeek, to: endOfLastWeek)
            {
                statistic,
                _ in
                let steps =
                    statistic.sumQuantity()?.doubleValue(for: .count()) ?? 0
                totalSteps += steps
                if steps >= goal { daysGoalHit += 1 }
            }

            completion(totalSteps / 7.0, daysGoalHit)
        }

        healthStore.execute(query)
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler,
            let bestAttemptContent = bestAttemptContent
        {
            contentHandler(bestAttemptContent)
        }
    }

    private func weeklyReportTitle(daysGoalHit: Int) -> String {
        switch daysGoalHit {
        case 7: return "Perfect week! 🏆"
        case 5...6: return "Great week! 🌟"
        case 1...4: return "Solid effort 💪"
        default: return "Weekly Summary"
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
