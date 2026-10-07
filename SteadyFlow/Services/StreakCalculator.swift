import Foundation

/// Calculates current and best streaks for habits
struct StreakCalculator {

    struct StreakResult {
        let current: Int
        let best: Int
        /// Days for fixed schedules; weeks or months for "times per" targets
        var unit: Unit = .day

        enum Unit { case day, week, month }

        var currentText: String { Self.format(current, unit) }
        var bestText: String { Self.format(best, unit) }

        /// "12", "3w", "2mo"
        static func format(_ count: Int, _ unit: Unit) -> String {
            switch unit {
            case .day: return "\(count)"
            case .week: return "\(count)w"
            case .month: return "\(count)mo"
            }
        }
    }

    /// Calculate streaks for a habit.
    ///
    /// Rules:
    /// - Current streak counts consecutive scheduled days completed, going backward from today/yesterday.
    /// - If today is scheduled and not yet done, streak counts from yesterday.
    /// - If today is scheduled and done, streak includes today.
    /// - Non-scheduled days don't break streaks (e.g., weekend for a weekday-only habit).
    /// - Best streak is the highest streak ever achieved.
    func calculate(for habit: Habit, asOf today: Date = Date()) -> StreakResult {
        if let target = habit.schedule.periodTarget {
            return periodStreak(for: habit, target: target, asOf: today)
        }

        let calendar = Calendar.current
        let completionDates = Set(habit.safeCompletions.map(\.date)) // "yyyy-MM-dd" strings
        let todayString = Habit.dateString(from: today)

        // Determine starting point
        let todayScheduled = habit.isScheduled(for: today)
        let todayCompleted = completionDates.contains(todayString)

        var currentStreak = 0
        var bestStreak = 0
        var runningStreak = 0

        // Walk backward from today up to 1 year
        let startDate: Date
        if todayScheduled && todayCompleted {
            startDate = today
        } else if todayScheduled && !todayCompleted {
            // Don't count today as broken — start from yesterday
            startDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        } else {
            // Today not scheduled, start from yesterday
            startDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }

        // Calculate current streak
        var date = startDate
        let createdStart = calendar.startOfDay(for: habit.createdAt)

        while date >= createdStart {
            let dateString = Habit.dateString(from: date)
            let isScheduled = habit.isScheduled(for: date)

            if !habit.existedOn(date: date) {
                break
            }

            if isScheduled {
                if completionDates.contains(dateString) {
                    currentStreak += 1
                } else {
                    break
                }
            }
            // Non-scheduled days: skip (don't break streak)

            date = calendar.date(byAdding: .day, value: -1, to: date) ?? createdStart
        }

        // Calculate best streak — walk forward from creation date
        date = createdStart
        let endDate = calendar.startOfDay(for: today)

        while date <= endDate {
            let dateString = Habit.dateString(from: date)
            let isScheduled = habit.isScheduled(for: date)

            if isScheduled {
                if completionDates.contains(dateString) {
                    runningStreak += 1
                    bestStreak = max(bestStreak, runningStreak)
                } else {
                    runningStreak = 0
                }
            }
            // Non-scheduled days: don't affect running streak

            date = calendar.date(byAdding: .day, value: 1, to: date) ?? endDate
            if date == calendar.date(byAdding: .day, value: 1, to: endDate) { break }
        }

        bestStreak = max(bestStreak, currentStreak)

        return StreakResult(current: currentStreak, best: bestStreak)
    }

    /// Streak for "N times per week/month" habits, counted in periods where the
    /// target was met. The current period counts once met but can't break the
    /// streak while still in progress, and neither can the (possibly partial)
    /// period the habit was created in.
    private func periodStreak(
        for habit: Habit,
        target: (period: TargetPeriod, count: Int),
        asOf today: Date
    ) -> StreakResult {
        let calendar = Habit.periodCalendar
        let component = target.period.calendarComponent
        let unit: StreakResult.Unit = target.period == .week ? .week : .month

        guard let first = calendar.dateInterval(of: component, for: habit.createdAt),
              let current = calendar.dateInterval(of: component, for: today) else {
            return StreakResult(current: 0, best: 0, unit: unit)
        }

        // Each period from creation to now, oldest first: was the target met?
        var met: [Bool] = []
        var periodStart = first.start
        while periodStart <= current.start,
              let period = calendar.dateInterval(of: component, for: periodStart) {
            met.append(habit.completedDays(in: period) >= target.count)
            periodStart = period.end
        }

        let lastIndex = met.count - 1
        func canBreak(_ index: Int) -> Bool { index != 0 && index != lastIndex }

        var best = 0
        var running = 0
        for (index, wasMet) in met.enumerated() {
            if wasMet {
                running += 1
                best = max(best, running)
            } else if canBreak(index) {
                running = 0
            }
        }

        var currentStreak = 0
        for index in stride(from: lastIndex, through: 0, by: -1) {
            if met[index] {
                currentStreak += 1
            } else if canBreak(index) {
                break
            }
        }

        return StreakResult(current: currentStreak, best: max(best, currentStreak), unit: unit)
    }
}
