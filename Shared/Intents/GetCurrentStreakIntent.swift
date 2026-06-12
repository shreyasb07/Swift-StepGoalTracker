//
//  GetStepStreakIntent.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 6/12/26.
//

import Foundation
import AppIntents
import SwiftUI

struct GetCurrentStreakIntent : AppIntent {
    static var title : LocalizedStringResource = "Get Step Streak"
    static var description = IntentDescription("Returns your current consecutive daily step goal streak.")
    
    // This makes it discoverable by Siri and Shortcuts app
    static var isDiscoverable: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog & ShowsSnippetView {
        //Fetch streak from existing App Group
        let currentStreak = UserDefaults.shared.integer(forKey: AppGroupConstants.currentStreakKey)
        
        let dialogText : IntentDialog = "You current step streak is \(currentStreak) days!"
        
        return .result(value: currentStreak, dialog: dialogText, view: CurrentStreakSnippetView(streak: currentStreak))
    }
}

// 4. Provide a lightweight card interface for the Siri canvas
struct CurrentStreakSnippetView: View {
    let streak: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT STREAK")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange) // Matches Ryze / Stepido branding
                Text("\(streak) Days")
                    .font(.title)
                    .fontWeight(.black)
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
        }
        .padding()
    }
}
