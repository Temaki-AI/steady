import Foundation
import SwiftData

@Model
final class DailyNote {
    var id: UUID
    var date: String                    // "2026-02-15"
    var text: String                    // max 500 chars
    var updatedAt: Date

    init(date: Date, text: String = "") {
        self.id = UUID()
        self.date = Habit.dateString(from: date)
        self.text = String(text.prefix(500))
        self.updatedAt = Date()
    }
}
