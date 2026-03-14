//
//  SummaryView.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/10/26.
//

import SwiftUI

struct SummaryView: View {
    @ObservedObject var connector: PhoneConnector
    @ObservedObject var health: HealthManager
    
    private var daysGoalHit: Int {
            health.weeklySteps.filter { $0.steps >= connector.stepGoal }.count
        }
    
    private var weeklyAverage: Double {
            let activeDays = health.weeklySteps.filter { $0.steps > 0 }
            guard !activeDays.isEmpty else { return 0 }
            return activeDays.map(\.steps).reduce(0, +) / Double(activeDays.count)
        }
    
    private var bestDay: HealthManager.DayStep? {
            health.weeklySteps.max(by: { $0.steps < $1.steps })
        }
    
    var body: some View {
        NavigationStack {
            List {
                //MARK: - Weekly Chart
                Section {
                    WeeklyStepsChart(days: health.weeklySteps, goal: connector.stepGoal)
                }
                //MARK: - Weekly Stats
                Section("This Week") {
                    HStack {
                        Label("Days Goal Hit", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Text(daysGoalHit == 0 ? "–" : "\(daysGoalHit) / 7 days")
                            .bold()
                    }

                    HStack {
                        Label("Weekly Average", systemImage: "chart.bar.fill")
                            .foregroundStyle(.blue)
                        Spacer()
                        Text(weeklyAverage == 0 ? "–" : "\(Int(weeklyAverage)) steps")
                            .bold()
                    }

                    HStack {
                        Label("Best Day", systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                        Spacer()
                        if let best = bestDay, best.steps > 0 {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(best.steps)) steps")
                                    .bold()
                                Text(best.label)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("–")
                                .bold()
                        }
                    }
                }

                // MARK: - Streak Summary
                Section("Streaks") {
                    HStack {
                        Label("Current Streak", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                        Spacer()
                        Text(health.currentStreak == 0 ? "–" : "\(health.currentStreak) days")
                            .bold()
                    }

                    HStack {
                        Label("Best Streak", systemImage: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text(health.bestStreak == 0 ? "–" : "\(health.bestStreak) days")
                            .bold()
                    }
                }
            }
                .navigationTitle("Summary")
        }
    }
}

#Preview {
    SummaryView(connector: PhoneConnector(), health: HealthManager())
}
