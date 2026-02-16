import Foundation
import SwiftData

@Model
final class Completion {
    var id: UUID
    var date: String                    // "2026-02-15" (local calendar date)
    var completedAt: Date               // full timestamp
    var timezone: String                // "America/New_York"
    var habit: Habit?

    init(habit: Habit, date: Date = Date()) {
        self.id = UUID()
        self.date = Habit.dateString(from: date)
        self.completedAt = Date()
        self.timezone = TimeZone.current.identifier
        self.habit = habit
    }

    /// The calendar date as a Date object
    var calendarDate: Date {
        Habit.date(from: date) ?? completedAt
    }
}
