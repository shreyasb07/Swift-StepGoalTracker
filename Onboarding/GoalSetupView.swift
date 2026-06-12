//
//  GoalSetupView.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/28/26.
//

import SwiftUI

struct GoalSetupView: View {
    @ObservedObject var connector: PhoneConnector
    @ObservedObject var healthManager: HealthManager
    @ObservedObject var notificationManager = NotificationManager.shared

    @EnvironmentObject var launchManager: AppLaunchManager

    @State private var selectedGoal: Int = 10000
    @State private var notificationsEnabled: Bool = true
    @State private var isRequestingPermissions: Bool = false

    //MARK: Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .padding(.vertical, 8)
            Text("Welcome to Stepido")
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // Sub-description
            Text(
                "Your steps. Your goals. Your streak."
            )
            .font(.headline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 32)
    }

    //MARK: GoalPicker Section
    private var goalPickerSection: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Daily Step Goal")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
//                    .kerning(1)

                HStack {
                    Button {
                        let newGoal = max(1000, connector.stepGoal - 500)
                        connector.stepGoal = newGoal
                        connector.updateGoal(newGoal: newGoal)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    VStack(spacing: 2) {
                        Text("\(Int(connector.stepGoal))")
                            .font(.title.monospacedDigit())
                            .bold()
                            .contentTransition(.numericText())
                            .animation(.spring(duration: 0.3), value: connector.stepGoal)
                        Text("steps / day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        let newGoal = min(50000, connector.stepGoal + 500)
                        connector.stepGoal = newGoal
                        connector.updateGoal(newGoal: newGoal)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // ✅ now inside the outer VStack — single return value
            Text("You can always change this later in App Settings")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.bottom, 32)
        }
    }

    //MARK: NotificationSection
    private var notificationSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Reminders")
                    .font(.body)
                    .fontWeight(.medium)
                Text("We'll nudge you to hit your goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $notificationsEnabled)
                .tint(Color("motivationText"))
                .labelsHidden()
        }
        .padding(16)
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    //MARK: Start Button
    private var startButton: some View {
        Button {
            Task { await completeSetup() }
        } label: {
            Group {
                if isRequestingPermissions {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Get Started")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("motivationText"))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isRequestingPermissions)
    }

    //MARK: Actions
    private func completeSetup() async {
        isRequestingPermissions = true

        // Request HealthKit permission
        healthManager.requestAuthorization(goal: Double(selectedGoal))

        // Request notification permission if enabled
        if notificationsEnabled {
            notificationManager.requestAuthorization()
        }

        launchManager.completeGoalSetup(
            goal: selectedGoal,
            notificationsEnabled: notificationsEnabled
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                headerSection
                goalPickerSection
                notificationSection
                Spacer()
                Text("Let Stepido keep you motivated,\nevery single day")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                startButton
            }
            .padding()
        }
    }
}

#Preview {
    GoalSetupView(connector: PhoneConnector(), healthManager: HealthManager())
}
