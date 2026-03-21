//
//  HomeView.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/10/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var connector: PhoneConnector
    @ObservedObject var health: HealthManager

    @State private var shareImage: UIImage? = nil

    private var motivationalText: String {
        let percentage = Int((health.stepCount / connector.stepGoal) * 100)
        switch percentage {
        case 0..<1: return "Let's get moving today!"
        case 1..<25: return "Good start, keep it up!"
        case 25..<50: return "You're on your way!"
        case 50..<75: return "Halfway there, don't stop!"
        case 75..<100: return "So close, finish strong!"
        default: return "Goal crushed today!"
        }
    }

    private var motivationalIcon: String {
        let percentage = Int((health.stepCount / connector.stepGoal) * 100)
        switch percentage {
        case 0..<1: return "figure.walk"
        case 1..<25: return "figure.walk.motion"
        case 25..<50: return "figure.run"
        case 50..<75: return "bolt.fill"
        case 75..<100: return "flame.fill"
        default: return "trophy.fill"
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // Pre-render as soon as the view appears and whenever data changes
    private func renderShareImage() async {
        let card = ShareableRingCard(
            steps: health.stepCount,
            goal: connector.stepGoal,
            streak: health.currentStreak
        )
        shareImage = await ViewImageRenderer.shared.render(
            view: card,
            size: CGSize(width: 360, height: 520)
        )
    }

    var body: some View {
        NavigationStack {
            List {
                //MARK: - Progress Ring
                Section {
                    VStack(spacing: 16) {
                        StepProgressRing(
                            steps: health.stepCount,
                            goal: connector.stepGoal
                        )
                        HStack(spacing: 6) {
                            Image(systemName: motivationalIcon)
                                .foregroundStyle(.blue)
                            Text(motivationalText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .animation(.easeInOut, value: motivationalText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                
                // MARK: - Milestone section
                Section("Today's Milestones") {
                    MilestoneProgressRow(
                        steps: health.stepCount,
                        goal: connector.stepGoal
                    )
                    .padding(.vertical, 8)
                }

                // MARK: - Daily Steps
                Section("Today") {
                    HStack {
                        Label("Steps", systemImage: "figure.walk")
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("\(Int(health.stepCount))")
                            .bold()
                            .foregroundStyle(
                                health.stepCount >= connector.stepGoal
                                    ? .green : .blue
                            )
                            .contentTransition(.numericText())
                            .animation(
                                .spring(duration: 0.3),
                                value: health.stepCount
                            )
                    }

                    HStack {
                        Label("Goal", systemImage: "target")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(connector.stepGoal)) steps")
                            .bold()
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Progress", systemImage: "percent")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(
                            "\(Int(min((health.stepCount / connector.stepGoal) * 100, 100)))%"
                        )
                        .bold()
                        .foregroundStyle(
                            health.stepCount >= connector.stepGoal
                                ? .green : .blue
                        )
                    }
                }
                // MARK: - Streak
                Section("Streak") {
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
                                ? "–" : "\(health.bestStreak) days"
                        )
                        .bold()
                    }
                }
            }
            .navigationTitle(greeting)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Group {
                        if let image = shareImage {
                            ShareLink(
                                item: Image(uiImage: image),
                                preview: SharePreview(
                                    "My step Progress",
                                    image: Image(uiImage: image)
                                )
                            ) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        } else {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }

                }
            }
            .refreshable {
                await health.fetchTodaySteps(goal: connector.stepGoal)
            }
            .onAppear {
                Task { await renderShareImage()}
            }
            .onChange(of: health.stepCount) { _, _ in
                Task { await renderShareImage() }
            }
            .onChange(of: connector.stepGoal) { _, _ in
                Task { await renderShareImage() }
            }
        }
    }
}

#Preview {
    HomeView(connector: PhoneConnector(), health: HealthManager())
}
