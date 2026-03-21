//
//  ShareSheet.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/15/26.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )
        }

        func updateUIViewController(
            _ uiViewController: UIActivityViewController,
            context: Context
        ) {}
}
