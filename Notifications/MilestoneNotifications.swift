//
//  MilestoneNotifications.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/10/26.
//
import UIKit
import Foundation
import UserNotifications

// MARK: - Milestone Notifications
extension NotificationManager {
    // Tracks which milestones have already fired today so we don't double notify
    private var milestonesKey: String { "firedMilestonesToday" }
    private var milestoneDateKey: String { "milestoneFireDate" }

    private var firedMilestones: Set<Int> {
        get {
            let array =
                UserDefaults.standard.array(forKey: milestonesKey) as? [Int]
                ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: milestonesKey)
        }
    }

    func resetMilestonesIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()
        let lastFiredDate = formatter.date(
            from: UserDefaults.standard.string(forKey: milestoneDateKey) ?? ""
        ).map { Calendar.current.startOfDay(for: $0) }

        if lastFiredDate != today {
            firedMilestones = []
            UserDefaults.standard.set(
                formatter.string(from: today),
                forKey: milestoneDateKey
            )
        }
    }

    func checkAndSendMilestone(steps: Double, goal: Double) {
        resetMilestonesIfNewDay()

        let percentage = Int((steps / goal) * 100)
        let milestones = [25, 50, 75, 100]

        for milestone in milestones {
            if percentage >= milestone && !firedMilestones.contains(milestone) {
                sendMilestoneNotification(milestone: milestone, steps: steps)
                firedMilestones.insert(milestone)
            }
        }
    }
    
    private func sendMilestoneNotification(milestone: Int, steps: Double) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        switch milestone {
        case 25:
            content.title = "Good start! 🚶"
            content.body = "You've hit 25% of your daily goal. Keep moving!"
        case 50:
            content.title = "Halfway there! 💪"
            content.body = "You're at 50% of your goal. You've got this!"
        case 75:
            content.title = "Almost there! 🔥"
            content.body = "75% done — the finish line is in sight!"
        case 100:
            content.title = "Goal crushed! 🎉"
            content.body = "You've hit your step goal today. Amazing work!"
        default:
            break
        }

        // Attach the app icon as the notification image
        // Replace the Bundle.main.url approach with UIImage from assets
        if let image = UIImage(named: "AppIcon"),
           let data = image.pngData() {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("AppIcon.png")
            try? data.write(to: tempURL)
            do{
                let attachment = try UNNotificationAttachment(
                    identifier: "icon",
                    url: tempURL,
                    options: nil
                )
                content.attachments = [attachment]
                Logger.success("Notification attachment created successfully")
            }catch {
                Logger.error("Failed to create attachment: \(error.localizedDescription)")
            }
            
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "milestone_\(milestone)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Logger.error(
                    "Failed to schedule milestone notification: \(error.localizedDescription)"
                )
            }
        }
    }

}
