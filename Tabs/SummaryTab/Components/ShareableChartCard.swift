//
//  ShareableChartCard.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/18/26.
//

import SwiftUI

struct ShareableChartCard: View {
    let days: [HealthManager.DayStep]
    let goal: Double
    let currentStreak: Int
    let period: SummaryPeriod
    let date: Date = Date()

    private var average: Double {
        let activeDays = days.filter { !$0.isFuture && $0.steps > 0 }
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.map(\.steps).reduce(0, +) / Double(activeDays.count)
    }

    private var daysGoalHit: Int {
        days.filter { !$0.isFuture && $0.steps >= goal }.count
    }

    // ← dynamic denominator based on period
    private var daysGoalHitText: String {
        switch period {
        case .week:
            return "\(daysGoalHit)/7"
        case .month:
            let totalDays = days.filter { !$0.isFuture }.count
            return "\(daysGoalHit)/\(totalDays)"
        }
    }

    private var bestDay: HealthManager.DayStep? {
        days.max(by: { $0.steps < $1.steps })
    }

    private static let weekHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private var weekHeader: String {
        let calendar = Calendar.mondayFirst
        let today = calendar.startOfDay(for: Date())
        let startOfWeek = calendar.date(byAdding: .day, value: -6, to: today)!
        return "Week of \(Self.weekHeaderFormatter.string(from: startOfWeek))"
    }

    private var cardSubtitle: String {
        switch period {
        case .week:
            weekHeader
        case .month:
            monthHeader
        }
    }

    private var monthHeader: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
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
                        Text(cardSubtitle)  // ← dynamic subtitle
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: period == .week ? "chart.bar.fill" : "calendar")
                        .font(.title)
                        .foregroundStyle(.blue)
                }

                // MARK: - Chart
                switch period {
                case .week:
                    WeeklyStepsChart(days: days, goal: goal)
                        .frame(height: 400)
                case .month:
                    MonthlyStepsChart(days: days, goal: goal, isShareable: true)
                        .frame(height: 400)
                }

                // MARK: - Stats Row
                HStack(spacing: 0) {
                    statItem(
                        value: "\(Int(average))",
                        label: "Avg Steps",
                        icon: "chart.bar.fill",
                        color: .blue
                    )

                    Divider()
                        .frame(height: 40)

                    statItem(
                        value: daysGoalHitText,
                        label: "Goal Hit",
                        icon: "checkmark.seal.fill",
                        color: .green
                    )

                    Divider()
                        .frame(height: 40)

                    statItem(
                        value: currentStreak == 0 ? "–" : "\(currentStreak)",
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
                    Text(cardSubtitle)
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
}

#Preview {
    VStack(spacing: 20) {
        // Week preview
        ShareableChartCard(
            days: [
                .init(label: "Mon", dayNumber: "1", steps: 6200, isToday: false, isFuture: false),
                .init(label: "Tue", dayNumber: "2", steps: 9800, isToday: false, isFuture: false),
                .init(label: "Wed", dayNumber: "3", steps: 4100, isToday: false, isFuture: false),
                .init(label: "Thu", dayNumber: "4", steps: 11200, isToday: false, isFuture: false),
                .init(label: "Fri", dayNumber: "5", steps: 0, isToday: false, isFuture: false),
                .init(label: "Sat", dayNumber: "6", steps: 3300, isToday: false, isFuture: false),
                .init(label: "Sun", dayNumber: "7", steps: 8000, isToday: true, isFuture: false),
            ],
            goal: 10000,
            currentStreak: 5,
            period: .week
        )

        // Month preview
        ShareableChartCard(
            days: (1...21).map { day in
                HealthManager.DayStep(
                    label: "Mon",
                    dayNumber: "\(day)",
                    steps: Double.random(in: 4000...14000),
                    isToday: day == 21,
                    isFuture: false
                )
            } + (22...31).map { day in
                HealthManager.DayStep(
                    label: "Mon",
                    dayNumber: "\(day)",
                    steps: 0,
                    isToday: false,
                    isFuture: true
                )
            },
            goal: 10000,
            currentStreak: 5,
            period: .month
        )
    }
    .padding()
}
