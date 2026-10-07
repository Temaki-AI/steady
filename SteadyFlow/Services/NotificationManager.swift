import Foundation
import UserNotifications

/// Manages local notifications for habit reminders.
///
/// Every change to pending notifications runs through one serial chain of tasks,
/// so a removal can never land after (and wipe out) the reschedule that followed it.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    /// How many days ahead reminders are scheduled. The window is refreshed
    /// every time the app becomes active (see `HabitService.refreshAllReminders`).
    private static let daysAhead = 7

    private let center = UNUserNotificationCenter.current()
    private var lastOperation: Task<Void, Never>?

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func checkPermission() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    /// Replace all reminders for a habit with the next `daysAhead` days of reminders
    func scheduleReminders(for habit: Habit) {
        let requests = Self.requests(for: habit)
        let prefix = habit.id.uuidString
        enqueue { center in
            await Self.removePending(in: center) { $0.hasPrefix(prefix) }
            for request in requests {
                try? await center.add(request)
            }
        }
    }

    /// Replace every pending reminder with a fresh window for the given habits.
    /// Also clears reminders left behind by deleted or archived habits.
    func rescheduleAll(_ habits: [Habit]) {
        let requests = habits.flatMap { Self.requests(for: $0) }
        enqueue { center in
            center.removeAllPendingNotificationRequests()
            for request in requests {
                try? await center.add(request)
            }
        }
    }

    /// Cancel today's pending reminders for a habit (called on check-off)
    func cancelTodayReminder(for habit: Habit) {
        let todayPrefix = "\(habit.id.uuidString)-\(Habit.dateString(from: Date()))"
        enqueue { center in
            await Self.removePending(in: center) { $0.hasPrefix(todayPrefix) }
        }
    }

    /// Cancel all reminders for a habit
    func cancelReminders(for habit: Habit) {
        let prefix = habit.id.uuidString
        enqueue { center in
            await Self.removePending(in: center) { $0.hasPrefix(prefix) }
        }
    }

    /// Cancel every reminder the app has scheduled
    func cancelAll() {
        enqueue { center in
            center.removeAllPendingNotificationRequests()
        }
    }

    // MARK: - Helpers

    /// Runs `operation` after every previously enqueued operation has finished
    private func enqueue(_ operation: @escaping @MainActor (UNUserNotificationCenter) async -> Void) {
        let previous = lastOperation
        let center = self.center
        lastOperation = Task {
            await previous?.value
            await operation(center)
        }
    }

    private static func removePending(
        in center: UNUserNotificationCenter,
        where matches: (String) -> Bool
    ) async {
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter(matches)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Builds the reminder requests for a habit. Reads the model synchronously,
    /// so it must run before any suspension point.
    private static func requests(for habit: Habit) -> [UNNotificationRequest] {
        guard !habit.reminders.isEmpty, !habit.isArchived else { return [] }

        let calendar = Calendar.current
        var requests: [UNNotificationRequest] = []

        for dayOffset in 0..<daysAhead {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }

            // Skip days it isn't due (incl. the rest of a week whose target is already met)
            guard habit.isDue(on: date) else { continue }

            // Skip today if already completed
            if dayOffset == 0 && habit.isCompleted(for: date) { continue }

            for reminder in habit.reminders {
                let identifier = "\(habit.id.uuidString)-\(Habit.dateString(from: date))-\(reminder.hour)-\(reminder.minute)"

                let content = UNMutableNotificationContent()
                content.title = "Time for: \(habit.name)"
                content.sound = .default

                var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                dateComponents.hour = reminder.hour
                dateComponents.minute = reminder.minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            }
        }

        return requests
    }
}
