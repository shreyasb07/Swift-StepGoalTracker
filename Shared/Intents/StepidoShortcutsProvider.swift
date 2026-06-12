//
//  StepidoShortcutsProvider.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 6/12/26.
//

import Foundation
import AppIntents

struct StepidoShortcutsProvider : AppShortcutsProvider {
    static var appShortcuts : [AppShortcut] {
        AppShortcut(
            intent: GetCurrentStreakIntent(),
            phrases: [
                "What is my \(.applicationName) streak?",
                "Check my streak on \(.applicationName)",
                "Show my \(.applicationName) step streak"
            ],
            shortTitle: "Get Step Streak",
            systemImageName: "flame.fill"
        )
        
        AppShortcut(
                    intent: GetBestStreakIntent(),
                    phrases: [
                        "What is my best streak in \(.applicationName)?",
                        "Show my high score on \(.applicationName)",
                        "What's my record streak in \(.applicationName)?"
                    ],
                    shortTitle: "Best Streak",
                    systemImageName: "trophy"
                )
    }
}
