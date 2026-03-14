//
//  PhoneConnector.swift
//  StepGoalTracker
//
//  Created by Shreyas Bhosale on 2/27/26.
//

import Foundation
import WatchConnectivity
import SwiftUI

class PhoneConnector: NSObject, WCSessionDelegate, ObservableObject {
    @AppStorage("stepGoal") var stepGoal: Double = 10000
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func updateGoal(newGoal: Double) {
//        self.stepGoal = newGoal
        let dict = ["stepGoal": newGoal]
        try? WCSession.default.updateApplicationContext(dict)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let goal = applicationContext["stepGoal"] as? Double {
            DispatchQueue.main.async {
                self.stepGoal = goal
            }
        }
    }
    
    // Required delegate stubs for iOS
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
}
