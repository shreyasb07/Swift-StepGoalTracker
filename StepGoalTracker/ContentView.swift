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

    var notificationStatusRow: some View {
        switch notifications.authorizationStatus {
        case .authorized:
            return AnyView(
                Label("Notifications enabled", systemImage: "bell.fill")
                    .foregroundStyle(.green)
            )
        case .denied:
            return AnyView(
                HStack {
                    Label(
                        "Notifications disabled",
                        systemImage: "bell.slash.fill"
                    )
                    .foregroundStyle(.red)
                    Spacer()
                    Button("Enable") {
                        // Can't prompt again once denied — send to Settings
                        if let url = URL(
                            string: UIApplication.openSettingsURLString
                        ) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            )
        case .notDetermined:
            return AnyView(
                Button {
                    NotificationManager.shared.requestAuthorization()
                } label: {
                    Label("Enable notifications", systemImage: "bell.badge")
                }
            )
        default:
            return AnyView(EmptyView())
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Daily Activity") {
                    HStack {
                        Text("Today's Steps")
                        Spacer()
                        Text("\(Int(health.stepCount))")
                            .bold()
                    }
                    HStack {
                        Label("Current Streak", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                        Spacer()
                        Text(
                            health.currentStreak == 0
                                ? "-" : "\(health.currentStreak) day(s)"
                        )
                        .bold()
                    }
                    HStack {
                        Label("Best Streak", systemImage: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text(
                            health.bestStreak == 0
                                ? "-" : "\(health.bestStreak) day(s)"
                        )
                        .bold()
                    }
                }

                Section("Settings") {
                    notificationStatusRow
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Goal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button {
                                let newGoal = max(
                                    1000,
                                    connector.stepGoal - 500
                                )
                                connector.stepGoal = newGoal
                                connector.updateGoal(newGoal: newGoal)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            VStack(spacing: 2) {
                                Text("\(Int(connector.stepGoal))")
                                    .font(.title2.monospacedDigit())
                                    .bold()
                                    .contentTransition(.numericText())
                                    .animation(
                                        .spring(duration: 0.3),
                                        value: connector.stepGoal
                                    )
                                Text("steps/day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                let newGoal = min(
                                    50000,
                                    connector.stepGoal + 500
                                )
                                connector.stepGoal = newGoal
                                connector.updateGoal(newGoal: newGoal)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("This Week") {
                    WeeklyStepsChart(
                        days: health.weeklySteps,
                        goal: connector.stepGoal
                    )
                }
            }
            .navigationTitle("StepMaster")
            .refreshable {
                await health.fetchTodaySteps(goal: connector.stepGoal)
                await health.fetchWeeklySteps(goal: connector.stepGoal)
            }
            .onAppear {
                NotificationManager.shared.requestAuthorization()
                NotificationManager.shared.checkAuthorizationStatus()
                health.requestAuthorization(goal: connector.stepGoal)
            }
        }
    }
}

#Preview {
    ContentView()
}
