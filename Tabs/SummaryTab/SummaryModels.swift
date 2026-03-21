//
//  SummaryModels.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/20/26.
//

import Foundation

enum SummaryPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"

}

enum ChartDisplayMode: String, CaseIterable {
    case bars = "Bars"
    case calendar = "Calendar"
}
