import Foundation

/// Pre-computes heatmap data for the contribution graph
struct HeatmapDataProvider {

    struct DayData: Identifiable {
        let id: String          // "yyyy-MM-dd"
        let date: Date
        let completedCount: Int
        let totalScheduled: Int
        let intensity: Int      // 0-3 (0 = none, 1 = low, 2 = mid, 3 = high)
    }

    /// Generate heatmap data for the past N days
    /// Should be called on a background thread for large date ranges
    func generateHeatmap(
        habits: [Habit],
        days: Int = 365,
        endDate: Date = Date()
    ) -> [DayData] {
        let calendar = Calendar.current
        var result: [DayData] = []

        let activeHabits = habits.filter { !$0.isArchived }

        for dayOffset in stride(from: -(days - 1), through: 0, by: 1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: endDate) else { continue }
            let dateString = Habit.dateString(from: date)

            var completed = 0
            var scheduled = 0

            for habit in activeHabits {
                guard habit.existedOn(date: date) else { continue }

                if habit.isScheduled(for: date) {
                    scheduled += 1
                    if habit.safeCompletions.contains(where: { $0.date == dateString }) {
                        completed += 1
                    }
                }
            }

            let intensity: Int
            if scheduled == 0 {
                intensity = 0
            } else {
                let ratio = Double(completed) / Double(scheduled)
                if ratio == 0 {
                    intensity = 0
                } else if ratio < 0.34 {
                    intensity = 1
                } else if ratio < 0.67 {
                    intensity = 2
                } else {
                    intensity = 3
                }
            }

            result.append(DayData(
                id: dateString,
                date: date,
                completedCount: completed,
                totalScheduled: scheduled,
                intensity: intensity
            ))
        }

        return result
    }

    /// Generate heatmap for a single habit
    func generateHabitHeatmap(
        habit: Habit,
        days: Int = 365,
        endDate: Date = Date()
    ) -> [DayData] {
        let calendar = Calendar.current
        var result: [DayData] = []

        for dayOffset in stride(from: -(days - 1), through: 0, by: 1) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: endDate) else { continue }
            let dateString = Habit.dateString(from: date)

            guard habit.existedOn(date: date) else {
                result.append(DayData(id: dateString, date: date, completedCount: 0, totalScheduled: 0, intensity: 0))
                continue
            }

            let isScheduled = habit.isScheduled(for: date)
            let isCompleted = habit.safeCompletions.contains(where: { $0.date == dateString })

            let intensity: Int
            if !isScheduled {
                intensity = isCompleted ? 3 : 0  // Bonus completion on off day
            } else {
                intensity = isCompleted ? 3 : 0
            }

            result.append(DayData(
                id: dateString,
                date: date,
                completedCount: isCompleted ? 1 : 0,
                totalScheduled: isScheduled ? 1 : 0,
                intensity: intensity
            ))
        }

        return result
    }
}
