//
//  SummaryView.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/10/26.
//

import SwiftUI

struct SummaryView: View {
    @ObservedObject var connector: PhoneConnector
    @ObservedObject var health: HealthManager

    @State private var shareImage: UIImage? = nil
    @State private var weekOffset: Int = 0
    @State private var monthOffset: Int = 0
    @State private var selectedPeriod: SummaryPeriod = .week

    // MARK: - Week Computed Properties
    private var weekNavigationTitle: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard
            let targetDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today),
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: targetDate)?.start,
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)
        else { return "This Week" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        if weekOffset == 0 { return "This Week" }
        if weekOffset == -1 { return "Last Week" }
        return "\(formatter.string(from: startOfWeek)) – \(formatter.string(from: endOfWeek))"
    }

    private var weekSectionTitle: String {
        weekOffset == 0 ? "This Week" : weekNavigationTitle
    }

    private var daysGoalHit: Int {
        health.selectedWeekSteps.filter { !$0.isFuture && $0.steps >= connector.stepGoal }.count
    }

    private var daysGoalHitText: String {
        daysGoalHit == 0 ? "–" : "\(daysGoalHit) / 7 days"
    }

    private var weeklyAverage: Double {
        let activeDays = health.selectedWeekSteps.filter { !$0.isFuture && $0.steps > 0 }
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.map(\.steps).reduce(0, +) / Double(activeDays.count)
    }

    private var weeklyAverageText: String {
        weeklyAverage == 0 ? "–" : "\(Int(weeklyAverage)) steps"
    }

    private var weekBestDay: HealthManager.DayStep? {
        health.selectedWeekSteps.filter { !$0.isFuture }.max(by: { $0.steps < $1.steps })
    }

    private var weekBestDayText: String {
        guard let best = weekBestDay, best.steps > 0 else { return "–" }
        return "\(Int(best.steps)) steps"
    }

    // MARK: - Month Computed Properties
    private var monthNavigationTitle: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let targetDate = calendar.date(byAdding: .month, value: monthOffset, to: today)
        else { return "This Month" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        if monthOffset == 0 { return "This Month" }
        if monthOffset == -1 { return "Last Month" }
        return formatter.string(from: targetDate)
    }

    private var monthSectionTitle: String {
        monthOffset == 0 ? "This Month" : monthNavigationTitle
    }

    private var monthDaysGoalHit: Int {
        health.selectedMonthlySteps.filter { !$0.isFuture && $0.steps >= connector.stepGoal }.count
    }

    private var monthDaysGoalHitText: String {
        guard
            let targetDate = Calendar.current.date(byAdding: .month, value: monthOffset, to: Calendar.current.startOfDay(for: Date())),
            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: targetDate)?.count
        else { return "–" }
        return monthDaysGoalHit == 0 ? "–" : "\(monthDaysGoalHit) / \(daysInMonth) days"
    }

    private var monthlyAverage: Double {
        let activeDays = health.selectedMonthlySteps.filter { !$0.isFuture && $0.steps > 0 }
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.map(\.steps).reduce(0, +) / Double(activeDays.count)
    }

    private var monthlyAverageText: String {
        monthlyAverage == 0 ? "–" : "\(Int(monthlyAverage)) steps"
    }

    private var monthBestDay: HealthManager.DayStep? {
        health.selectedMonthlySteps.filter { !$0.isFuture }.max(by: { $0.steps < $1.steps })
    }

    private var monthBestDayText: String {
        guard let best = monthBestDay, best.steps > 0 else { return "–" }
        return "\(Int(best.steps)) steps"
    }

    // MARK: - Streak
    private var currentStreakText: String {
        health.currentStreak == 0 ? "–" : "\(health.currentStreak) days"
    }

    private var bestStreakText: String {
        health.bestStreak == 0 ? "–" : "\(health.bestStreak) days"
    }

    // MARK: - Sections
    private var periodSelectorSection: some View {
        Section {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(SummaryPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var weeklyNavigationSection: some View {
        Section {
            PeriodNavigationHeader(
                title: weekNavigationTitle,
                canGoForward: weekOffset < 0,
                onBack: {
                    weekOffset -= 1
                    Task { await health.fetchSelectedWeek(offset: weekOffset, goal: connector.stepGoal) }
                },
                onForward: {
                    weekOffset += 1
                    Task { await health.fetchSelectedWeek(offset: weekOffset, goal: connector.stepGoal) }
                }
            )
        }
    }

    private var weeklyChartSection: some View {
        Section {
            WeeklyStepsChart(days: health.selectedWeekSteps, goal: connector.stepGoal)
        }
    }

    private var weeklyStatsSection: some View {
        Section(weekSectionTitle) {
            StatRow(label: "Days Goal Hit", icon: "checkmark.seal.fill", color: .green, value: daysGoalHitText)
            StatRow(label: "Weekly Average", icon: "chart.bar.fill", color: .blue, value: weeklyAverageText)
            BestDayRow(stepText: weekBestDayText, dayLabel: weekBestDay?.label ?? "", isMonthView: false)
        }
    }

    private var monthlyNavigationSection: some View {
        Section {
            PeriodNavigationHeader(
                title: monthNavigationTitle,
                canGoForward: monthOffset < 0,
                onBack: {
                    monthOffset -= 1
                    Task { await health.fetchSelectedMonth(offset: monthOffset, goal: connector.stepGoal) }
                },
                onForward: {
                    monthOffset += 1
                    Task { await health.fetchSelectedMonth(offset: monthOffset, goal: connector.stepGoal) }
                }
            )
        }
    }

    private var monthlyChartSection: some View {
        Section {
            MonthlyStepsChart(days: health.selectedMonthlySteps, goal: connector.stepGoal)
        }
    }

    private var monthlyStatsSection: some View {
        Section(monthSectionTitle) {
            StatRow(label: "Days Goal Hit", icon: "checkmark.seal.fill", color: .green, value: monthDaysGoalHitText)
            StatRow(label: "Monthly Average", icon: "chart.bar.fill", color: .blue, value: monthlyAverageText)
            BestDayRow(stepText: monthBestDayText, dayLabel: monthBestDay?.dayNumber ?? "", isMonthView: true)
        }
    }

    private var streakSection: some View {
        Section("Streaks") {
            StatRow(label: "Current Streak", icon: "flame.fill", color: .orange, value: currentStreakText)
            StatRow(label: "Best Streak", icon: "trophy.fill", color: .yellow, value: bestStreakText)
            if weekOffset != 0 || monthOffset != 0 {
                Text("Streak reflects current status, not the selected period.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if let image = shareImage {
                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview("My Step Progress", image: Image(uiImage: image))
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
            } else {
                ProgressView().scaleEffect(0.8)
            }
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                periodSelectorSection
                switch selectedPeriod {
                case .week:
                    weeklyNavigationSection
                    weeklyChartSection
                    weeklyStatsSection
                    streakSection
                case .month:
                    monthlyNavigationSection
                    monthlyChartSection
                    monthlyStatsSection
                    streakSection
                }
            }
            .navigationTitle("Summary")
            .toolbar { toolbarContent }
            .onAppear {
                weekOffset = 0
                monthOffset = 0
                Task {
                    await health.fetchSelectedWeek(offset: 0, goal: connector.stepGoal)
                    await health.fetchSelectedMonth(offset: 0, goal: connector.stepGoal)
                    await renderShareImage()
                }
            }
            .onChange(of: health.selectedWeekSteps) { _, _ in Task { await renderShareImage() } }
            .onChange(of: health.selectedMonthlySteps) { _, _ in Task { await renderShareImage() } }
            .onChange(of: connector.stepGoal) { _, _ in Task { await renderShareImage() } }
            .onChange(of: selectedPeriod) { _, _ in Task { await renderShareImage() } }
        }
    }

    // MARK: - Render
    private func renderShareImage() async {
        switch selectedPeriod {
        case .week:
            let card = ShareableChartCard(days: health.selectedWeekSteps, goal: connector.stepGoal, currentStreak: health.currentStreak, period: .week)
            shareImage = await ViewImageRenderer.shared.render(view: card, size: CGSize(width: 360, height: 550))
        case .month:
            let card = ShareableChartCard(days: health.selectedMonthlySteps, goal: connector.stepGoal, currentStreak: health.currentStreak, period: .month)
            shareImage = await ViewImageRenderer.shared.render(view: card, size: CGSize(width: 360, height: 550))
        }
    }
}

#Preview {
    SummaryView(connector: PhoneConnector(), health: HealthManager())
}
