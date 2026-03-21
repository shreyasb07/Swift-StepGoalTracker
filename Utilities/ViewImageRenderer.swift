//
//  ViewImageRenderer.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 3/18/26.
//

import SwiftUI

@MainActor
class ViewImageRenderer {
    static let shared = ViewImageRenderer()
    private init() {}

    func render<Content: View>(
        view: Content,
        size: CGSize = CGSize(width: 390, height: 520)
    ) async -> UIImage? {
        let renderer = ImageRenderer(
            content:
                view
                .frame(width: size.width)
        )

        //Retina scale for sharp images
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = ProposedViewSize(width: size.width, height: nil) // ← nil height = size to fit

        guard let image = renderer.uiImage else {
            Logger.error("Failed to render view to image")
            return nil
        }
        Logger.success(
            "View rendered to image -- size: \(Int(size.width)) X \(Int(size.height))"
        )
        return image
    }

}
