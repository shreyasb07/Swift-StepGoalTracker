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

    private var weeklyAverage: Double {
        let activeDays = days.filter { $0.steps > 0 }
        guard !activeDays.isEmpty else { return 0 }
        return activeDays.map(\.steps).reduce(0, +) / Double(activeDays.count)
    }

    private var daysGoalHit: Int {
        days.filter { $0.steps >= goal }.count
    }

    private var bestDay: HealthManager.DayStep? {
        days.max(by: { $0.steps < $1.steps })
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
                    Image(systemName: "chart.bar.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }

                // MARK: - Chart
                WeeklyStepsChart(days: days, goal: goal)
                    .frame(height: 400)

                // MARK: - Stats Row
                HStack(spacing: 0) {
                    statItem(
                        value: "\(Int(weeklyAverage))",
                        label: "Avg Steps",
                        icon: "chart.bar.fill",
                        color: .blue
                    )

                    Divider()
                        .frame(height: 40)

                    statItem(
                        value: "\(daysGoalHit)/7",
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
                    Text(weekHeader)
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

    private static let weekHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private var weekHeader: String {
        let calendar = Calendar.current
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
}

#Preview {
    let mockDays: [HealthManager.DayStep] = [
        .init(
            label: "Mon",
            dayNumber: "1",
            steps: 6200,
            isToday: false,
            isFuture: false
        ),
        .init(
            label: "Tue",
            dayNumber: "2",
            steps: 9800,
            isToday: false,
            isFuture: false
        ),
        .init(
            label: "Wed",
            dayNumber: "3",
            steps: 4100,
            isToday: false,
            isFuture: false
        ),
        .init(
            label: "Thu",
            dayNumber: "4",
            steps: 11200,
            isToday: false,
            isFuture: false
        ),
        .init(
            label: "Fri",
            dayNumber: "5",
            steps: 0,
            isToday: false,
            isFuture: false
        ),
        .init(
            label: "Sat",
            dayNumber: "6",
            steps: 3300,
            isToday: false,
            isFuture: false
        ),
        .init(
            label: "Sun",
            dayNumber: "7",
            steps: 8000,
            isToday: true,
            isFuture: false
        ),
    ]
    ShareableChartCard(
        days: mockDays,
        goal: 10000,
        currentStreak: 5,
        period: .month
    )
    .padding()
}
