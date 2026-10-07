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

    /// Spoken name for VoiceOver
    var displayName: String {
        String(describing: self).capitalized
    }
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

    /// Distinct completed days ("yyyy-MM-dd"). CloudKit sync can produce two
    /// completions for the same day (checked off on two devices), so count days, not records.
    var completedDates: Set<String> {
        Set(safeCompletions.map(\.date))
    }

    /// Check if this habit is scheduled for a given date
    func isScheduled(for date: Date) -> Bool {
        schedule.isScheduled(for: date, createdAt: createdAt)
    }

    // MARK: - Weekly / Monthly Targets

    /// Calendar for "per week" periods. Honors the week-start setting, which
    /// lives in the App Group defaults so the widget agrees with the app.
    static var periodCalendar: Calendar {
        var calendar = Calendar.current
        let firstDay = UserDefaults.shared.integer(forKey: "firstDayOfWeek")
        if (1...7).contains(firstDay) {
            calendar.firstWeekday = firstDay
        }
        return calendar
    }

    /// The week or month containing `date`, for habits with a periodic target
    func targetPeriod(containing date: Date) -> DateInterval? {
        guard let target = schedule.periodTarget else { return nil }
        return Self.periodCalendar.dateInterval(of: target.period.calendarComponent, for: date)
    }

    /// Distinct days completed within `period`, optionally only days before `cutoff`
    func completedDays(in period: DateInterval, before cutoff: Date? = nil) -> Int {
        let start = Self.dateString(from: period.start)
        let end = Self.dateString(from: cutoff ?? period.end) // exclusive
        return completedDates.filter { $0 >= start && $0 < end }.count
    }

    /// Progress toward the target in the period containing `date`, e.g. 2 of 3 this week
    func periodProgress(for date: Date) -> (done: Int, target: Int, period: TargetPeriod)? {
        guard let target = schedule.periodTarget,
              let period = targetPeriod(containing: date) else { return nil }
        return (completedDays(in: period), target.count, target.period)
    }

    /// Whether the habit counts as due on `date`. Fixed-day habits follow their
    /// schedule. Target habits are due until the period's target is met, so rest
    /// days after hitting the target never count as misses.
    func isDue(on date: Date) -> Bool {
        guard let target = schedule.periodTarget,
              let period = targetPeriod(containing: date) else {
            return isScheduled(for: date)
        }
        if isCompleted(for: date) { return true }
        return completedDays(in: period, before: date) < target.count
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

    /// Storage keys must be identical on every device regardless of the user's
    /// calendar or region, so pin the Gregorian calendar and POSIX locale.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    static func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        dateFormatter.date(from: string)
    }
}
