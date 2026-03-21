//
//  ShareableRingCard.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/18/26.
//

import SwiftUI

struct ShareableRingCard: View {
    let steps: Double
    let goal: Double
    let streak: Int
    let date: Date = Date()

    private var percentage: Int {
        Int(min((steps / goal) * 100, 100))
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)

            VStack(spacing: 20) {
                // MARK: - Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
//                        Text("StepMaster")
//                            .font(.headline.bold())
//                            .foregroundStyle(.primary)
                        Text("Daily Progress")
                            .font(.headline.bold())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "figure.walk.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }
                .padding()

                // MARK: - Ring
                StepProgressRing(steps: steps, goal: goal)
                    .frame(width: 200, height: 200)
                    .padding(.vertical, 30)

                // MARK: - Stats Row
                HStack(spacing: 0) {
                    statItem(
                        value: "\(Int(steps))",
                        label: "Steps",
                        icon: "figure.walk",
                        color: steps >= goal ? .green : .blue
                    )

                    Divider()
                        .frame(height: 40)

                    statItem(
                        value: "\(percentage)%",
                        label: "Goal",
                        icon: "target",
                        color: steps >= goal ? .green : .blue
                    )

                    Divider()
                        .frame(height: 40)

                    statItem(
                        value: streak == 0 ? "–" : "\(streak)",
                        label: "Streak",
                        icon: "flame.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )

                // MARK: - Watermark
                HStack {
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Stepido App")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
        .frame(width: 360)
    }
    private func statItem(
        value: String,
        label: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.subheadline, design: .rounded).monospacedDigit())
                .bold()
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ShareableRingCard(steps: 7500, goal: 10000, streak: 5)
        .padding()
}
