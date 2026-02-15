import Foundation
import UserNotifications

/// Manages local notifications for habit reminders
final class NotificationManager {
    private let center = UNUserNotificationCenter.current()

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

    /// Reschedule all reminders for a habit (next 7 days)
    func scheduleReminders(for habit: Habit) {
        // Cancel existing reminders for this habit
        cancelReminders(for: habit)

        guard !habit.reminders.isEmpty, !habit.isArchived else { return }

        let calendar = Calendar.current

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }

            // Skip if not scheduled for this day
            guard habit.isScheduled(for: date) else { continue }

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
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                center.add(request)
            }
        }
    }

    /// Cancel today's pending reminders for a habit (called on check-off)
    func cancelTodayReminder(for habit: Habit) {
        let todayPrefix = "\(habit.id.uuidString)-\(Habit.dateString(from: Date()))"

        center.getPendingNotificationRequests { requests in
            let toRemove = requests
                .filter { $0.identifier.hasPrefix(todayPrefix) }
                .map(\.identifier)
            self.center.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
    }

    /// Cancel all reminders for a habit
    func cancelReminders(for habit: Habit) {
        let prefix = habit.id.uuidString

        center.getPendingNotificationRequests { requests in
            let toRemove = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map(\.identifier)
            self.center.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
    }

    /// Reschedule all notifications (called on app launch and background refresh)
    func rescheduleAll(habits: [Habit]) {
        center.removeAllPendingNotificationRequests()
        for habit in habits where !habit.isArchived {
            scheduleReminders(for: habit)
        }
    }
}
