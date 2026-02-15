import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Widget Provider

struct SteadyTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SteadyEntry {
        SteadyEntry(date: Date(), completed: 5, total: 8, habits: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SteadyEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SteadyEntry>) -> Void) {
        // Read from shared SwiftData store
        let entry = loadEntry()

        // Refresh hourly as fallback
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> SteadyEntry {
        // In production: read from shared App Group SwiftData store
        // For now, return placeholder
        SteadyEntry(date: Date(), completed: 0, total: 0, habits: [])
    }
}

// MARK: - Entry

struct SteadyEntry: TimelineEntry {
    let date: Date
    let completed: Int
    let total: Int
    let habits: [WidgetHabit]
}

struct WidgetHabit: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
    let isCompleted: Bool
}

// MARK: - Small Widget (Ring Chart)

struct SmallWidgetView: View {
    let entry: SteadyEntry

    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.completed) / Double(entry.total)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(hex: "#81C784") ?? .green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)

                VStack(spacing: 0) {
                    Text("\(entry.completed)/\(entry.total)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .frame(width: 60, height: 60)

            Text("Today")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget (Habit List)

struct MediumWidgetView: View {
    let entry: SteadyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Today")
                    .font(.headline)
                Spacer()
                Text("\(entry.completed)/\(entry.total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 2)

            ForEach(entry.habits.prefix(4)) { habit in
                HStack(spacing: 8) {
                    // Interactive check-off button
                    Button(intent: CheckOffHabitIntent(habitId: habit.id.uuidString)) {
                        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(habit.isCompleted ? (Color(hex: habit.colorHex) ?? .green) : .secondary)
                    }
                    .buttonStyle(.plain)

                    Image(systemName: habit.icon)
                        .font(.caption)
                        .foregroundStyle(Color(hex: habit.colorHex) ?? .green)

                    Text(habit.name)
                        .font(.caption)
                        .lineLimit(1)

                    Spacer()
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Interactive Check-Off Intent

struct CheckOffHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Off Habit"
    static var description: IntentDescription = "Mark a habit as complete"

    @Parameter(title: "Habit ID")
    var habitId: String

    init() {
        self.habitId = ""
    }

    init(habitId: String) {
        self.habitId = habitId
    }

    func perform() async throws -> some IntentResult {
        // In production: write to shared SwiftData store
        // Then reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Widget Bundle

struct SteadyWidgetBundle: WidgetBundle {
    var body: some Widget {
        SteadyTodayWidget()
    }
}

struct SteadyTodayWidget: Widget {
    let kind: String = "SteadyTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SteadyTimelineProvider()) { entry in
            switch entry.date { // Use widget family
            default:
                MediumWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Today's Habits")
        .description("Track your daily habits at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
