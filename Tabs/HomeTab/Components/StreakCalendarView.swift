//
//  StreakCalendarView.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/24/26.
//

import SwiftUI

struct StreakCalendarView: View {
    let goal: Double
    let currentStreak: Int
    let bestStreak: Int
    @Binding var isPresented: Bool

    @ObservedObject var health: HealthManager
    @ObservedObject var connector: PhoneConnector

    @State private var monthOffset: Int = 0
    @State private var monthlySteps: [HealthManager.DayStep] = []
    @State private var isLoading = false

    //MARK: Weekday Symbols
    private var weekdaySymbols: [String] {
        var symbols = Calendar.current.veryShortWeekdaySymbols
        let sunday = symbols.removeFirst()
        symbols.append(sunday)
        return symbols
    }

    //MARK: Leading empty cells
    private var leadingEmptyCells: Int {
        let calendar = Calendar.mondayFirst
        let today = calendar.startOfDay(for: Date())
        guard
            let targetDate = calendar.date(
                byAdding: .month,
                value: monthOffset,
                to: today
            ),
            let startOfMonth = calendar.dateInterval(
                of: .month,
                for: targetDate
            )?
            .start
        else {
            return 0
        }
        let weekday = calendar.component(.weekday, from: startOfMonth)
        return (weekday + 5) % 7
    }

    //MARK: computed stats
    private var daysGoalHit: Int {
        monthlySteps.filter { !$0.isFuture && $0.steps >= goal }.count
    }

    private var totalActiveDays: Int {
        monthlySteps.filter { !$0.isFuture }.count
    }

    private func goalHit(at index: Int) -> Bool {
        guard index >= 0 && index < monthlySteps.count else { return false }
        let day = monthlySteps[index]
        return !day.isFuture && day.steps >= goal
    }

    private func isStartOfStreak(at index: Int) -> Bool {
        goalHit(at: index) && !goalHit(at: index - 1)
    }

    private func isEndOfStreak(at index: Int) -> Bool {
        goalHit(at: index) && !goalHit(at: index + 1)
    }

    private func isMidStreak(at index: Int) -> Bool {
        goalHit(at: index) && goalHit(at: index - 1) && goalHit(at: index + 1)
    }

    //MARK: Month Title
    private var monthTitle: String {
        let calendar = Calendar.mondayFirst
        let today = calendar.startOfDay(for: Date())
        guard
            let targetDate = calendar.date(
                byAdding: .month,
                value: monthOffset,
                to: today
            )
        else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: targetDate)
    }

    private var isCurrentMonth: Bool { monthOffset == 0 }

    // MARK: - Load Month Data
    private func loadMonth() async {
        isLoading = true
        await health.fetchSelectedMonth(offset: monthOffset, goal: goal)
        monthlySteps = health.selectedMonthlySteps
        isLoading = false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            Divider()
            navigationView
            weekdayLabelsView
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                calendarGridView
            }
            Divider()
            legendView
            Divider()
            streakStatsView
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .onAppear {
            Task {
                await loadMonth()
            }
        }
        .onChange(of: monthOffset) { _, _ in
            Task { await loadMonth() }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Streak Calendar")
                    .font(.headline.bold())
                Text("\(daysGoalHit) / \(totalActiveDays) days goal hit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Navigation
    private var navigationView: some View {
        PeriodNavigationHeader(
            title: monthTitle,
            canGoForward: !isCurrentMonth,
            onBack: { monthOffset -= 1 },
            onForward: { monthOffset += 1 }
        )
    }

    // MARK: - Month Title
    private var monthTitleView: some View {
        Text(monthTitle)
            .font(.subheadline.bold())
            .foregroundStyle(.primary)
    }

    // MARK: - Weekday Labels
    private var weekdayLabelsView: some View {
        HStack(spacing: 4) {
            ForEach(weekdaySymbols, id: \.self) { label in
                Text(label)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func isVisualStart(at index: Int) -> Bool {
        guard goalHit(at: index) else { return false }
        let day = monthlySteps[index].date
        let isMonday = Calendar.mondayFirst.component(.weekday, from: day) == 2

        // Visual start if: It's the technical start OR it's a Monday (start of row)
        return isStartOfStreak(at: index) || isMonday
    }

    private func isVisualEnd(at index: Int) -> Bool {
        guard goalHit(at: index) else { return false }
        let day = monthlySteps[index].date
        let isSunday = Calendar.mondayFirst.component(.weekday, from: day) == 1

        // Visual end if: It's the technical end OR it's a Sunday (end of row)
        return isEndOfStreak(at: index) || isSunday
    }

    // MARK: - Calendar Grid
    private var calendarGridView: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 0),
                count: 7
            ),
            spacing: 4
        ) {
            // Leading empty cells
            ForEach(0..<leadingEmptyCells, id: \.self) { _ in
                Color.clear.frame(height: 36)
            }

            // Day cells
            ForEach(monthlySteps.enumerated(), id: \.element.id) { index, day in
                DayCell(
                    day: day,
                    goal: goal,
                    isVisualStart: isVisualStart(at: index),
                    isVisualEnd: isVisualEnd(at: index),
                    isPartOfStreak: goalHit(at: index)
                )
            }
        }
    }

    // MARK: - Legend
    private var legendView: some View {
        HStack(spacing: 12) {
            legendItem(color: .green, label: "Goal hit")
            legendItem(color: .red.opacity(0.3), label: "Missed")
            legendItem(color: .blue.opacity(0.3), label: "Today")
            legendItem(color: .secondary.opacity(0.15), label: "Future")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Streak Stats
    private var streakStatsView: some View {
        HStack(spacing: 0) {
            streakStat(
                value: currentStreak == 0 ? "–" : "\(currentStreak)",
                label: "Current",
                icon: "flame.fill",
                color: .orange
            )
            Divider().frame(height: 40)
            streakStat(
                value: bestStreak == 0 ? "–" : "\(bestStreak)",
                label: "Best",
                icon: "trophy.fill",
                color: .yellow
            )
            Divider().frame(height: 40)
            streakStat(
                value: "\(daysGoalHit)",
                label: "Days Hit",
                icon: "checkmark.seal.fill",
                color: .green
            )
        }
    }

    private func streakStat(
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
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

}

// MARK: - Day Cell
struct DayCell: View {
    let day: HealthManager.DayStep
    let goal: Double
    let isVisualStart: Bool
    let isVisualEnd: Bool
    let isPartOfStreak: Bool

    private var cellColor: Color {
        if day.isFuture { return Color.secondary.opacity(0.15) }
        if day.steps >= goal { return .green }
        if day.isToday { return .blue.opacity(0.3) }
        if day.steps > 0 { return .red.opacity(0.3) }
        return Color.secondary.opacity(0.15)
    }

    private var icon: String? {
        if day.isFuture { return nil }
        if day.steps >= goal { return "checkmark" }
        if day.isToday { return "figure.walk" }
        if day.steps > 0 { return "xmark" }
        return nil
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if isPartOfStreak {
                    streakBackground
                }
                // Day circle
                Circle()
                    .fill(cellColor)
                    .frame(width: 28, height: 28)
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(day.steps >= goal ? .white : .primary)
                } else if day.isFuture {
                    Text(day.dayNumber)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                }
            }

            Text(day.dayNumber)
                .font(.system(size: 8))
                .foregroundStyle(day.isToday ? .blue : .secondary)
                .fontWeight(day.isToday ? .bold : .regular)
        }
    }

    // MARK: - Streak Background Connector
    @ViewBuilder
    private var streakBackground: some View {
        let roundedRectShape = UnevenRoundedRectangle(
            topLeadingRadius: isVisualStart ? 14 : 0,
            bottomLeadingRadius: isVisualStart ? 14 : 0,
            bottomTrailingRadius: isVisualEnd ? 14 : 0,
            topTrailingRadius: isVisualEnd ? 14 : 0
        )
        Rectangle()
            // Single day streak — just the circle, no connector
            .fill(Color.green.opacity(0.5))
            .overlay(
                roundedRectShape.stroke(
                    Color.white.opacity(1),
                    lineWidth: 0.2
                )
            )
            .clipShape(roundedRectShape)
            .padding(.leading, isVisualStart ? 4 : 0)
            .padding(.trailing, isVisualEnd ? 4 : 0)
            .frame(height: 35)
            .shadow(radius: 10)
    }
}

#Preview {
    StreakCalendarPreview()
}
private struct StreakCalendarPreview: View {
    @StateObject private var health = MockHealthManager()
    @StateObject private var connector = PhoneConnector()

    // Injects mock data without hitting HealthKit
    private class MockHealthManager: HealthManager {
        private var mockDays: [DayStep] {
            let calendar = Calendar.mondayFirst
            let today = calendar.startOfDay(for: Date())
            guard
                let startOfMonth = calendar.dateInterval(
                    of: .month,
                    for: today
                )?.start,
                let daysInMonth = calendar.range(
                    of: .day,
                    in: .month,
                    for: today
                )?.count
            else { return [] }

            let dayNumberFormatter = DateFormatter()
            dayNumberFormatter.dateFormat = "d"
            let labelFormatter = DateFormatter()
            labelFormatter.dateFormat = "EEE"

            return (0..<daysInMonth).compactMap { offset in
                guard
                    let day = calendar.date(
                        byAdding: .day,
                        value: offset,
                        to: startOfMonth
                    )
                else { return nil }
                let isFuture = day > today
                return DayStep(
                    date: day,
                    label: labelFormatter.string(from: day),
                    dayNumber: dayNumberFormatter.string(from: day),
                    steps: isFuture ? 0 : Double.random(in: 3000...15000),
                    isToday: calendar.isDateInToday(day),
                    isFuture: isFuture
                )
            }
        }
        // Override to inject mock data instead of hitting HealthKit
        override func fetchSelectedMonth(offset: Int, goal: Double) async {
            selectedMonthlySteps = mockDays
            selectedMonthOffset = offset
        }
    }

    var body: some View {
        ScrollView {
            StreakCalendarView(
                goal: 10000,
                currentStreak: 7,
                bestStreak: 14,
                isPresented: .constant(true),
                health: health,
                connector: connector
            )
            .padding()
        }
    }
}
