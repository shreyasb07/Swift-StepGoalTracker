//
//  MilestoneProgressRow.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/13/26.
//

import SwiftUI

struct MilestoneProgressRow: View {
    let steps: Double
    let goal: Double
    
    private let milestones = [25, 50, 75, 100]
    
    private func isHit(_ milestone: Int) -> Bool {
            let percentage = Int((steps / goal) * 100)
            return percentage >= milestone
        }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(milestones, id: \.self) {milestone in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(isHit(milestone) ? milestoneColor(milestone): Color.orange.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: isHit(milestone) ? "checkmark": "circle.dotted")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isHit(milestone) ? .white : .secondary)
                    }
                    .animation(.spring(duration: 0.4), value:isHit(milestone))
                    Text("\(milestone)%")
                                            .font(.caption2)
                                            .foregroundStyle(isHit(milestone) ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
                
                //Connector line between milestones
                if milestone != milestones.last {
                    Rectangle()
                        .fill(isHit(milestone) ? milestoneColor(milestone) : Color.orange.opacity(0.2))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .offset(y: -10) // align with center of circle
                        .animation(.spring(duration: 0.4), value: isHit(milestone))
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

private func milestoneColor(_ milestone: Int) -> Color {
    return .green
    }

#Preview {
    MilestoneProgressRow(steps: 3000, goal: 10000).padding()
}
