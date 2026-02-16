import Foundation
import SwiftData

/// 12-color palette for habits
enum HabitColor: String, Codable, CaseIterable {
    case red = "#E57373"
    case orange = "#FFB74D"
    case amber = "#FFD54F"
    case green = "#81C784"
    case teal = "#4DB6AC"
    case blue = "#64B5F6"
    case indigo = "#7986CB"
    case purple = "#BA68C8"
    case pink = "#F06292"
    case brown = "#A1887F"
    case gray = "#90A4AE"
    case lime = "#AED581"
}

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "circle.fill"
    var colorHex: String = "#81C784"
    var scheduleData: Data = Data()
    var timeOfDayRaw: String = "anytime"
    var position: Int = 0
    var remindersData: Data = Data()
    var isArchived: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Completion.habit)
    var completions: [Completion]? = []

    init(
        name: String,
        icon: String = "circle.fill",
        color: HabitColor = .green,
        schedule: HabitSchedule = .daily,
        timeOfDay: TimeOfDay = .anytime,
        position: Int = 0,
        reminders: [ReminderTime] = []
    ) {
        self.id = UUID()
        self.name = String(name.prefix(50))
        self.icon = icon
        self.colorHex = color.rawValue
        self.scheduleData = (try? JSONEncoder().encode(schedule)) ?? Data()
        self.timeOfDayRaw = timeOfDay.rawValue
        self.position = position
        self.remindersData = (try? JSONEncoder().encode(reminders)) ?? Data()
        self.isArchived = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    var schedule: HabitSchedule {
        get { (try? JSONDecoder().decode(HabitSchedule.self, from: scheduleData)) ?? .daily }
        set {
            scheduleData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = Date()
        }
    }

    var timeOfDay: TimeOfDay {
        get { TimeOfDay(rawValue: timeOfDayRaw) ?? .anytime }
        set {
            timeOfDayRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    var color: HabitColor {
        get { HabitColor.allCases.first { $0.rawValue == colorHex } ?? .green }
        set {
            colorHex = newValue.rawValue
            updatedAt = Date()
        }
    }

    var reminders: [ReminderTime] {
        get { (try? JSONDecoder().decode([ReminderTime].self, from: remindersData)) ?? [] }
        set {
            remindersData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = Date()
        }
    }

    /// The completions array, safely unwrapped
    var safeCompletions: [Completion] {
        completions ?? []
    }

    /// Check if this habit is scheduled for a given date
    func isScheduled(for date: Date) -> Bool {
        let completionDates = safeCompletions.map { $0.calendarDate }
        return schedule.isScheduled(for: date, createdAt: createdAt, completions: completionDates)
    }

    /// Check if this habit is completed for a given date
    func isCompleted(for date: Date) -> Bool {
        let dateString = Self.dateString(from: date)
        return safeCompletions.contains { $0.date == dateString }
    }

    /// Get completion for a specific date
    func completion(for date: Date) -> Completion? {
        let dateString = Self.dateString(from: date)
        return safeCompletions.first { $0.date == dateString }
    }

    /// Whether the habit existed on a given date
    func existedOn(date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) >= Calendar.current.startOfDay(for: createdAt)
    }

    // MARK: - Date Helpers

    static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.date(from: string)
    }
}
