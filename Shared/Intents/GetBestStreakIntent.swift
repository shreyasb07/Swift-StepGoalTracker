//
//  GetBestStreakIntent.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 6/12/26.
//

import Foundation
import AppIntents
import SwiftUI

struct GetBestStreakIntent : AppIntent {
    static var title : LocalizedStringResource = "Get Best Step Streak"
    static var description = IntentDescription("Returns your all-time highest consecutive day step streak.")
    
    // This makes it discoverable by Siri and Shortcuts app
    static var isDiscoverable: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog & ShowsSnippetView{
        //Fetch streak from existing App Group
        let bestStreak = UserDefaults.shared.integer(forKey: AppGroupConstants.bestStreakKey)
        
        let dialogText : IntentDialog = "You best step streak is \(bestStreak) days!"
        
        return .result(value: bestStreak, dialog: dialogText, view: BestStreakSnippetView(streak: bestStreak))
    }
}

struct BestStreakSnippetView: View {
    let streak: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("BEST STREAK")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange) // Matches Ryze / Stepido branding
                Text("\(streak) Days")
                    .font(.title)
                    .fontWeight(.black)
            }
            Spacer()
            Image(systemName: "trophy.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
        }
        .padding()
    }
}
