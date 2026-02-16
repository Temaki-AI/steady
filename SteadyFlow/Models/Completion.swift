import Foundation
import SwiftData

@Model
final class Completion {
    var id: UUID = UUID()
    var date: String = ""
    var completedAt: Date = Date()
    var timezone: String = ""
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
