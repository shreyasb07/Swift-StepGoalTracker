//
//  StatRow.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/20/26.
//

import SwiftUI

import SwiftUI

struct StatRow: View {
    let label: String
    let icon: String
    let color: Color
    let value: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(color)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

#Preview {
    List {
        StatRow(label: "Current Streak", icon: "flame.fill", color: .orange, value: "5 days")
        StatRow(label: "Best Streak", icon: "trophy.fill", color: .yellow, value: "12 days")
        StatRow(label: "Weekly Average", icon: "chart.bar.fill", color: .blue, value: "9,521 steps")
    }
}
