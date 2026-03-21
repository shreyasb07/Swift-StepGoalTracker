//
//  BestDayRow.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/20/26.
//

import SwiftUI

struct BestDayRow: View {
    let stepText: String
    let dayLabel: String
    let isMonthView: Bool

    var body: some View {
        HStack {
            Label("Best Day", systemImage: "star.fill")
                .foregroundStyle(.yellow)
            Spacer()
            if stepText == "–" {
                Text("–").bold()
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(stepText)
                        .bold()
                    Text(isMonthView ? "Day \(dayLabel)" : dayLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    List {
        BestDayRow(stepText: "13,488 steps", dayLabel: "Wed", isMonthView: false)
        BestDayRow(stepText: "11,200 steps", dayLabel: "15", isMonthView: true)
        BestDayRow(stepText: "–", dayLabel: "", isMonthView: false)
    }
}
