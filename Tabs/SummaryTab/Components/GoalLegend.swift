//
//  GoalLegend.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/20/26.
//

import SwiftUI

struct GoalLegend: View {
    let goal: Double

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.orange.opacity(0.7))
                .frame(width: 16, height: 3)
            Text("Goal: \(Int(goal)) steps")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Standard goal
        GoalLegend(goal: 10000)

        // High goal
        GoalLegend(goal: 15000)

        // Low goal
        GoalLegend(goal: 5000)
    }
    .padding()
}
