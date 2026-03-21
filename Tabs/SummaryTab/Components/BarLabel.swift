//
//  BarLabel.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/20/26.
//

import SwiftUI

struct BarLabel: View {
    let day: HealthManager.DayStep
    let isMaxDay: Bool
    let useDayNumber: Bool

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

#Preview {
    VStack(spacing: 20) {
            // Today's label
            BarLabel(
                day: HealthManager.DayStep(
                    label: "Mon",
                    dayNumber: "1",
                    steps: 9521,
                    isToday: true,
                    isFuture: false,
                ),
                isMaxDay: false,
                useDayNumber: true,
            )

            // Max day label
            BarLabel(
                day: HealthManager.DayStep(
                    label: "Tue",
                    dayNumber: "2",
                    steps: 13488,
                    isToday: false,
                    isFuture: false
                ),
                isMaxDay: true,
                useDayNumber: true
            )

            // Regular day — should show nothing
            BarLabel(
                day: HealthManager.DayStep(
                    label: "Wed",
                    dayNumber: "3",
                    steps: 6200,
                    isToday: false,
                    isFuture: false
                ),
                isMaxDay: false,
                useDayNumber: true
            )

            // Future day — should show nothing
            BarLabel(
                day: HealthManager.DayStep(
                    label: "Thu",
                    dayNumber: "4",
                    steps: 0,
                    isToday: false,
                    isFuture: true
                ),
                isMaxDay: false,
                useDayNumber: true

            )
        }
        .padding()
}
