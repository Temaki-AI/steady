import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

// MARK: - Widget Provider

struct SteadyFlowTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SteadyFlowEntry {
        SteadyFlowEntry(date: Date(), completed: 5, total: 8, habits: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SteadyFlowEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SteadyFlowEntry>) -> Void) {
        // Read from shared SwiftData store
        let entry = loadEntry()

        // Refresh hourly as fallback
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> SteadyFlowEntry {
        // In production: read from shared App Group SwiftData store
        // For now, return placeholder
        SteadyFlowEntry(date: Date(), completed: 0, total: 0, habits: [])
    }
}

// MARK: - Entry

struct SteadyFlowEntry: TimelineEntry {
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
    let entry: SteadyFlowEntry

    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.completed) / Double(entry.total)
    }
    
    private var primaryGreen: Color {
        Color(hex: "6B9B7D")
    }
    
    private var darkGreen: Color {
        Color(hex: "4A7A5E")
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(hex: "F0EDE8"), lineWidth: 8)
                
                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [primaryGreen, darkGreen]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270 * progress - 90)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)

                VStack(spacing: 2) {
                    Text("\(entry.completed)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text("of \(entry.total)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 70, height: 70)

            Text("Today")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .containerBackground(Color(hex: "FAFAF7"), for: .widget)
    }
}

// MARK: - Medium Widget (Habit List)

struct MediumWidgetView: View {
    let entry: SteadyFlowEntry
    
    private var primaryGreen: Color {
        Color(hex: "6B9B7D")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(entry.completed)/\(entry.total)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryGreen)
            }
            .padding(.bottom, 4)

            ForEach(entry.habits.prefix(4)) { habit in
                HStack(spacing: 10) {
                    // Interactive check-off button
                    Button(intent: CheckOffHabitIntent(habitId: habit.id.uuidString)) {
                        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.body)
                            .foregroundStyle(habit.isCompleted ? (Color(hex: habit.colorHex)) : Color.secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)

                    Image(systemName: habit.icon)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: habit.colorHex))
                        .frame(width: 20)

                    Text(habit.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()
                }
                .opacity(habit.isCompleted ? 0.6 : 1.0)
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(Color(hex: "FAFAF7"), for: .widget)
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

struct SteadyFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        SteadyFlowTodayWidget()
    }
}

struct SteadyFlowTodayWidget: Widget {
    let kind: String = "SteadyFlowTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SteadyFlowTimelineProvider()) { entry in
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
