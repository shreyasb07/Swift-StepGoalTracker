//
//  GoalLine.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/20/26.
//

import SwiftUI

struct GoalLine: View {
    let goalRatio: CGFloat
    let topOffset: CGFloat = 13
    let bottomOffset: CGFloat = 25

    var body: some View {
        GeometryReader { geo in
            let barAreaHeight = geo.size.height - topOffset - bottomOffset
            let yPosition = topOffset + barAreaHeight * (1 - goalRatio)
            Rectangle()
                .fill(Color.orange)
                .frame(height: 1.5)
                .offset(y: yPosition)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        // Goal at 70% height
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
            GoalLine(goalRatio: 0.7)
        }
        .frame(height: 150)

        // Goal at 50% height
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
            GoalLine(goalRatio: 0.5)
        }
        .frame(height: 150)

        // Goal at 90% height — near top
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
            GoalLine(goalRatio: 0.9)
        }
        .frame(height: 150)
    }
    .padding()
}
