//
//  NotificationManager.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/7/26.
//

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private init() {}

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

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
