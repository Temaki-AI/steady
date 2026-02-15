import Foundation

/// Flexible scheduling for habits
enum HabitSchedule: Codable, Hashable {
    case daily
    case specificDays(Set<Weekday>)     // e.g., {.mon, .wed, .fri}
    case timesPerWeek(Int)              // e.g., 3 times per week, any days
    case timesPerMonth(Int)             // e.g., 10 times per month
    case interval(days: Int)            // e.g., every 3 days

    /// Human-readable description
    var displayText: String {
        switch self {
        case .daily:
            return "Every day"
        case .specificDays(let days):
            let sorted = days.sorted { $0.rawValue < $1.rawValue }
            return sorted.map(\.shortName).joined(separator: ", ")
        case .timesPerWeek(let count):
            return "\(count)× per week"
        case .timesPerMonth(let count):
            return "\(count)× per month"
        case .interval(let days):
            return days == 1 ? "Every day" : "Every \(days) days"
        }
    }

    /// Check if a habit is scheduled for a given date
    func isScheduled(for date: Date, createdAt: Date, completions: [Date]) -> Bool {
        let calendar = Calendar.current

        switch self {
        case .daily:
            return true

        case .specificDays(let days):
            let weekday = calendar.component(.weekday, from: date)
            return days.contains(Weekday(from: weekday))

        case .timesPerWeek:
            // Always show — it's up to the user which days
            return true

        case .timesPerMonth:
            // Always show
            return true

        case .interval(let interval):
            let daysSinceCreation = calendar.dateComponents([.day], from: calendar.startOfDay(for: createdAt), to: calendar.startOfDay(for: date)).day ?? 0
            return daysSinceCreation >= 0 && daysSinceCreation % interval == 0
        }
    }
}

/// Days of the week
enum Weekday: Int, Codable, Hashable, CaseIterable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    init(from calendarWeekday: Int) {
        self = Weekday(rawValue: calendarWeekday) ?? .sunday
    }
}

/// Time-of-day grouping
enum TimeOfDay: String, Codable, CaseIterable, Comparable {
    case morning, afternoon, evening, anytime

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .morning: return "sun.rise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.fill"
        case .anytime: return "clock.fill"
        }
    }

    var sortOrder: Int {
        switch self {
        case .morning: return 0
        case .afternoon: return 1
        case .evening: return 2
        case .anytime: return 3
        }
    }

    static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

/// Reminder time (hour + minute)
struct ReminderTime: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var hour: Int       // 0-23
    var minute: Int     // 0-59

    var displayText: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h, minute, ampm)
    }
}
