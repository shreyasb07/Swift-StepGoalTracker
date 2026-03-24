//
//  Calendar+Extensions.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/23/26.
//

import Foundation

extension Calendar {
    // A Monday first calendar irrespective of device locale
    static var mondayFirst: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.locale = .current
        return calendar
    }
}
