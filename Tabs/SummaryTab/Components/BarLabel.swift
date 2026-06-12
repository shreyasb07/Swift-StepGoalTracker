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
                day: .mock(label: "Mon", day: 1, steps: 11200),
                isMaxDay: false,
                useDayNumber: true,
            )

            // Max day label
            BarLabel(
                day: .mock(label: "Tue", day: 2, steps: 13488),
                isMaxDay: true,
                useDayNumber: true
            )

            // Regular day — should show nothing
            BarLabel(
                day: .mock(label: "Wed", day: 3, steps: 6200),
                isMaxDay: false,
                useDayNumber: true
            )

            // Future day — should show nothing
            BarLabel(
                day: .mock(label: "Thu", day: 4, steps: 0),
                isMaxDay: false,
                useDayNumber: true

            )
        }
        .padding()
}
