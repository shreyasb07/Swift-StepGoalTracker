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
        if day.steps >= goal { return .green }
        if day.isToday { return .green.opacity(0.5) }
        return .red.opacity(0.3)
    }
    
    private func barHeightRatio(for steps: Double) -> CGFloat {
            guard maxSteps > 0 else { return 0 }
            return CGFloat(steps / maxSteps)
        }
    
    private var maxStepDay: HealthManager.DayStep? {
        days.max(by: { $0.steps < $1.steps })
    }
    
    private var weeklyAverage: Double {
        let activeDays = days.filter { $0.steps >= 0}
        guard !activeDays.isEmpty else {return 0}
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
                        heightRatio: barHeightRatio(for: day.steps)
                    )
                }
            }
            .frame(height: 200)
            .overlay(alignment: .bottom){
                GoalLine(goalRatio: CGFloat(goal / maxSteps))
            }
            GoalLegend(goal: goal)
        }
        .padding(.vertical, 4)
    }
    }

struct BarLabel: View {
    let day: HealthManager.DayStep
    let isMaxDay: Bool

    var body: some View {
        if day.steps >= 0 {
            Text("\(Int(day.steps))")
                .font(.system(size: 9, weight: day.isToday ? .semibold : .regular).monospacedDigit())
                .foregroundStyle(day.isToday ? .blue : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

struct BarColumn: View {
    let day: HealthManager.DayStep
    let isMaxDay: Bool
    let barColor: Color
    let heightRatio: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            BarLabel(day: day, isMaxDay: isMaxDay)
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 5)
                        .fill(barColor)
                        .frame(height: min(max(geo.size.height * heightRatio, heightRatio > 0 ? 4 : 2), geo.size.height))
                }
            }
            Divider()
                .frame(height: 1)
                .background(Color.secondary.opacity(0.3))
            
            Spacer().frame(height: 6)
            
            Text(day.label)
                .font(.system(size: 11, weight: day.isToday ? .bold : .regular ))
                .foregroundStyle(day.isToday ? .primary : .secondary)
        }
    }
}

struct GoalLine: View {
    let goalRatio: CGFloat
    let topOffset: CGFloat = 13
    let bottomOffset: CGFloat = 25

    var body: some View {
        GeometryReader { geo in
            let barAreaHeight = geo.size.height - topOffset - bottomOffset
            let yPosition = topOffset + barAreaHeight * (1 - goalRatio)
            Rectangle()
                .fill(Color.orange)
                .frame(height: 1.5)
                .offset(y: yPosition)
        }
    }
}

struct GoalLegend: View {
    let goal: Double

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.orange.opacity(0.7))
                .frame(width: 16, height: 3)
            Text("Goal: \(Int(goal)) steps")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let mockDays: [HealthManager.DayStep] = [
        .init(label: "Mon", steps: 6200, isToday: false),
        .init(label: "Tue", steps: 9800, isToday: false),
        .init(label: "Wed", steps: 4100, isToday: false),
        .init(label: "Thu", steps: 11200, isToday: false),
        .init(label: "Fri", steps: 0, isToday: false),
        .init(label: "Sat", steps: 3300, isToday: false),
        .init(label: "Sun", steps: 8000, isToday: true),
    ]
    List {
        Section("This Week") {
            WeeklyStepsChart(days: mockDays, goal: 8000)
        }
    }
}
