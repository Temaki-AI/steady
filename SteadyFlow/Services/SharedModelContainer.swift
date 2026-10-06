import Foundation
import SwiftData

/// Shared ModelContainer that uses App Group storage so both the main app
/// and widget extension can access the same SwiftData database.
enum SharedModelContainer {
    static let appGroupID = "group.com.steadyflow.habits"

    /// URL for the shared SwiftData store inside the App Group container
    static var storeURL: URL {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )!
        return container.appending(path: "SteadyFlow.store")
    }

    /// Schema shared by app and widget
    static let schema = Schema([
        Habit.self,
        Completion.self,
        DailyNote.self
    ])

    /// Creates a ModelContainer for the main app (with CloudKit sync)
    static func makeAppContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Creates a ModelContainer for the widget (local only, no CloudKit)
    static func makeWidgetContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
