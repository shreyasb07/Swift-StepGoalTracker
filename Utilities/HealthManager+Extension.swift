//
//  HealthManager+Extension.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/26/26.
//

import Foundation

extension HealthManager.DayStep {
    static func mock(label: String, day: Int, steps: Double, isToday: Bool = false, isFuture: Bool = false) -> HealthManager.DayStep {
        let calendar = Calendar.mondayFirst
        // Create a date based on the day number to keep things logical
        let date = calendar.date(byAdding: .day, value: day - 7, to: Date()) ?? Date()
        
        return .init(
            date: date,
            label: label,
            dayNumber: "\(day)",
            steps: steps,
            isToday: isToday,
            isFuture: isFuture
        )
    }
}
