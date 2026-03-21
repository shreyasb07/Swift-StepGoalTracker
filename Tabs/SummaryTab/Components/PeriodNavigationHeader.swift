//
//  PeriodNavigationHeader.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/20/26.
//

import SwiftUI

struct PeriodNavigationHeader: View {
    let title: String
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.subheadline.bold())
                .animation(.easeInOut, value: title)

            Spacer()

            Button(action: onForward) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canGoForward ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        Section {
            PeriodNavigationHeader(
                title: "This Week",
                canGoForward: false,
                onBack: {},
                onForward: {}
            )
        }
        Section {
            PeriodNavigationHeader(
                title: "Last Month",
                canGoForward: true,
                onBack: {},
                onForward: {}
            )
        }
    }
}
