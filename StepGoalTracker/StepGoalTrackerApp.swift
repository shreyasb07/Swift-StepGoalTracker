//
//  StepGoalTrackerApp.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 2/2/26.
//

import SwiftUI

@main
struct StepGoalTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var healthManager = HealthManager()
    @StateObject private var launchManager = AppLaunchManager()
    @StateObject private var notificationManager = NotificationManager.shared

    init() {
        UNUserNotificationCenter.current().delegate = NotificationManager.shared

        // Delay log rotation slightly to ensure LogFileWriter is fully initialized
        DispatchQueue.main.async {
            LogRotationManager.shared.rotate()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthManager)
                .environmentObject(launchManager)
                .environmentObject(notificationManager)
                .sheet(
                    isPresented: .constant(
                        launchManager.launchState == .goalSetup
                    ),
                    onDismiss: nil
                ) {
                    GoalSetupView(
                        connector: PhoneConnector(),
                        healthManager: healthManager
                    )
                    .environmentObject(launchManager)
                    .environmentObject(healthManager)
                    .environmentObject(notificationManager)
                    .interactiveDismissDisabled(true)
                }
                .onAppear {
                    delegate.healthManager = healthManager
                    delegate.scheduleAppRefresh()
                }
        }
    }
}
