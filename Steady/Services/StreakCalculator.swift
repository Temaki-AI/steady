import Foundation

/// Calculates current and best streaks for habits
struct StreakCalculator {

    struct StreakResult {
        let current: Int
        let best: Int
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
        let calendar = Calendar.current
        let completionDates = Set(habit.completions.map(\.date)) // "yyyy-MM-dd" strings
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
}
