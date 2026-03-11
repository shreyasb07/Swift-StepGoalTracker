import Foundation
import HealthKit
import SwiftUI

// 1. Keep the ID constant for safety
//let SHARED_GROUP_ID = "group.shreyas.StepGoalTracker"

@MainActor
class HealthManager: ObservableObject {

    @Published var weeklySteps: [DayStep] = []
    @AppStorage("previousStreak") var previousStreak: Int = 0

    struct DayStep: Identifiable {
        let id = UUID()
        let label: String
        let steps: Double
        let isToday: Bool
    }

    private var timer: Timer?
    private var anchoredQuery: HKAnchoredObjectQuery?
    let healthStore = HKHealthStore()
    @Published var stepCount: Double = 0
    @AppStorage("currentStreak") var currentStreak: Int = 0
    @AppStorage("bestStreak") var bestStreak: Int = 0
    @AppStorage("lastGoalMetDate") var lastGoalMetDateString: String = ""

    func requestAuthorization(goal: Double) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        healthStore.requestAuthorization(toShare: [], read: [stepType]) {
            success,
            error in
            if success {
                print("Authorization successful")
                self.healthStore.enableBackgroundDelivery(
                    for: stepType,
                    frequency: .immediate
                ) { success, error in
                    if !success {
                        print("Failed to enable background delivery")
                    }
                }
                
                Task { @MainActor in
                    self.startAnchoredQuery(goal: goal)
                    await self.fetchTodaySteps(goal: goal)
                    await self.fetchWeeklySteps(goal: goal)
                }
            }
        }
    }

    func startAnchoredQuery(goal: Double) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: nil,  // nil end = live, up to now
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: stepType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, _, _, _, error in
            // Initial results handler
            if let error = error {
                print("Anchored query error: \(error.localizedDescription)")
                return
            }
            Task { await self?.fetchTodaySteps(goal: goal) }
        }

        // This handler fires every time HealthKit has new step data
        query.updateHandler = { [weak self] _, _, _, _, error in
            if let error = error {
                print(
                    "Anchored query update error: \(error.localizedDescription)"
                )
                return
            }
            Task { await self?.fetchTodaySteps(goal: goal) }
        }

        self.anchoredQuery = query
        healthStore.execute(query)

        #if os(watchOS)
        startObserverQuery(goal: goal)
        #endif
    }

    func stopAnchoredQuery() {
        if let query = anchoredQuery {
            healthStore.stop(query)
            anchoredQuery = nil
        }
        #if os(watchOS)
            stopObserverQuery()
        #endif
    }

    func fetchTodaySteps(goal: Double) async {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, _ in
                guard let self else {
                    continuation.resume()
                    return
                }
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                DispatchQueue.main.async {
                    self.stepCount = steps
                    self.updateStreak(steps: steps, goal: goal)
                    NotificationManager.shared.checkAndSendMilestone(steps: steps, goal: goal)
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }

        
    }

    func fetchWeeklySteps(goal: Double) async{
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Build 7 day slots ending today
        let days: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }.reversed()

        let weekAgo = days.first!
        let predicate = HKQuery.predicateForSamples(
            withStart: weekAgo,
            end: Date(),
            options: .strictStartDate
        )

        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: today,
            intervalComponents: DateComponents(day: 1)
        )
        
        await withCheckedContinuation { continuation in
            query.initialResultsHandler = { _, results, error in
                guard let results else {
                    continuation.resume()
                    return
                }

                let formatter = DateFormatter()
                formatter.dateFormat = "EEE"  // "Mon", "Tue", etc.

                var built: [DayStep] = []
                for day in days {
                    let stat = results.statistics(for: day)
                    let steps = stat?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    built.append(
                        DayStep(
                            label: formatter.string(from: day),
                            steps: steps,
                            isToday: calendar.isDateInToday(day)
                        )
                    )
                }

                DispatchQueue.main.async {
                    self.weeklySteps = built
                    let daysGoalHit = built.filter { $0.steps >= goal }.count
                        let activeDays = built.filter { $0.steps > 0 }
                        let average = activeDays.isEmpty ? 0 : activeDays.map(\.steps).reduce(0, +) / Double(activeDays.count)
                        
                        NotificationManager.shared.scheduleWeeklyReport(
                            daysGoalHit: daysGoalHit,
                            averageSteps: average,
                            currentStreak: self.currentStreak,
                            previousStreak: self.previousStreak
                        )
                        
                        // Update previous streak for next week's comparison
                        self.previousStreak = self.currentStreak
                        continuation.resume()
                }
            }

            healthStore.execute(query)
        }
    }

    func updateStreak(steps: Double, goal: Double) {
        guard steps >= goal else { return }

        let formatter = ISO8601DateFormatter()
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: today
        )!
        let lastDate = formatter.date(from: lastGoalMetDateString)
            .map { Calendar.current.startOfDay(for: $0) }

        let newStreak: Int
        if lastDate == today {
            newStreak = currentStreak
            // Already counted today, do nothing
        } else if lastDate == yesterday {
            // Continuing streak from yesterday
            newStreak = currentStreak + 1
        } else {
            // No previous streak or gap in days
            newStreak = 1
        }

        currentStreak = newStreak
        bestStreak = max(bestStreak, newStreak)
        lastGoalMetDateString = formatter.string(from: today)
        
    }

    #if os(watchOS)
        private var observerQuery: HKObserverQuery?

        func startObserverQuery(goal: Double) {
            let stepType = HKQuantityType.quantityType(
                forIdentifier: .stepCount
            )!

            let query = HKObserverQuery(sampleType: stepType, predicate: nil) {
                [weak self] _, completionHandler, error in
                if let error = error {
                    print("Observer query error: \(error.localizedDescription)")
                    completionHandler()
                    return
                }
                Task {await self?.fetchTodaySteps(goal: goal) }
                completionHandler()
            }

            observerQuery = query
            healthStore.execute(query)
        }

        func stopObserverQuery() {
            if let query = observerQuery {
                healthStore.stop(query)
                observerQuery = nil
            }
        }
    #endif  // os(watchOS)

}
