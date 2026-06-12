//
//  AppGroupConstants.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/26/26.
//

import Foundation

enum AppGroupConstants {
    static let suiteName = "group.shreyas.StepGoalTracker"
    
    //Streak
    static let step_goal_key = "user_step_goal"
    static let currentStreakKey = "current_streak"
    static let previousStreakKey = "previous_streak_key"
    static let bestStreakKey = "best_streak_key"
    static let streakTaskIdentifier = "com.shreyas.StepGoalTracker.refreshStreakTask"
    
    //First Launch
    static let hasLaunchedKey = "hasLaunchedBefore"
    static let notificationsEnabledKey = "notificationsEnabled"
}
