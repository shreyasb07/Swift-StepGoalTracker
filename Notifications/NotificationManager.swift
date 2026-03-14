//
//  NotificationManager.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/7/26.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject,ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var tappedNotificationType: NotificationType? = nil
    
    enum NotificationType {
        case milestone
        case weeklyReport
    }
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    //MARK: - Delegate Methods
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        DispatchQueue.main.async {
            if identifier.hasPrefix("milestone_"){
                self.tappedNotificationType = .milestone
            } else if identifier == "weekly_report" {
                self.tappedNotificationType = .weeklyReport
            }
        }
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping  (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    //MARK: - Authorization
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            DispatchQueue.main.async {
                self.checkAuthorizationStatus()
            }
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
}
