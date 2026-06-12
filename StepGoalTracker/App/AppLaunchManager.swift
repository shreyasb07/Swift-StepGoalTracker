//
//  AppLaunchManager.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/28/26.
//

import Foundation

@MainActor
public final class AppLaunchManager : ObservableObject {
    
    enum AppLaunchState {
        case onboarding
        case goalSetup
        case main
    }
    
    @Published private(set) var launchState : AppLaunchState = .main
    
    init() {
        determineLaunchState()
    }
    
    //MARK: Public
    func completeGoalSetup(goal: Int, notificationsEnabled: Bool) {
        UserDefaults.shared.set(goal, forKey: AppGroupConstants.step_goal_key)
        UserDefaults.shared.set(notificationsEnabled, forKey: AppGroupConstants.notificationsEnabledKey)
        UserDefaults.shared.set(true, forKey: AppGroupConstants.hasLaunchedKey)
        launchState = .main
    }
    
    func determineLaunchState() {
        let hasLaunched = UserDefaults.shared.object(forKey: AppGroupConstants.hasLaunchedKey) as? Bool ?? false
        Logger.info("hasLaunched: \(hasLaunched) → launchState: \(hasLaunched ? "main" : "goalSetup")")
        launchState = hasLaunched ? .main : .goalSetup
    }
}
