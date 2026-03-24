import Foundation
import HealthKit
import SwiftUI

// 1. Keep the ID constant for safety
//let SHARED_GROUP_ID = "group.shreyas.StepGoalTracker"

@MainActor
class HealthManager: ObservableObject {

    struct DayStep: Identifiable, Equatable {
        let id = UUID()
        let label: String
        let dayNumber: String
        let steps: Double
        let isToday: Bool
        let isFuture: Bool
    }

    private var anchoredQuery: HKAnchoredObjectQuery?
    let healthStore = HKHealthStore()
    //Week
    @Published var weeklySteps: [DayStep] = []
    @Published var selectedWeekSteps: [DayStep] = []
    @Published var selectedWeekOffset: Int = 0
    //Month
    @Published var selectedMonthlySteps: [DayStep] = []
    @Published var selectedMonthOffset: Int = 0
    @Published var stepCount: Double = 3000

    @AppStorage("currentStreak") var currentStreak: Int = 0
    @AppStorage("bestStreak") var bestStreak: Int = 0
    @AppStorage("lastGoalMetDate") var lastGoalMetDateString: String = ""

    @AppStorage("previousStreak") var previousStreak: Int = 0

    //MARK: - HealthKit Helpers

    private func stepType() -> HKQuantityType {
        return HKQuantityType.quantityType(forIdentifier: .stepCount)!
    }

    private func predicate(from start: Date, to end: Date = Date())
        -> NSPredicate
    {
        HKQuery.predicateForSamples(withStart: start, end: end)
    }

    private func extractSteps(
        from result: HKStatisticsCollection?,
        for day: Date
    ) -> Double {
        result?.statistics(for: day)?.sumQuantity()?.doubleValue(for: .count())
            ?? 0
    }
    
    private static let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"  // "1", "2"... "31"
        return formatter
    }()

    //MARK: - Weekly steps core query
    //Single Shared Helper - both fetchWeeklySteps and fetchSelectedWeek can use this
    private func fetchSteps(
        from startDate: Date,
        days: [Date],
        isCurrentPeriod: Bool
    ) async -> [DayStep] {
        let calendar = Calendar.mondayFirst
        let today = calendar.startOfDay(for: Date())
        let endDate =
            isCurrentPeriod
        ? Date() : calendar.date(byAdding: .day, value: days.count, to: startDate) ?? startDate

        let query = HKStatisticsCollectionQuery(
            quantityType: stepType(),
            quantitySamplePredicate: predicate(from: startDate, to: endDate),
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return await withCheckedContinuation { continuation in
            query.initialResultsHandler = { [weak self] _, results, _ in
                guard let self, let results else {
                    continuation.resume(returning: [])
                    return
                }

                // Collect raw step values on background thread
                // using only value types — no @MainActor access
                var rawSteps: [(date: Date, steps: Double)] = []
                for day in days {
                    let isFuture = day > today
                    let steps =
                        isFuture
                        ? 0
                        : (results.statistics(for: day)?.sumQuantity()?
                            .doubleValue(for: .count()) ?? 0)
                    rawSteps.append((date: day, steps: steps))
                }
                Task { @MainActor in
                    var built: [DayStep] = []
                    for rawStep in rawSteps {
                        built.append(
                            DayStep(
                                label: formatter.string(from: rawStep.date),
                                dayNumber: Self.dayNumberFormatter.string(from: rawStep.date),
                                steps: rawStep.steps,
                                isToday: calendar.isDateInToday(rawStep.date),
                                isFuture: rawStep.date > today
                            )
                        )
                    }
                    continuation.resume(returning: built)
                }
            }
            healthStore.execute(query)

        }
    }

    func requestAuthorization(goal: Double) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        healthStore.requestAuthorization(toShare: [], read: [stepType]) {
            success,
            error in
            if success {
                Logger.success("Authorization successful")
                self.healthStore.enableBackgroundDelivery(
                    for: stepType,
                    frequency: .immediate
                ) { success, error in
                    if !success {
                        Logger.error("Failed to enable background delivery")
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
        let startOfDay = Calendar.current.startOfDay(for: Date())

        let query = HKAnchoredObjectQuery(
            type: stepType(),
            predicate: predicate(from: startOfDay, to: Date()),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, _, _, _, error in
            // Initial results handler
            if let error = error {
                Logger.error(
                    "Anchored query error: \(error.localizedDescription)"
                )
                return
            }
            Task { await self?.fetchTodaySteps(goal: goal) }
        }

        // This handler fires every time HealthKit has new step data
        query.updateHandler = { [weak self] _, _, _, _, error in
            if let error = error {
                Logger.error(
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
        let startOfDay = Calendar.current.startOfDay(for: Date())

        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType(),
                quantitySamplePredicate: predicate(from: startOfDay),
                options: .cumulativeSum
            ) { [weak self] _, result, _ in
                guard let self else {
                    continuation.resume()
                    return
                }
                let steps =
                    result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                Task { @MainActor in
                    self.stepCount = steps
                    self.updateStreak(steps: steps, goal: goal)
                    NotificationManager.shared.checkAndSendMilestone(
                        steps: steps,
                        goal: goal
                    )
                    continuation.resume()
                }
            }
            healthStore.execute(query)
        }

    }

    //MARK: - Fetch Steps for current week
    func fetchWeeklySteps(goal: Double) async {
        let calendar = Calendar.mondayFirst
        let today = calendar.startOfDay(for: Date())

        guard
            let startOfWeek = calendar.dateInterval(
                of: .weekOfYear,
                for: today
            )?.start
        else {
            Logger.error("Failed to calculate start of the week")
            return
        }
        // Build 7 day slots ending today
        let days: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }

        let built = await fetchSteps(
            from: startOfWeek,
            days: days,
            isCurrentPeriod: true
        )
        weeklySteps = built
        
        //Fetch last week's completed data for the report
        if calendar.isDateInToday(today) && calendar.component(.weekday, from: today) == 2 { // 2 = Monday
            //Its Monday, fetch last week report
            guard
                let lastWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: today),
                let lastWeekStart = calendar.dateInterval(of: .weekOfYear, for: lastWeekDate)?.start
            else { return }
            
            let lastWeekDays : [Date] = (0..<7).compactMap {
                calendar.date(byAdding: .day, value: $0, to: lastWeekStart)
            }
            let lastWeekBuilt = await fetchSteps(
                        from: lastWeekStart,
                        days: lastWeekDays,
                        isCurrentPeriod: false
                    )
            //Schedule weekly report
            let daysGoalHit = lastWeekBuilt.filter { !$0.isFuture && $0.steps >= goal }
                .count
            let activeDays = lastWeekBuilt.filter { !$0.isFuture && $0.steps > 0 }
            let average =
                activeDays.isEmpty
                ? 0
                : activeDays.map(\.steps).reduce(0, +) / Double(activeDays.count)

            NotificationManager.shared.scheduleWeeklyReport(
                daysGoalHit: daysGoalHit,
                averageSteps: average,
                currentStreak: currentStreak,
                previousStreak: previousStreak
            )
            previousStreak = currentStreak
            Logger.success("Fetched current week steps")
        }
        Logger.success("Fetched current week steps")
    }

    //MARK: - Fetch Selected Week
    func fetchSelectedWeek(offset: Int, goal: Double) async {
        let calendar = Calendar.mondayFirst
        let today = calendar.startOfDay(for: Date())

        // Calculate start of the target week
        guard
            let targetDate = calendar.date(
                byAdding: .weekOfYear,
                value: offset,
                to: today
            ),
            let startOfWeek = calendar.dateInterval(
                of: .weekOfYear,
                for: targetDate
            )?.start
        else {
            Logger.error("Failed to calculate week for offset \(offset)")
            return
        }

        let days: [Date] = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }

        let built = await fetchSteps(
            from: startOfWeek,
            days: days,
            isCurrentPeriod: offset == 0
        )
        selectedWeekSteps = built
        selectedWeekOffset = offset
        Logger.success("Fetched week data for offset \(offset)")
    }

    func fetchSelectedMonth(offset: Int, goal: Double) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard
            let targetDate = calendar.date(
                byAdding: .month,
                value: offset,
                to: today
            ),
            let startOfMonth = calendar.dateInterval(
                of: .month,
                for: targetDate
            )?.start,
            let daysInMonth = calendar.range(
                of: .day,
                in: .month,
                for: targetDate
            )?.count
        else {
            Logger.error("Failed to calculate month for offset. \(offset)")
            return
        }

        let days: [Date] = (0..<daysInMonth).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfMonth)
        }

        let built = await fetchSteps(
            from: startOfMonth,
            days: days,
            isCurrentPeriod: offset == 0
        )
        selectedMonthlySteps = built
        selectedMonthOffset = offset
        Logger.success("Fetched month data for offset: \(offset)")
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
                Task { await self?.fetchTodaySteps(goal: goal) }
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
