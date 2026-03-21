//
//  StepProgressRing.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/13/26.
//

import SwiftUI

struct StepProgressRing: View {
    let steps: Double
    let goal: Double
    
    private var progress: Double {
        min(steps/goal, 1.0)
    }
    
    var body: some View {
        ZStack {
            //Track
            Circle()
                .stroke(Color.green.opacity(0.15), lineWidth: 20)
            
            //Progress
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            //Center Content
            VStack(spacing: 4) {
                Text("\(Int(steps))")
                    .font(.system(.title, design: .rounded).monospacedDigit())
                    .bold()
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: steps)
                Text("steps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Divider()
                    .frame(width: 80)
                Text("Goal: \(Int(goal))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 220, height: 220)
    }
}

#Preview {
    StepProgressRing(steps: 3000, goal: 10000)
}
