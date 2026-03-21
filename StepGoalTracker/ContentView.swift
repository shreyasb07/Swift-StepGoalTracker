//
//  ContentView.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 2/2/26.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @StateObject var connector = PhoneConnector()
    @StateObject var health = HealthManager()
    @ObservedObject var notifications = NotificationManager.shared
    
    @State private var activeTab: Int = 0
    
    var body: some View {
        TabView(selection: $activeTab) {
            HomeView(connector: connector, health: health)
                .tabItem {
                    Label("Home", systemImage:"figure.walk")
                }
                .tag(0)
            SummaryView(connector: connector, health: health)
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
                .tag(1)
            SettingsView(connector: connector, health: health)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(Color("motivationText"))
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            NotificationManager.shared.checkAuthorizationStatus()
            health.requestAuthorization(goal: connector.stepGoal)
        }
        .onReceive(notifications.$tappedNotificationType) {type in
            guard let type else {return}
            switch type {
            case .milestone:
                activeTab = 0
            case .weeklyReport:
                activeTab = 1
            }
            notifications.tappedNotificationType = nil
        }
        .onReceive(NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification)
                ) { _ in
                    NotificationManager.shared.checkAuthorizationStatus()
                }
                .refreshable {
                    await health.fetchTodaySteps(goal: connector.stepGoal)
                    await health.fetchWeeklySteps(goal: connector.stepGoal)
                }
    }
}

#Preview {
    ContentView()
}
