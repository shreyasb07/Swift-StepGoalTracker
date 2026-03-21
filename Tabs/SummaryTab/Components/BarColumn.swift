//
//  BarColumn.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/20/26.
//

import SwiftUI


struct BarColumn: View {
    let day: HealthManager.DayStep
    let isMaxDay: Bool
    let barColor: Color
    let heightRatio: CGFloat
    var useDayNumber: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            BarLabel(day: day, isMaxDay: isMaxDay, useDayNumber: useDayNumber)
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
            
            Text(useDayNumber ? day.dayNumber: day.label)
                .font(.system(size: 11, weight: day.isToday ? .bold : .regular ))
                .foregroundStyle(day.isToday ? .primary : .secondary)
        }
    }
}

#Preview {
        HStack(alignment: .bottom, spacing: 6) {
            // Goal hit
            BarColumn(
                day: HealthManager.DayStep(
                    label: "Mon",
                    dayNumber: "1",
                    steps: 11200,
                    isToday: false,
                    isFuture: false
                ),
                isMaxDay: false,
                barColor: .green,
                heightRatio: 0.85

            )

            // Today, in progress
            BarColumn(
                day: HealthManager.DayStep(
                    label: "Tue",
                    dayNumber: "2",
                    steps: 7500,
                    isToday: true,
                    isFuture: false
                ),
                isMaxDay: false,
                barColor: .blue.opacity(0.6),
                heightRatio: 0.55
            )

            // Past day, goal missed
            BarColumn(
                day: HealthManager.DayStep(
                    label: "Wed",
                    dayNumber: "3",
                    steps: 4100,
                    isToday: false,
                    isFuture: false
                ),
                isMaxDay: false,
                barColor: .red.opacity(0.3),
                heightRatio: 0.3
            )

            // Zero steps
            BarColumn(
                day: HealthManager.DayStep(
                    label: "Thu",
                    dayNumber: "4",
                    steps: 0,
                    isToday: false,
                    isFuture: false
                ),
                isMaxDay: false,
                barColor: .red.opacity(0.3),
                heightRatio: 0
            )

            // Future day
            BarColumn(
                day: HealthManager.DayStep(
                    label: "Fri",
                    dayNumber: "5",
                    steps: 0,
                    isToday: false,
                    isFuture: true
                ),
                isMaxDay: false,
                barColor: .clear,
                heightRatio: 0
            )
        }
        .frame(height: 200)
        .padding()
}
