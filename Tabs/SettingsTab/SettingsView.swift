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
    @State private var showClearLogsConfirmation = false

    @State private var isExporting = false
    @State private var exportURL: URL? = nil
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    @State private var showShareSheet = false
    @State private var exportDays = 7

    private var appVersion: String {
        let version =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "–"
        let build =
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }

    var notificationStatusRow: some View {
        switch notifications.authorizationStatus {
        case .authorized:
            return AnyView(
                Label("Notifications enabled", systemImage: "bell.fill")
                    .foregroundStyle(.green)
                    .tint(.blue)
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
                        .foregroundStyle(.blue)
                }
            )
        default:
            return AnyView(EmptyView())
        }
    }

    private func exportLogs() async {
        isExporting = true
        do {
            let url = try await LogExporter.shared.exportLogs(
                forDays: exportDays
            )
            exportURL = url
            showShareSheet = true
            Logger.success("Export ready: \(url.lastPathComponent)")
        } catch {
            exportErrorMessage = error.localizedDescription
            showExportError = true
            Logger.error("Export failed: \(error.localizedDescription)")
        }
        isExporting = false
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
                Section("Personal Records") {
                    HStack {
                        Label("Current Streak", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                        Spacer()
                        Text(
                            health.currentStreak == 0
                                ? "–" : "\(health.currentStreak) days"
                        )
                        .bold()
                    }

                    HStack {
                        Label("Best Streak", systemImage: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text(
                            health.bestStreak == 0
                                ? "-" : "\(health.bestStreak) days"
                        )
                        .bold()
                    }
                }
                Section("Reset") {
                    Button("Reset Milestones") {
                        showResetMilestonesConfirmation = true
                    }
                    .foregroundStyle(.blue)
                    .confirmationDialog(
                        "Reset Milestones",
                        isPresented: $showResetMilestonesConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Reset", role: .destructive) {
                            UserDefaults.standard.removeObject(
                                forKey: "firedMilestonesToday"
                            )
                            UserDefaults.standard.removeObject(
                                forKey: "milestoneFiredDate"
                            )
                            Logger.info("Milestones reset")
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text(
                            "This will reset today's milestone notifications. They will fire again as you hit each milestone."
                        )
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
                            UserDefaults.standard.removeObject(
                                forKey: "currentStreak"
                            )
                            UserDefaults.standard.removeObject(
                                forKey: "bestStreak"
                            )
                            UserDefaults.standard.removeObject(
                                forKey: "lastGoalMetDate"
                            )
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text(
                            "This will permanently reset your current and best streak. This cannot be undone."
                        )
                    }
                }
                // MARK: - Debug
                #if DEBUG
                    Section("Debug") {
                        Button("Print Milestone State") {
                            let fired =
                                UserDefaults.standard.array(
                                    forKey: "firedMilestonesToday"
                                ) ?? []
                            let date =
                                UserDefaults.standard.string(
                                    forKey: "milestoneFiredDate"
                                ) ?? "none"
                            Logger.info("Fired milestones: \(fired)")
                            Logger.info("Milestone date: \(date)")
                        }
                        .foregroundStyle(.blue)
                    }
                #endif
                // MARK: - Diagnostics
                Section("Diagnostics") {
                    //Export period picker
                    Picker("Export Period", selection: $exportDays) {
                        Text("Last 3 days").tag(3)
                        Text("Last 7 days").tag(7)
                        Text("Last 14 days").tag(14)
                    }
                    .pickerStyle(.menu)

                    //Export Button
                    Button {
                        Task {
                            await exportLogs()
                        }
                    } label: {
                        HStack {
                            Label(
                                "Export Logs",
                                systemImage: "square.and.arrow.up"
                            )
                            .foregroundStyle(.blue)
                            Spacer()
                            if isExporting {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isExporting)

                    // Clear logs Button
                    Button("Clear Logs", role: .destructive) {
                        showClearLogsConfirmation = true
                    }
                    .confirmationDialog("Are you sure you want to clear all logs?", isPresented: $showClearLogsConfirmation, titleVisibility: .visible){
                        Button("Clear", role: .destructive){
                            LogFileWriter.shared.deleteAllLogFiles()
                            LogExporter.shared.deleteAllExports()
                            exportURL = nil
                            Logger.info("All Logs and Exports cleared by user")
                        }
                        Button("Cancel", role: .cancel){}
                    } message: {
                        Text("This will permanently clear all logs from your system. This cannot be undone")
                    }
                }
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
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export failed", isPresented: $showExportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportErrorMessage)
            }
            .navigationTitle("Settings")
        }

    }
}

#Preview {
    SettingsView(connector: PhoneConnector(), health: HealthManager())
}
