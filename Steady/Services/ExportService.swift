import Foundation
import SwiftData

/// Handles JSON and CSV export/import
struct ExportService {

    // MARK: - Export

    struct ExportData: Codable {
        let version: String
        let exportedAt: String
        let habits: [ExportHabit]
        let notes: [ExportNote]
    }

    struct ExportHabit: Codable {
        let id: String
        let name: String
        let icon: String
        let color: String
        let schedule: HabitSchedule
        let timeOfDay: String
        let position: Int
        let isArchived: Bool
        let createdAt: String
        let completions: [ExportCompletion]
    }

    struct ExportCompletion: Codable {
        let date: String
        let completedAt: String
        let timezone: String
    }

    struct ExportNote: Codable {
        let date: String
        let text: String
    }

    /// Export all data as JSON
    func exportJSON(habits: [Habit], notes: [DailyNote]) -> Data? {
        let formatter = ISO8601DateFormatter()

        let exportHabits = habits.map { habit in
            ExportHabit(
                id: habit.id.uuidString,
                name: habit.name,
                icon: habit.icon,
                color: habit.colorHex,
                schedule: habit.schedule,
                timeOfDay: habit.timeOfDayRaw,
                position: habit.position,
                isArchived: habit.isArchived,
                createdAt: formatter.string(from: habit.createdAt),
                completions: habit.completions.map { c in
                    ExportCompletion(
                        date: c.date,
                        completedAt: formatter.string(from: c.completedAt),
                        timezone: c.timezone
                    )
                }
            )
        }

        let exportNotes = notes.map { note in
            ExportNote(date: note.date, text: note.text)
        }

        let exportData = ExportData(
            version: "1.0",
            exportedAt: formatter.string(from: Date()),
            habits: exportHabits,
            notes: exportNotes
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(exportData)
    }

    /// Export all data as CSV
    func exportCSV(habits: [Habit], notes: [DailyNote]) -> Data? {
        var lines: [String] = ["date,habit_name,completed,note"]

        // Collect all dates
        var allDates = Set<String>()
        for habit in habits {
            for completion in habit.completions {
                allDates.insert(completion.date)
            }
        }
        for note in notes {
            allDates.insert(note.date)
        }

        let notesByDate = Dictionary(uniqueKeysWithValues: notes.map { ($0.date, $0.text) })

        for dateStr in allDates.sorted() {
            for habit in habits {
                let completed = habit.completions.contains { $0.date == dateStr }
                let note = notesByDate[dateStr] ?? ""
                let escapedName = habit.name.replacingOccurrences(of: ",", with: ";")
                let escapedNote = note.replacingOccurrences(of: ",", with: ";")
                    .replacingOccurrences(of: "\n", with: " ")
                lines.append("\(dateStr),\(escapedName),\(completed ? "yes" : "no"),\(escapedNote)")
            }
        }

        return lines.joined(separator: "\n").data(using: .utf8)
    }
}
