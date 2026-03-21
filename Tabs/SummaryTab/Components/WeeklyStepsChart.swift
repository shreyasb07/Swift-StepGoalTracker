//
//  WeeklyStepsChart.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/6/26.
//

import SwiftUI

struct WeeklyStepsChart: View {
    let days: [HealthManager.DayStep]
    let goal: Double

    private var maxSteps: Double {
        max(days.map(\.steps).max() ?? 0, goal) * 1.1
    }

    private func barHeight(steps: Double, in maxHeight: CGFloat) -> CGFloat {
        guard maxSteps > 0 else { return 2 }
        let ratio = CGFloat(steps / maxSteps)
        return max(ratio * maxHeight, steps > 0 ? 4 : 2)
    }

    private func barColor(for day: HealthManager.DayStep) -> Color {
        if day.isFuture { return .clear }
        if day.steps >= goal { return .green }
        if day.isToday { return .green.opacity(0.5) }
        return .red.opacity(0.3)
    }

    private func barHeightRatio(for day: HealthManager.DayStep) -> CGFloat {
        if day.isFuture { return 0 }
        guard maxSteps > 0 else { return 0 }
        return CGFloat(day.steps / maxSteps)
    }

    private var maxStepDay: HealthManager.DayStep? {
        days.max(by: { $0.steps < $1.steps })
    }

    private var weeklyAverage: Double {
        let activeDays = days.filter { $0.steps >= 0 }
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.map(\.steps).reduce(0, +) / Double(activeDays.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 3) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Avg \(Int(weeklyAverage)) steps")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(days) { day in
                    BarColumn(
                        day: day,
                        isMaxDay: day.id == maxStepDay?.id,
                        barColor: barColor(for: day),
                        heightRatio: barHeightRatio(for: day)
                    )
                }
            }
            .frame(height: 300)
            .overlay(alignment: .bottom) {
                GoalLine(goalRatio: CGFloat(goal / maxSteps))
            }
            GoalLegend(goal: goal)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let mockDays: [HealthManager.DayStep] = [
        .init(label: "Mon", dayNumber: "1", steps: 6200, isToday: false, isFuture: false),
        .init(label: "Tue", dayNumber: "2", steps: 9800, isToday: false, isFuture: false),
        .init(label: "Wed", dayNumber: "3", steps: 4100, isToday: false, isFuture: false),
        .init(label: "Thu", dayNumber: "4", steps: 11200, isToday: false, isFuture: false),
        .init(label: "Fri", dayNumber: "5", steps: 0, isToday: false, isFuture: false),
        .init(label: "Sat", dayNumber: "6", steps: 3300, isToday: false, isFuture: false),
        .init(label: "Sun", dayNumber: "7", steps: 8000, isToday: true, isFuture: false),
        .init(label: "Mon", dayNumber: "8", steps: 0, isToday: false, isFuture: true),
    ]
    List {
        Section("This Week") {
            WeeklyStepsChart(days: mockDays, goal: 8000)
        }
    }
}
