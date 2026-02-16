import Foundation
import SwiftData

@Model
final class DailyNote {
    var id: UUID = UUID()
    var date: String = ""
    var text: String = ""
    var updatedAt: Date = Date()

    init(date: Date, text: String = "") {
        self.id = UUID()
        self.date = Habit.dateString(from: date)
        self.text = String(text.prefix(500))
        self.updatedAt = Date()
    }
}
