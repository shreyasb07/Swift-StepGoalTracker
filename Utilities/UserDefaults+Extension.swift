//
//  UserDefaults+Extension.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/26/26.
//

import Foundation

extension UserDefaults {
    static let shared: UserDefaults = {
        if let groupDefaults = UserDefaults(suiteName: AppGroupConstants.suiteName){
            return groupDefaults
        }
        print("⚠️ Warning: App Group suite '\(AppGroupConstants.suiteName)' could not be loaded. Falling back to standard container.")
        return UserDefaults.standard
    }()
}
