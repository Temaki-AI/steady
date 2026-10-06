import Foundation
import SwiftData

/// Shared ModelContainer that uses App Group storage so both the main app
/// and widget extension can access the same SwiftData database.
enum SharedModelContainer {
    static let appGroupID = "group.com.steadyflow.habits"

    struct AppGroupUnavailable: Error {}

    /// Set once at launch when the app had to fall back to a temporary in-memory store
    nonisolated(unsafe) static var isUsingTemporaryStore = false

    /// URL for the shared SwiftData store inside the App Group container.
    /// Throws (rather than crashing) if the App Group isn't provisioned.
    static func storeURL() throws -> URL {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            throw AppGroupUnavailable()
        }
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
            url: try storeURL(),
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Creates a ModelContainer for the widget (local only, no CloudKit)
    static func makeWidgetContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            url: try storeURL(),
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
