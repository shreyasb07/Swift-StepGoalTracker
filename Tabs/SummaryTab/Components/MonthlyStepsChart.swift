//
//  MonthlyStepsChart.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/20/26.
//

import SwiftUI

struct MonthlyStepsChart: View {
    let days: [HealthManager.DayStep]
    let goal: Double
    var isShareable: Bool = false

    private var maxSteps: Double {
        let actualMax = days.filter { !$0.isFuture }.map(\.steps).max() ?? 0
        return max(actualMax, goal) * 1.1
    }

    private func barHeightRatio(for day: HealthManager.DayStep) -> CGFloat {
        if day.isFuture { return 0 }
        guard maxSteps > 0 else { return 0 }
        return CGFloat(day.steps / maxSteps)
    }

    private func barColor(for day: HealthManager.DayStep) -> Color {
        if day.isFuture { return .clear }
        if day.steps >= goal { return .green }
        if day.isToday { return .blue.opacity(0.6) }
        return .red.opacity(0.3)
    }

    // Y axis reference values
    private var yAxisValues: [Double] {
        let step = (maxSteps / 3 / 1000).rounded(.up) * 1000
        return [step, step * 2, step * 3]
    }

    // Week start day numbers for X axis labels
    private var weekMarkers: [String] {
        days.filter { day in
            guard let num = Int(day.dayNumber) else { return false }
            return num == 1 || num == 8 || num == 15 || num == 22 || num == 29
        }.map(\.dayNumber)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                let barAreaWidth = geo.size.width - 44  // subtract Y axis width
                let barWidth = max(2, barAreaWidth / CGFloat(days.count) - 2)

                ZStack(alignment: .bottomLeading) {
                    // MARK: - Reference Lines + Y Axis
                    VStack(spacing: 0) {
                        ForEach(yAxisValues.reversed(), id: \.self) { value in
                            HStack(spacing: 4) {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(height: 0.5)
                                Text(formatSteps(value))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36, alignment: .trailing)
                            }
                            if value != yAxisValues.first {
                                Spacer()
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)

                    // MARK: - Bars
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(days) { day in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(barColor(for: day))
                                .frame(
                                    width: barWidth,
                                    height: max(
                                        barHeightRatio(for: day) * geo.size.height,
                                        day.steps > 0 && !day.isFuture ? 3 : 0
                                    )
                                )
                                .animation(.easeInOut(duration: 0.5), value: barHeightRatio(for: day))
                        }
                    }
                    .frame(width: barAreaWidth, alignment: .leading)  // ← leading alignment
                }
            }
            .frame(height: 180)

            // MARK: - X Axis — positioned absolutely
            GeometryReader { geo in
                let barAreaWidth = geo.size.width - 44
                let barWidth = max(2, barAreaWidth / CGFloat(days.count) - 2)

                ZStack(alignment: .topLeading) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        if let num = Int(day.dayNumber),
                           [1, 8, 15, 22, 29].contains(num) {
                            Text(day.dayNumber)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .offset(x: CGFloat(index) * (barWidth + 2))
                        }
                    }
                }
            }
            .frame(height: 16)

            // MARK: - Goal Legend
            GoalLegend(goal: goal)
        }
        .padding(.vertical, 4)
    }
    private func formatSteps(_ value: Double) -> String {
        if value >= 1000 {
            return "\(Int(value / 1000))K"
        }
        return "\(Int(value))"
    }
}
#Preview {
    MonthlyStepsChartPreview()
}

private struct MonthlyStepsChartPreview: View {
    private var mockDays: [HealthManager.DayStep] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard
            let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start,
            let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count
        else { return [] }

        let dayNumberFormatter = DateFormatter()
        dayNumberFormatter.dateFormat = "d"

        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "EEE"

        return (0..<daysInMonth).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfMonth)
            else { return nil }
            let isFuture = day > today
            let isToday = calendar.isDateInToday(day)
            return HealthManager.DayStep(
                label: labelFormatter.string(from: day),
                dayNumber: dayNumberFormatter.string(from: day),
                steps: isFuture ? 0 : Double.random(in: 4000...15000),
                isToday: isToday,
                isFuture: isFuture
            )
        }
    }

    var body: some View {
        List {
            // Standard view
            Section("This Month") {
                MonthlyStepsChart(days: mockDays, goal: 10000)
            }

            // Low step days — tests red bars
            Section("Low Activity Month") {
                MonthlyStepsChart(
                    days: mockDays.map { day in
                        HealthManager.DayStep(
                            label: day.label,
                            dayNumber: day.dayNumber,
                            steps: day.isFuture ? 0 : Double.random(in: 2000...6000),
                            isToday: day.isToday,
                            isFuture: day.isFuture
                        )
                    },
                    goal: 10000
                )
            }

            // High step days — tests green bars and Y axis scaling
            Section("High Activity Month") {
                MonthlyStepsChart(
                    days: mockDays.map { day in
                        HealthManager.DayStep(
                            label: day.label,
                            dayNumber: day.dayNumber,
                            steps: day.isFuture ? 0 : Double.random(in: 12000...20000),
                            isToday: day.isToday,
                            isFuture: day.isFuture
                        )
                    },
                    goal: 10000
                )
            }
        }
    }
}
