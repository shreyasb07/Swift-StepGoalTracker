import Foundation
import HealthKit
import SwiftUI

// 1. Keep the ID constant for safety
//let SHARED_GROUP_ID = "group.shreyas.StepGoalTracker"

@MainActor
class HealthManager: ObservableObject {

    struct DayStep: Identifiable, Equatable {
        let id = UUID()
        let date: Date
        let label: String
        let dayNumber: String
        let steps: Double
        let isToday: Bool
        let isFuture: Bool
    }

    private var anchoredQuery: HKAnchoredObjectQuery?
    private var observerQuery: HKObserverQuery?
    let healthStore = HKHealthStore()
    
    //Week
    @Published var weeklySteps: [DayStep] = []
    @Published var selectedWeekSteps: [DayStep] = []
    @Published var selectedWeekOffset: Int = 0
    //Month
    @Published var selectedMonthlySteps: [DayStep] = []
    @Published var selectedMonthOffset: Int = 0
    @Published var stepCount: Double = 3000

    @AppStorage(AppGroupConstants.currentStreakKey, store: .shared) var currentStreak: Int = 0
    @AppStorage(AppGroupConstants.bestStreakKey, store: .shared) var bestStreak: Int = 0

    @AppStorage(AppGroupConstants.previousStreakKey, store: .shared) var previousStreak: Int = 0
    
    @Published var lastBackgroundRefresh: Date? {
        didSet {
            // Persist it so we can see it across app kills
            UserDefaults.shared.set(lastBackgroundRefresh, forKey: "last_bg_refresh")
        }
    }

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
    
    private func generateDateRange(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start
        let calendar = Calendar.mondayFirst
        
        while current <= end {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

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
            ? Date()
            : calendar.date(byAdding: .day, value: days.count, to: startDate)
                ?? startDate

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
            query.initialResultsHandler = { _, results, _ in
                guard let results else {
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
                                date: rawStep.date,
                                label: formatter.string(from: rawStep.date),
                                dayNumber: Self.dayNumberFormatter.string(
                                    from: rawStep.date
                                ),
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
        self.migrateOldStreakData()
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
        let calendar = Calendar.mondayFirst
        let startOfDay = calendar.startOfDay(for: Date())

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

//        #if os(watchOS)
            startObserverQuery(goal: goal)
//        #endif
    }

    func stopAnchoredQuery() {
        if let query = anchoredQuery {
            healthStore.stop(query)
            anchoredQuery = nil
        }
//        #if os(watchOS)
            stopObserverQuery()
//        #endif
    }

    func fetchTodaySteps(goal: Double) async {
        let calendar = Calendar.mondayFirst
        let startOfDay = calendar.startOfDay(for: Date())

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
                    // 1. Update the local "Today" entry in your array if it exists
                    // This ensures refreshStreak sees the latest number immediately
                    if let index = self.selectedMonthlySteps.firstIndex(where: {
                        calendar.isDateInToday($0.date)
                    }) {
                        let oldDay = self.selectedMonthlySteps[index]
                        self.selectedMonthlySteps[index] = DayStep(
                            date: oldDay.date,
                            label: oldDay.label,
                            dayNumber: oldDay.dayNumber,
                            steps: steps,
                            isToday: true,
                            isFuture: false
                        )
                    }
                    await self.refreshStreak(goal: goal)
                    
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
        let calendar = Calendar.mondayFirst
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
        if offset == 0 {
            await self.refreshStreak(goal: goal)
        }
        Logger.success("Fetched month data for offset: \(offset)")
    }

    func refreshStreak(goal: Double) async {
        Logger.info("Calling refresh Streak")
        let calendar = Calendar.mondayFirst
        let today = calendar.startOfDay(for: Date())
        
        // ─── GUARANTEED KEY MIGRATION INTERCEPTOR ─────────────────────────
        let defaults = UserDefaults.shared
        if let oldBest = defaults.value(forKey: "bestStreak") as? Int {
                Logger.info("Found legacy 'bestStreak' data: \(oldBest) days. Rescuing record...")
                
                // Push the true historical record directly to the MainActor state
                await MainActor.run {
                    // This updates both the runtime property and your new App Group key
                    self.bestStreak = max(oldBest, self.bestStreak)
                }
                
                // Wipe out the old key name so this migration block runs EXACTLY ONCE
                defaults.removeObject(forKey: "bestStreak")
                Logger.success("🎉 Safely restored your true historical Best Streak of \(oldBest) days!")
            }
            
            // Clean up legacy current streak key name if it lingers
            if let oldCurrent = defaults.value(forKey: "currentStreak") as? Int {
                defaults.removeObject(forKey: "currentStreak")
            }

        // Step 1 — Find the streak start using exponential backoff
        // Fetch increasingly large windows until we find a miss
        var windowSize = 30
        var streakStartDate: Date? = nil

        while true {
            guard let windowStart = calendar.date(
                byAdding: .day,
                value: -windowSize,
                to: today
            ) else { break }

            let days = generateDateRange(from: windowStart, to: today)
            let fetched = await fetchSteps(
                from: windowStart,
                days: days,
                isCurrentPeriod: true
            )

            // Find the earliest miss in this window
            let sortedDays = fetched
                .filter { !$0.isFuture }
                .sorted { $0.date < $1.date }

            // Find first day where goal was NOT met
            let missIndex = sortedDays.lastIndex { $0.steps < goal && !calendar.isDateInToday($0.date) }

            if let missIndex {
                // Found a miss inside this window
                // Streak starts the day after the miss
                streakStartDate = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: calendar.startOfDay(for: sortedDays[missIndex].date)
                )
                Logger.info("Found streak start: \(String(describing: streakStartDate)) after miss on \(sortedDays[missIndex].date)")
                break
            } else {
                // No miss found in this window — go back further
                if windowSize > 1825 { // 5 year safety cap
                    Logger.warning("No streak break found in 5 years — using window start")
                    streakStartDate = windowStart
                    break
                }
                windowSize *= 2  // Double the window: 30 → 60 → 120 → 240...
                Logger.info("No miss found in \(windowSize / 2) days — expanding to \(windowSize) days")
            }
        }

        guard let startDate = streakStartDate else {
            Logger.error("Could not determine streak start date")
            return
        }

        // Step 2 — Count days from streak start to today
        // We already have this data from the last fetch — just count
        let days = generateDateRange(from: startDate, to: today)
        let streakDays = await fetchSteps(
            from: startDate,
            days: days,
            isCurrentPeriod: true
        )

        let count = streakDays.filter {
            !$0.isFuture &&
            ($0.steps >= goal || calendar.isDateInToday($0.date))
        }.count

        Logger.info("Streak count: \(count) days from \(startDate) to \(today)")

        await MainActor.run {
            if self.currentStreak != count {
                self.previousStreak = self.currentStreak
            }
            self.currentStreak = count
            if count > self.bestStreak {
                self.bestStreak = count
            }
        }
    }

//    #if os(watchOS)

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
                Task {
                    await self?.fetchTodaySteps(goal: goal)
                    completionHandler()
                }
                
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
//    #endif  // os(watchOS)

    func migrateOldStreakData() {
        // 1. Access standard UserDefaults (where the old keys lived)
        let standardDefaults = UserDefaults.standard
        
        // 2. Access your App Group suite container
        let sharedDefaults = UserDefaults.shared // Using your fixed shared extension
        
        // 3. Migrate Best Streak if it exists under the old key
        if let oldBest = standardDefaults.value(forKey: "bestStreak") as? Int {
            let currentSharedBest = sharedDefaults.integer(forKey: AppGroupConstants.bestStreakKey)
            
            // Only migrate if the old record is higher than what's currently in the shared slot
            if oldBest > currentSharedBest {
                sharedDefaults.set(oldBest, forKey: AppGroupConstants.bestStreakKey)
                Logger.success("Migrated bestStreak (\(oldBest) days) to App Group container.")
            }
            
            // Clean up the old key so this only runs once
            standardDefaults.removeObject(forKey: "bestStreak")
        }
        
        // 4. Migrate Current Streak just in case
        if let oldCurrent = standardDefaults.value(forKey: "currentStreak") as? Int {
            if sharedDefaults.value(forKey: AppGroupConstants.currentStreakKey) == nil {
                sharedDefaults.set(oldCurrent, forKey: AppGroupConstants.currentStreakKey)
                Logger.success("Migrated currentStreak (\(oldCurrent) days) to App Group container.")
            }
            standardDefaults.removeObject(forKey: "currentStreak")
        }
    }
}

