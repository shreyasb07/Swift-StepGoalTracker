//
//  SettingsView.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/10/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var connector: PhoneConnector
    @ObservedObject var health: HealthManager
    @ObservedObject var notifications = NotificationManager.shared
    
    @State private var showResetMilestonesConfirmation = false
    @State private var showResetStreakConfirmation = false
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }

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
                //MARK: - Goal
                Section("Daily Goal") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Step Goal")
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
                                Text("steps / day")
                                    .font(.caption2)
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
                Section("Notifications") {
                    notificationStatusRow
                }
                
                //MARK: - Personal Records
                Section("Personal Records"){
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
                        Text(health.bestStreak == 0 ? "-" : "\(health.bestStreak) days")
                            .bold()
                    }
                }
                Section("Reset") {
                    Button("Reset Milestones") {
                        showResetMilestonesConfirmation = true
                    }
                    .confirmationDialog(
                        "Reset Milestones",
                        isPresented: $showResetMilestonesConfirmation,
                        titleVisibility: .visible
                    ){
                        Button("Reset", role: .destructive){
                            UserDefaults.standard.removeObject(forKey: "firedMilestonesToday")
                            UserDefaults.standard.removeObject(forKey: "milestoneFiredDate")
                            Logger.info("Milestones reset")
                        }
                        Button("Cancel", role: .cancel){}
                    } message: {
                        Text("This will reset today's milestone notifications. They will fire again as you hit each milestone.")
                    }
                    Button("Reset Streak", role: .destructive) {
                        showResetStreakConfirmation = true
                    }
                    .confirmationDialog(
                        "Reset Streak",
                        isPresented: $showResetStreakConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Reset", role: .destructive) {
                            UserDefaults.standard.removeObject(forKey: "currentStreak")
                            UserDefaults.standard.removeObject(forKey: "bestStreak")
                            UserDefaults.standard.removeObject(forKey: "lastGoalMetDate")
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will permanently reset your current and best streak. This cannot be undone.")
                    }
                }
                // MARK: - Debug
                                #if DEBUG
                                Section("Debug") {
                                    Button("Print Milestone State") {
                                        let fired = UserDefaults.standard.array(forKey: "firedMilestonesToday") ?? []
                                        let date = UserDefaults.standard.string(forKey: "milestoneFiredDate") ?? "none"
                                        Logger.info("Fired milestones: \(fired)")
                                        Logger.info("Milestone date: \(date)")
                                    }
                                }
                                #endif
                // MARK: - About
                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle("Settings")
        }
        
    }
}

#Preview {
    SettingsView(connector: PhoneConnector(), health: HealthManager())
}
