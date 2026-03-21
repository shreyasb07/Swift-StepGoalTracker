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

    private var maxSteps: Double {
        let actualMax = days.filter { !$0.isFuture }.map(\.steps).max() ?? 0
        return max(actualMax, goal) * 1.1
    }

    private var maxStepDay: HealthManager.DayStep? {
        days.filter { !$0.isFuture }.max(by: { $0.steps < $1.steps })
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(days) { day in
                            BarColumn(
                                day: day,
                                isMaxDay: day.id == maxStepDay?.id,
                                barColor: barColor(for: day),
                                heightRatio: barHeightRatio(for: day),
                                useDayNumber: true
                            )
                            .frame(width: 28)
                            .id(day.id)
                        }
                    }
                    .frame(height: 300)
                    .overlay(alignment: .bottom) {
                        GoalLine(goalRatio: CGFloat(goal / maxSteps))
                    }
                    .padding(.horizontal, 4)
                }
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.85),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .onAppear { 
                    if let today = days.first(where: { $0.isToday }) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo(today.id, anchor: .center)
                        }
                    }
                }
            }

            GoalLegend(goal: goal)
        }
        .padding(.vertical, 4)
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
            return HealthManager.DayStep(
                label: labelFormatter.string(from: day),
                dayNumber: dayNumberFormatter.string(from: day),
                steps: isFuture ? 0 : Double.random(in: 3000...15000),
                isToday: calendar.isDateInToday(day),
                isFuture: isFuture
            )
        }
    }

    var body: some View {
        List {
            Section("This Month") {
                MonthlyStepsChart(days: mockDays, goal: 10000)
            }
        }
    }
}
