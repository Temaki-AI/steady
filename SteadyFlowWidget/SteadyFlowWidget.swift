import WidgetKit
import SwiftUI
import SwiftData
import AppIntents
import UserNotifications

// MARK: - Widget Provider

struct SteadyFlowTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SteadyFlowEntry {
        SteadyFlowEntry(date: Date(), completed: 5, total: 8, habits: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SteadyFlowEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            completion(loadEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SteadyFlowEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now

        // Include a fresh entry for midnight so the widget flips to the new day on time,
        // instead of showing yesterday's check-offs until the next reload
        let entries = [loadEntry(for: now), loadEntry(for: tomorrow)]

        // Refresh hourly as a fallback (e.g. for changes synced from other devices)
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        completion(Timeline(entries: entries, policy: .after(min(nextHour, tomorrow))))
    }

    private func loadEntry(for day: Date = Date()) -> SteadyFlowEntry {
        do {
            let container = try SharedModelContainer.makeWidgetContainer()
            let context = ModelContext(container)

            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { !$0.isArchived },
                sortBy: [SortDescriptor(\.position)]
            )
            let habits = try context.fetch(descriptor)

            let widgetHabits = habits
                .filter { $0.isScheduled(for: day) }
                .map { habit in
                    WidgetHabit(
                        id: habit.id,
                        name: habit.name,
                        icon: habit.icon,
                        colorHex: habit.colorHex,
                        isCompleted: habit.isCompleted(for: day)
                    )
                }

            let completed = widgetHabits.filter(\.isCompleted).count
            return SteadyFlowEntry(
                date: day,
                completed: completed,
                total: widgetHabits.count,
                habits: widgetHabits
            )
        } catch {
            return SteadyFlowEntry(date: Date(), completed: 0, total: 0, habits: [])
        }
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

// MARK: - Entry View (switches on widget family)

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SteadyFlowEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemLarge:
            MediumWidgetView(entry: entry, maxHabits: 9)
        default:
            MediumWidgetView(entry: entry, maxHabits: 4)
        }
    }
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
    /// How many rows fit: 4 in medium, 9 in large
    let maxHabits: Int
    
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

            ForEach(entry.habits.prefix(maxHabits)) { habit in
                HStack(spacing: 10) {
                    // Interactive check-off button
                    Button(intent: CheckOffHabitIntent(habitId: habit.id.uuidString)) {
                        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.body)
                            .foregroundStyle(habit.isCompleted ? (Color(hex: habit.colorHex)) : Color.secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(habit.name)
                    .accessibilityValue(habit.isCompleted ? "Completed" : "Not completed")

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

            if entry.habits.count > maxHabits {
                Text("+\(entry.habits.count - maxHabits) more")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        guard let uuid = UUID(uuidString: habitId) else {
            return .result()
        }

        do {
            let container = try SharedModelContainer.makeWidgetContainer()
            let context = ModelContext(container)

            var descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate<Habit> { $0.id == uuid }
            )
            descriptor.fetchLimit = 1
            guard let habit = try context.fetch(descriptor).first else {
                return .result()
            }

            let dateString = Habit.dateString(from: Date())

            let existing = habit.safeCompletions.filter { $0.date == dateString }
            if !existing.isEmpty {
                existing.forEach(context.delete)
                // Today's reminder comes back the next time the app opens
                // (HabitService.refreshAllReminders)
            } else {
                let completion = Completion(habit: habit, date: Date())
                context.insert(completion)
                // Done for today: drop today's pending reminders for this habit
                let center = UNUserNotificationCenter.current()
                let todayPrefix = "\(habit.id.uuidString)-\(dateString)"
                let pending = await center.pendingNotificationRequests()
                center.removePendingNotificationRequests(
                    withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(todayPrefix) }
                )
            }

            try context.save()
        } catch {
            // Silently fail — widget will show stale data until next refresh
        }

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Widget Bundle

@main
struct SteadyFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        SteadyFlowTodayWidget()
    }
}

struct SteadyFlowTodayWidget: Widget {
    let kind: String = "SteadyFlowTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SteadyFlowTimelineProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Habits")
        .description("Track your daily habits at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
