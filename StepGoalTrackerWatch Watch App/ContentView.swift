//
//  ContentView.swift
//  StepGoalTrackerWatch Watch App
//
//  Created by Shreyas Bhosale on 2/2/26.
//

import SwiftUI

struct ContentView : View {
    @StateObject var connector = PhoneConnector()
    @StateObject var health = HealthManager()
    @FocusState private var isCrownFocused: Bool
    
    var progress: Double {
        let ratio = health.stepCount / connector.stepGoal
            return min(max(ratio, 0.001), 1.0) // Keeps it between 0.1% and 100%
        }
    
    var actualPercentage: Int {
        let ratio = health.stepCount / connector.stepGoal
        return Int(ratio * 100)
    }
    
    var body: some View {
        VStack{
            ZStack{
                //The Track of the ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                //The progress fill
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                VStack {
                    HStack (spacing: 4){
                        Image(systemName: "figure.walk")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.green) // Matches your goal color
//                                .padding(.bottom, 2)
                        Text("Steps")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                    Text("\(Int(health.stepCount))")
                        .font(.system(.title3, design: .rounded))
                        .bold()
                    
                    // The "Divider" line
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(height: 1)
                            .frame(width: 40)
//                            .padding(.vertical, 1)
                    
                    // Goal
                    Text("\(Int(connector.stepGoal))")
                            .font(.system(.caption2, design: .rounded).monospacedDigit())
                            .foregroundStyle(.white) // Visual cue that this is the editable value
                    }
                    // Digital Crown modifiers move here
                    .focusable()
                    .focused($isCrownFocused)
                    .digitalCrownRotation($connector.stepGoal, from: 1000, through: 50000, by: 500, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                    .onChange(of: connector.stepGoal) { _, newGoal in
                        connector.updateGoal(newGoal: newGoal)
                    }

                }
            .padding()
            Text("Goal Achieved: \(actualPercentage) %")
                .font(.caption2)
                .foregroundStyle(actualPercentage >= 100 ? .green : .white)
        }
        .onAppear {
            isCrownFocused = true
            health.requestAuthorization(goal: connector.stepGoal)
        }
        .onDisappear {
            health.stopAnchoredQuery()
        }
        .onChange(of: health.stepCount){ oldCount, newCount in
            if newCount >= connector.stepGoal{
                WKInterfaceDevice.current().play(.success)
            }
        }
    }
}

#Preview {
    ContentView()
}
