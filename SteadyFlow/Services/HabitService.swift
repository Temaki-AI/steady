import Foundation
import SwiftData
import WidgetKit

/// Core business logic for habit operations
@Observable
final class HabitService {
    private let modelContext: ModelContext
    private let streakCalculator = StreakCalculator()
    private let notificationManager = NotificationManager()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    func createHabit(
        name: String,
        icon: String = "circle.fill",
        color: HabitColor = .green,
        schedule: HabitSchedule = .daily,
        timeOfDay: TimeOfDay = .anytime,
        reminders: [ReminderTime] = []
    ) -> Habit {
        // Get next position for this time-of-day group
        let position = nextPosition(for: timeOfDay)

        let habit = Habit(
            name: name,
            icon: icon,
            color: color,
            schedule: schedule,
            timeOfDay: timeOfDay,
            position: position,
            reminders: reminders
        )

        modelContext.insert(habit)
        try? modelContext.save()

        // Schedule notifications
        notificationManager.scheduleReminders(for: habit)
        WidgetCenter.shared.reloadAllTimelines()

        return habit
    }

    func updateHabit(_ habit: Habit) {
        habit.updatedAt = Date()
        try? modelContext.save()
        notificationManager.scheduleReminders(for: habit)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        habit.updatedAt = Date()
        try? modelContext.save()
        notificationManager.cancelReminders(for: habit)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func unarchiveHabit(_ habit: Habit) {
        habit.isArchived = false
        habit.position = nextPosition(for: habit.timeOfDay)
        habit.updatedAt = Date()
        try? modelContext.save()
        notificationManager.scheduleReminders(for: habit)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func deleteHabit(_ habit: Habit) {
        notificationManager.cancelReminders(for: habit)
        modelContext.delete(habit)
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Check-Off (Performance Critical — must be < 16ms)

    /// Toggle completion for a habit on a given date.
    /// Returns true if now completed, false if uncompleted.
    @discardableResult
    func toggleCompletion(for habit: Habit, on date: Date = Date()) -> Bool {
        let dateString = Habit.dateString(from: date)

        if let existing = habit.safeCompletions.first(where: { $0.date == dateString }) {
            // Uncomplete
            modelContext.delete(existing)
            try? modelContext.save()
            notificationManager.scheduleReminders(for: habit)
            WidgetCenter.shared.reloadAllTimelines()
            return false
        } else {
            // Complete
            let completion = Completion(habit: habit, date: date)
            modelContext.insert(completion)
            try? modelContext.save()
            notificationManager.cancelTodayReminder(for: habit)
            WidgetCenter.shared.reloadAllTimelines()
            return true
        }
    }

    // MARK: - Queries

    func activeHabits(for timeOfDay: TimeOfDay? = nil) -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.position)]
        )

        let habits = (try? modelContext.fetch(descriptor)) ?? []

        if let timeOfDay {
            return habits.filter { $0.timeOfDay == timeOfDay }
        }
        return habits
    }

    func archivedHabits() -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.isArchived },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Reordering

    func moveHabit(_ habit: Habit, to newPosition: Int) {
        let group = activeHabits(for: habit.timeOfDay)
        var sorted = group.sorted { $0.position < $1.position }

        guard let currentIndex = sorted.firstIndex(where: { $0.id == habit.id }) else { return }
        let item = sorted.remove(at: currentIndex)
        let clampedPosition = min(max(newPosition, 0), sorted.count)
        sorted.insert(item, at: clampedPosition)

        for (index, h) in sorted.enumerated() {
            h.position = index
        }

        try? modelContext.save()
    }

    // MARK: - Daily Notes

    func dailyNote(for date: Date) -> DailyNote? {
        let dateString = Habit.dateString(from: date)
        let descriptor = FetchDescriptor<DailyNote>(
            predicate: #Predicate { $0.date == dateString }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func saveDailyNote(text: String, for date: Date) {
        let dateString = Habit.dateString(from: date)

        if let existing = dailyNote(for: date) {
            existing.text = String(text.prefix(500))
            existing.updatedAt = Date()
        } else if !text.isEmpty {
            let note = DailyNote(date: date, text: text)
            modelContext.insert(note)
        }

        try? modelContext.save()
    }

    // MARK: - Helpers

    private func nextPosition(for timeOfDay: TimeOfDay) -> Int {
        let group = activeHabits(for: timeOfDay)
        return (group.map(\.position).max() ?? -1) + 1
    }
}
